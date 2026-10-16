#!/usr/bin/python3

import board
import neopixel
try:
    import displaymetar
except ImportError:
    displaymetar = None

# Keep in sync with LED_COUNT in metar.py
LED_COUNT = 50

pixels = neopixel.NeoPixel(board.D18, LED_COUNT)

pixels.deinit()

if displaymetar is not None:
    disp = displaymetar.startDisplay()
    displaymetar.shutdownDisplay(disp)

print("LEDs off")
