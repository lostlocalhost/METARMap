### LLH1.61 (2023-10-21-23) 
- Little change... Aviationweather update thier api endpoint, so thats fixed. ALong with a little structure cleanup.

### LLH1.6 (2023-10-6) "This is stil a thing?"
OK, so it's been a long while. All sorts of stuff were wrong on this, and I was running it on a Pi W Zero with a mini 2G card. For a while now I've had to reboot it every hour due to a memory issue.
- Drive space was willing up with logs and junk. Rebuilding on another sdcard from scratch I noticed a few issues. I'm now runnig it on 64bit and Pi4B. Yea power.
- On new install, pytz library needed it's own installation for the diusplay to work. There isnt clear messaging thats what the problem is, and it's not in the very outdated instructions below.
- Font library ttf-dejavu changed name to fonts-dejavu
- liblcms1-dev is not found, however liblcms2-dev installs. Unsure exact impact.

### LLH1.5 (2020-01-01) Happy new year!
- Finished build for first METARMap. (yea)
- Updated all config to initial personal needs for board.
- Added images of build.

### LLH1.4.3 (2020-12-30)
- Updated input file to json.
- Also finished the update for the 2 cycles of screen info. Includes custom text to display right justified on header line. This should be limited to 4 chars in the 'text' parm in the airports input file.

### LLH1.4.2 (2020-12-28)
- Added two cycles to each iaco. It will use half the DISPLAY_ROTATION_SPEED to cycle to the second screen.
- Updated some of the values, including local time along with Zulu
- Split out the light list and the display list to be able to control what places get displayed.

### 1.4.1 (2020-12-16)
- Small bugfix for CLR skycondition (which doesn't have a cloudbase)

### 1.4.0 (2020-12-15)
- Adding functionality to display METAR information for the airports in use on a small external display
- - Code is written for a 128 x 64 pixel external OLED display using the SSD1306 chipset

### 1.3.1 (2020-12-13)
- Astral for dimming using sunrise/sunset has a breaking change starting with python 3.6
- - Made a fix to support both older raspberry pi running python 3.5 with Astral 1.10.1 as well as newer Raspberry images running Astral 2.2

### 1.3.0 (2020-12-12)
- Adding functionality to dim the lights between certain times of day
  - Either as a fixed time of day
  - or using local sunrise/sunset times

### 1.2.3 (2020-11-19)
- Aviationweather.gov has stopped accepting the default user agent for urllib
- - Explicitly Setting it to standard web browser compatible user agent

### 1.2.2 (2020-06-11)
- Small fix to ensure correct variable scoping

### 1.2.1 (2020-05-21)
- Change to not skip station if wind is not currently reported, but the Flight condition is

### 1.2.0 (2020-05-18)
- Adding functionality to show lightning conditions in vicinity of the airport

### 1.1.2 (2020-05-12)
- Small fix to the loop condition

### 1.1.1 (2020-05-09)
- Small fix for IFR color duplicate value

### 1.1.0 (2020-05-08)
- Adding blinking functionality for windy conditions

### 1.0.1 (2020-04-19)
- Fixed LED_BRIGHTNESS not working

### 1.0 (2019-01-05)
- Initial version of the script
