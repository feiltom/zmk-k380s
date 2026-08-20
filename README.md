# Zephyr™ Mechanical Keyboard (ZMK) Firmware

[![Discord](https://img.shields.io/discord/719497620560543766)](https://zmk.dev/community/discord/invite)
[![Build](https://github.com/zmkfirmware/zmk/workflows/Build/badge.svg)](https://github.com/zmkfirmware/zmk/actions)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

[ZMK Firmware](https://zmk.dev/) is an open source ([MIT](LICENSE)) keyboard firmware built on the [Zephyr™ Project](https://www.zephyrproject.org/) Real Time Operating System (RTOS). ZMK's goal is to provide a modern, wireless, and powerful firmware free of licensing issues.

Check out the website to learn more: https://zmk.dev/.

You can also come join our [ZMK Discord Server](https://zmk.dev/community/discord/invite).

To review features, check out the [feature overview](https://zmk.dev/docs/). ZMK is under active development, and new features are listed with the [enhancement label](https://github.com/zmkfirmware/zmk/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement) in GitHub. Please feel free to add 👍 to the issue description of any requests to upvote the feature.

## Board: k380s

Custom board for the K380s (nRF52832 QFAB, BLE-only) mainboard used in a
Logitech K380s shell. `app/boards/nordic/k380s/`. Pin functions below were
reverse-engineered via brute-force GPIO scanning and hardware testing (no
schematic available), so treat unlisted pins/behaviors as unknown rather
than confirmed-absent.

### GPIO map (P0.0 - P0.31, all 32 pins in use)

| Pin(s)              | Function                          | Notes |
|---------------------|------------------------------------|-------|
| P0.0-P0.8, P0.28-29  | Key matrix rows                    | `GPIO_ACTIVE_HIGH \| GPIO_OPEN_SOURCE` |
| P0.9-P0.22          | Key matrix columns                 | `GPIO_ACTIVE_HIGH \| GPIO_PULL_DOWN`. P0.9/P0.10 are the SoC's NFC antenna pins by default - freed for GPIO use via `&uicr { nfct-pins-as-gpios; }` |
| P0.23               | Green LED                          | Plain `gpio-leds`, active high |
| P0.24               | Red LED                            | Lowest forward voltage of the 5 LEDs - confirmed working on the 2-cell NiMH pack |
| P0.25               | White LED 1                        | Used as the ZMK status LED (advertising/connected/battery blink) |
| P0.26               | White LED 2                        | Unused by firmware, same behavior as White LED 1 |
| P0.27               | White LED 3                        | Unused by firmware, same behavior as White LED 1 |
| P0.30 (AIN6)        | Battery voltage sense              | 2-cell NiMH pack wired directly to the ADC, no physical divider. See the calibration comment on `vbatt` in the board dts - the driver's fixed Li-ion SoC curve is approximated with a scaled `full-ohms` |
| P0.31               | LED bank power enable              | Must be driven **high** or none of the 5 LEDs above light up, regardless of their own GPIO state. Modeled as a `zmk,ext-power-generic` device (`EXT_POWER` node) rather than a static `gpio-hog` so it gets cleanly disabled by ZMK's device-suspend path before `sys_poweroff()` (deep sleep) and re-enabled again on the next boot |

### Known quirks

- **Deep sleep and LED power**: `CONFIG_ZMK_SLEEP` selects
  `ZMK_PM_DEVICE_SUSPEND_RESUME`, so `zmk_pm_suspend_devices()` runs
  `PM_DEVICE_ACTION_SUSPEND` on every eligible device before `sys_poweroff()`.
  The `ext_power_generic` driver backing P0.31 handles that action by
  driving the pin low, so the whole LED bank is powered down during deep
  sleep and comes back automatically on wake (fresh boot re-enables it in
  `ext_power_generic_init`).
- **Battery percentage accuracy**: the voltage-divider driver only supports
  a fixed lithium-ion state-of-charge curve in this ZMK version. The
  `full-ohms` value on `vbatt` is a linear-fit approximation for a 2-cell
  NiMH pack, not a real physical divider ratio - expect the reported
  percentage to be approximate, especially near the extremes.

### Flashing: SWD wiring

The board has no exposed debug connector - wire a J-Link (or other SWD probe)
directly to the four pads shown below (front side of the board):

![K380s board pads](app/boards/nordic/k380s/front.jpg)

| Pad    | Probe pin | Location on board |
|--------|-----------|--------------------|
| VCC    | VTref/VCC | Bottom-left, next to GND |
| GND    | GND       | Bottom-left, next to VCC |
| SWDIO  | SWDIO     | Small pad next to the MCU, left of SWDCLK |
| SWDCLK | SWDCLK    | Small pad next to the MCU, right of SWDIO |

The battery pack powers the board during flashing - VCC only needs to be
tied to the probe's VTref sense line, not driven; the nRF52832 has no USB.
