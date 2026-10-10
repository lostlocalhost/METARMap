try:
	from board import SCL, SDA
	import busio
	from PIL import Image, ImageDraw, ImageFont
	import adafruit_ssd1306
	import time
	from pytz import timezone
	import pytz
	noDisplayLibraries = False
	importError = None
except ImportError as e:
	noDisplayLibraries = True
	importError = e

import sys
import datetime

_errorCount = 0
_MAX_LOGGED_ERRORS = 5

def _log(msg):
	"""Always-on logging to stderr (refresh.sh appends it to Logs/metar_refresh.log)."""
	print(datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S') + " displaymetar: " + msg, file=sys.stderr, flush=True)

def _logError(where, e):
	"""Log display errors, capped per run so a dead screen cannot flood the SD card."""
	global _errorCount
	_errorCount += 1
	if _errorCount <= _MAX_LOGGED_ERRORS:
		_log("ERROR in " + where + ": " + type(e).__name__ + ": " + str(e))
	if _errorCount == _MAX_LOGGED_ERRORS:
		_log("further display errors this run will not be logged")


from icecream import ic
# This additional file is to support the functionality for an external display
# If you only want to have the LEDs light up, then you do not need this file
fontLarge = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf', 20)
fontMed = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', 15)
fontSmall = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', 12)
fontXSmall = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf', 11)
padding = -3
x = 0

def _text_size(font, text):
	"""Pillow <10 used getsize; 10+ uses getbbox."""
	try:
		return font.getsize(text)
	except AttributeError:
		bbox = font.getbbox(str(text))
		return (bbox[2] - bbox[0], bbox[3] - bbox[1])


ic.configureOutput(includeContext=True, contextAbsPath=False)

def startDisplay():
	if noDisplayLibraries:
		_log("display libraries failed to import, screen disabled: " + str(importError))
		return None
	try:
		i2c = busio.I2C(SCL, SDA)
		disp = adafruit_ssd1306.SSD1306_I2C(128, 64, i2c)
		# Hard reset each run: after days of uptime the SSD1306 can ACK I2C
		# but stop lighting the panel. Power-cycle the panel in software and
		# resend the full init (charge pump, contrast, addressing) explicitly.
		disp.poweroff()
		time.sleep(0.1)
		disp.init_display()
		disp.contrast(255)
		disp.invert(False)
		disp.fill(0)
		disp.show()
		disp.poweron()
	except Exception as e:
		_logError("startDisplay (I2C/SSD1306 init)", e)
		return None
	_log("screen started OK (hard reset)")
	return disp

_drawCount = 0

def drawCount():
	return _drawCount

def _countDraw():
	global _drawCount
	_drawCount += 1
	
def shutdownDisplay(disp):
	if noDisplayLibraries:
		return
	if disp is None:
		return

	try:
		disp.poweroff()
	except Exception as e:
		_logError("shutdownDisplay", e)

def clearScreen(disp):
	if noDisplayLibraries:
		return
	if disp is None:
		return
	try:
		disp.fill(0)
		disp.show()
	except Exception as e:
		_logError("clearScreen", e)
	

def outputMetar1(disp, station, condition):
	if noDisplayLibraries:
		return
	if disp is None or condition is None or station is None:
		return

	ic(station)
	
	width = disp.width
	height = disp.height
	image1 = Image.new("1", (width, height))
	draw1 = ImageDraw.Draw(image1)
	# Draw a black filled box to clear the image.
	draw1.rectangle((0, 0, width, height), outline=0, fill=0)
	
	top = padding
	bottom = height - padding
	
	#draw.line([(x + 85, top + 18), (x + 85, bottom)], fill=255, width=1)
	central = timezone('US/Central')
 
	draw1.text((x, top + 0), station[0][1:] + "-" + (condition["flightCategory"] or "UNK"), font=fontLarge, fill=255) # StationID, Condition (VFR/IFR)
	w,h = _text_size(fontXSmall, str(station[1])) 
	draw1.text((width-w, top + 1), str(station[1]), font=fontXSmall, fill=255) # Custom text ("HOME", "CNTRL" etc)
	
	draw1.text((x, top + 20), condition["windDir"] + "@" + str(condition["windSpeed"]) + (("G" + str(condition["windGustSpeed"]) if condition["windGust"] else "") + "/" +str(condition["vis"]) + "SM "), font=fontMed, fill=255)
	draw1.text((x, top + 35), str(condition["altimHg"]) + "Hg" + " " + str(condition["tempC"]) + "/" + str(condition["dewpointC"]) + "C", font=fontMed, fill=255)
	draw1.text((x, top + 50), condition["obsTime"].astimezone(central).strftime("%H:%MC") + " " + condition["obsTime"].strftime("%H:%MZ"), font=fontSmall, fill=255)
	try:
		disp.image(image1)
		disp.show()
		_countDraw()
	except Exception as e:
		_logError("outputMetar1", e)
	
def outputMetar2(disp, station, condition):
	if noDisplayLibraries:
		return
	if disp is None or condition is None or station is None:
		return
	
	width = disp.width
	height = disp.height
	image2 = Image.new("1", (width, height))
	draw2 = ImageDraw.Draw(image2)
	# Draw a black filled box to clear the image.
	draw2.rectangle((0, 0, width, height), outline=0, fill=0)
	
	top = padding
	bottom = height - padding
	
	draw2.rectangle((0, 0, width, height), outline=0, fill=0)
	draw2.text((x, top + 0), station[0][1:] + "-" + (condition["flightCategory"] or "UNK"), font=fontLarge, fill=255) # StationID, Condition (VFR/IFR)
	w,h = _text_size(fontXSmall, str(station[1]))
	draw2.text((width-w, top + 1), str(station[1]), font=fontXSmall, fill=255) # Custom text ("HOME", "CNTRL" etc)
	
	yOff = 18
	xOff = 0
	NewLine = False
	for skyIter in condition["skyConditions"]:
		draw2.text((x + xOff, top + yOff), skyIter["cover"] + ("@" + str(skyIter["cloudBaseFt"]) if skyIter["cloudBaseFt"] > 0 else ""), font=fontSmall, fill=255)
		if NewLine:
			yOff += 12
			xOff = 0
			NewLine = False
		else:
			xOff = 65
			NewLine = True
	draw2.text((x, yOff + 12), condition["obs"], font=fontMed, fill=255)
	try:
		disp.image(image2)
		disp.show()
		_countDraw()
	except Exception as e:
		_logError("outputMetar2", e)
 
def none(disp):
	if noDisplayLibraries:
		return
	if disp is None:
		return
	
	width = disp.width
	height = disp.height
	image1 = Image.new("1", (width, height))
	draw1 = ImageDraw.Draw(image1)
	# Draw a black filled box to clear the image.
	draw1.rectangle((0, 0, width, height), outline=0, fill=0)
	top = padding
	bottom = height - padding
	draw1.text((x, top + 0), "NO DATA FND", font=fontLarge, fill=255) # StationID, Condition (VFR/IFR)
	draw1.text((x, top + 20), "Check:", font=fontMed, fill=255)
	draw1.text((x, top + 35), "internet", font=fontMed, fill=255)
	draw1.text((x, top + 50), "airports lst", font=fontMed, fill=255)
	try:
		disp.image(image1)
		disp.show()
		_countDraw()
	except Exception as e:
		_logError("none", e)
