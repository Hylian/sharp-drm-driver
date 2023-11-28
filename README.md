# Sharp Memory LCD Kernel Driver for Beepy + Radxa Zero

DRM kernel driver for 2.7" 400x240 Sharp memory LCD panel.

This driver targets the [Radxa Zero](https://wiki.radxa.com/Zero) 
running [Armbian](https://www.armbian.com/radxa-zero/) on 
[Beepy](https://beepy.sqfmi.com/).

Forked from the Raspberry Pi driver for Beepy 
[here](https://github.com/ardangelo/sharp-drm-driver).

This driver has been validated on Armbian 23.11 Bookworm for Radxa Zero.

## Installation

### Dependencies
```
apt install linux-headers-current-meson64
```

### Build
```
make
```

### Install
```
make install
```

### Uninstall

*Warning*: If you've made additional modifications to `user_overlays` or 
`extraargs` in `/boot/armbianEnv.txt`, this may result in unexpected behavior.

```
make uninstall
```

