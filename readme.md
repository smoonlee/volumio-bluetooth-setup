# bluetooth ➲ volumio ➲ rpi-dac

Simple script to setup bluetooth sound casting to volumio.

Tested on rpi2 / volumio 2.389 (rasbian jessie) / duriosound dac / bluetooth dongle.

## Usage

1. Install and start [volumio](https://volumio.org/get-started/)
2. Setup your dac (sound card) in volumio interface
3. Run the setup script **from** the rpi :

```bash
ssh volumio@volumio.local
git clone https://github.com/vrince/volumio-bluetooth-setup.git
cd volumio-bluetooth-setup
sudo ./setup.sh
```

## Known issues

* bluetooth auto trust need love
* handle audio sink properly (hardcoded to device `alsa_output.platform-soc_sound.analog-stereo.monitor` in `bluez-dev`)

## References

Original forked from : [Super-Simple-Raspberry-Pi-Audio-Receiver-Install](https://github.com/BaReinhard/Super-Simple-Raspberry-Pi-Audio-Receiver-Install)

Mainly fix and adapted from: [A2DP audio streaming using Raspberry PI](https://gist.github.com/oleq/24e09112b07464acbda1)
