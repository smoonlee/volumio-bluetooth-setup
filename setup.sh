#!/bin/bash

# most of the magic here comes from:
# - https://gist.github.com/oleq/24e09112b07464acbda1
# - https://github.com/BaReinhard/Super-Simple-Raspberry-Pi-Audio-Receiver-Install

install_dependencies() {
  #TODO clean up that mess probably not half of it is necessary
  sudo apt install pulseaudio-module-bluetooth python-dbus libltdl-dev pulseaudio libtool intltool \
  libsndfile-dev libcap-dev libjson0-dev libasound2-dev libavahi-client-dev libbluetooth-dev libglib2.0-dev \
  libsamplerate0-dev libsbc-dev libspeexdsp-dev libssl-dev libtdb-dev libbluetooth-dev intltool autoconf \
  autogen automake build-essential libasound2-dev libflac-dev libogg-dev libtool libvorbis-dev pkg-config python \
  --no-install-recommends

  sudo apt install bluez bluez-firmware libusb-dev libdbus-1-dev libglib2.0-dev libudev-dev libical-dev \
  libreadline-dev libltdl-dev libsamplerate0-dev libsndfile1-dev libasound2-dev libavahi-client-dev \
  libspeexdsp-dev liborc-0.4-dev intltool libtdb-dev libssl-dev libjson0-dev libsbc-dev libcap-dev \
  --no-install-recommends
}

set_bluetooth_name() {
  if [ -z "${BLUETOOTH_NAME}" ] ; then
    read -p "Bluetooth device name: " BLUETOOTH_NAME
  else
    echo "Bluetooth device name: ${BLUETOOTH_NAME}"
  fi
  echo "PRETTY_HOSTNAME=$BLUETOOTH_NAME" > /etc/machine-info
}

setup_volume_watcher() {
  cp usr/local/bin/volume-watcher.py /usr/local/bin/volume-watcher.py
  chmod +x /usr/local/bin/volume-watcher.py
  cp lib/systemd/system/volume-watcher.service /lib/systemd/system/volume-watcher.service
  systemctl enable volume-watcher
}

setup_pulse_audio() {
  cp init.d/pulseaudio /etc/init.d/pulseaudio
  chmod +x /etc/init.d/pulseaudio
  update-rc.d pulseaudio defaults > /dev/null
}

add_udev_rule() {
  #add udev rule to trigger script on device connection
  LINE="KERNEL==\"input[0-9]*\", RUN+=\"/usr/local/bin/bluez-udev\""
  echo "${LINE}" > /etc/udev/rules.d/99-input.rules
}

setup_bluetooth() {
  #create bluetooth audio.conf class 0x20041C == audio loud speaker
  printf "%s\n" \
  "Class = 0x20041C" \
  "Enable = Source,Sink,Media,Socket" \
  "load-module module-bluetooth-discover" \
  ".endif" > /etc/bluetooth/audio.conf

  #change bt name and class in /etc/bluetooth/main.conf
  #TODO handle went name / class is alreday setted (no #) 
  sed -i "s/^#Name = .*/Name = ${BLUETOOTH_NAME}/" /etc/bluetooth/main.conf
  sed -i "s/^#Class = .*/Class = 0x200414/" /etc/bluetooth/main.conf

  #bluez
  cp usr/local/bin/bluez-udev /usr/local/bin
  chmod 755 /usr/local/bin/bluez-udev
  #TODO check if this is needed ...
  cp usr/local/bin/bluezutils.py /usr/local/bin

  #autotrust
  #FIXME auto trust do not work ...
  #new manual pair --> trust 
  cp usr/local/bin/simple-agent.autotrust /usr/local/bin
  chmod 755 /usr/local/bin/simple-agent.autotrust

  #bluetooth daemon
  cp init.d/bluetooth /etc/init.d/bluetooth
  chmod +x /etc/init.d/bluetooth
  update-rc.d bluetooth defaults > /dev/null

  #bluetooth agent
  cp init.d/bluetooth-agent-vol /etc/init.d/bluetooth-agent
  chmod +x /etc/init.d/bluetooth-agent
  update-rc.d bluetooth-agent defaults > /dev/null
}

setup_pulse() {
  cp etc/pulse/daemon.conf /etc/pulse/daemon.conf
  #setup /etc/pulse/system.pa
  #add tsched=0 and module-bluetooth-discover
  sed -i "s/^load-module module-udev-detect.*/load-module module-udev-detect tsched=0/" /etc/pulse/system.pa
  if ! grep -Fxq "load-module module-bluetooth-discover" /etc/pulse/system.pa ; then
    printf "%s\n" \
    "### Automatically load driver modules for Bluetooth hardware" \
    ".ifexists module-bluetooth-discover.so" \
    "load-module module-bluetooth-discover" \
    ".endif" >> /etc/pulse/system.pa
  fi
}

restart_services() {
  service bluetooth start
  service pulseaudio start
  service bluetooth-agent start
}

# TODO cmdline args
# setup sequence
install_dependencies
set_bluetooth_name
setup_volume_watcher
setup_pulse_audio
add_udev_rule
setup_bluetooth
setup_pulse
restart_services
