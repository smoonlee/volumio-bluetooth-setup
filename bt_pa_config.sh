#!/bin/bash

get_bluetooth_name() {
  if [ -z "${BLUETOOTH_NAME}" ] ; then
    read -p "Bluetooth device name: " BLUETOOTH_NAME
  else
    echo "Bluetooth device name: ${BLUETOOTH_NAME}"
  fi
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
  update-rc.d pulseaudio defaults
}

add_udev_rule() {
  #add udev rule to trigger script on device connection
  LINE="KERNEL==\"input[0-9]*\", RUN+=\"/usr/local/bin/bluez-udev\""
  if ! grep -Fxq "${LINE}" /etc/udev/rules.d/99-com.rules ; then
    echo "${LINE}" >> /etc/udev/rules.d/99-com.rules
  fi
}

setup_bluetooth() {
  echo "PRETTY_HOSTNAME=$BLUETOOTH_NAME" >> /etc/machine-info

  #change bt name and class in /etc/bluetooth/main.conf
  sed -i "s/^#Name.*/Name = ${BLUETOOTH_NAME}/" /etc/bluetooth/main.conf
  sed -i "s/^#Class.*/Class = 0x200414/" /etc/bluetooth/main.conf

  #bluez
  cp usr/local/bin/bluez-udev /usr/local/bin
  chmod 755 /usr/local/bin/bluez-udev
  cp usr/local/bin/bluezutils.py /usr/local/bin

  #autotrust
  cp usr/local/bin/simple-agent.autotrust /usr/local/bin
  chmod 755 /usr/local/bin/simple-agent.autotrust

  #bluetooth daemon
  cp init.d/bluetooth /etc/init.d/bluetooth
  chmod +x /etc/init.d/bluetooth
  update-rc.d bluetooth defaults

  #bluetooth agent
  cp init.d/bluetooth-agent-vol /etc/init.d/bluetooth-agent
  chmod +x /etc/init.d/bluetooth-agent
  update-rc.d bluetooth-agent defaults
}

setup_pulse() {
  cp etc/pulse/daemon.conf /etc/pulse/daemon.conf
  #setup /etc/pulse/system.pa
  #add tsched=0 and module-bluetooth-discover
  sed -i "s/^load-module module-udev-detect.*/load-module module-udev-detect tsched=0/" /etc/pulse/system.pa
  if ! grep -Fxq "load-module module-bluetooth-discover" /etc/pulse/system.pa ; then
    DISCOVER="### Automatically load driver modules for Bluetooth hardware
.ifexists module-bluetooth-discover.so
load-module module-bluetooth-discover
.endif"
  echo ${DISCOVER} >> /etc/pulse/system.pa
  fi
}

restart_services() {
  service bluetooth start &
  service pulseaudio start &
  service bluetooth-agent start &
}

# setup sequence 
get_bluetooth_name
setup_volume_watcher
setup_pulse_audio
add_udev_rule
setup_bluetooth
setup_pulse

# BT FIX
build-from-source() {
  remove_dir /etc/pulsebackup
  mkdir /etc/pulsebackup
  cp /etc/pulse/* /etc/pulsebackup/

  cd ~
  remove_dir pulseaudio
  git clone --branch v6.0 https://github.com/pulseaudio/pulseaudio

  cd ~
  remove_dir json-c
  git clone https://github.com/json-c/json-c.git
  cd json-c
  sh autogen.sh
  ./configure 
  make
  make install
  cd ~
  remove_dir libsndfile
  git clone git://github.com/erikd/libsndfile.git
  cd libsndfile
  ./autogen.sh
  ./configure --enable-werror
  make
  make install
  cd ~
  cd pulseaudio
  ./bootstrap.sh
  make
  make install
  ldconfig
  cp /etc/pulsebackup/* /etc/pulse
}