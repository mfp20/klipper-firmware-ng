# klipper-firmware-ng
Stripped down version of [original Klipper firmware](https://github.com/KevinOConnor/klipper), to prepare merge in [klipper-ng](https://github.com/mfp20/klipper-ng)

# Removed:
- all boards except linux and avr (to be re-added after performance tests)
- DECL introspection system (to be re-added, partially, after performance tests)
- drivers: steppers, neopixel, ... (to be re-added after performance tests)
- autoconf (to be re-added after all other parts will be re-added)

# Modified:
- HDLC removed in favor of COBS
- refactoring of code in order to have proper headers and code files (ie: make it easy to reuse the code)

# Added:
- conventional RPC based on single byte commands (see protocol.h)
- temporary Makefile (to be removed after integration to klipper-ng)
