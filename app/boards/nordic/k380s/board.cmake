# SPDX-License-Identifier: MIT

board_runner_args(pyocd "--target=nrf52832")
board_runner_args(jlink "--device=nrf52832_xxAB" "--speed=4000")

include(${ZEPHYR_BASE}/boards/common/pyocd.board.cmake)
include(${ZEPHYR_BASE}/boards/common/jlink.board.cmake)
