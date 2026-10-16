### LLH1.7.1 (2026-10-16)
- Docs and housekeeping (PR #4):
- - README rewritten to match the current scripts: setup.sh, refresh.sh lock/timeouts, log rotation, `-l`/`-t` flags, `BLINK_SPEED`, stale-cache behavior, and corrected package names.
- - crontab paths now point to /home/pi/METARMap and the file uses LF line endings.
- - Fixed .gitignore so logs and cache files are actually ignored (also ignores `__pycache__/`).
- - setup.sh: `apt-get upgrade -y` and `cd` calls now exit on failure.
- - lightsoff.sh: added missing `#!/bin/bash` shebang.
- - Removed `metarpid.pid` and a `.pyc` file from git tracking.
- - Fixed spelling in README.md and CHANGELIST.md.

### LLH1.7 (2026-10-16) Hang/robustness fixes (PR #3)
- Pi Zero hangs were more likely overlapping cron runs / NeoPixel re-inits and a hung urlopen than an LED leak in the Python code.
- Blink is capped at 280s (`BLINK_TOTALTIME_SECONDS`) so it finishes inside the 5-minute cron interval.
- METAR fetch now has a timeout and one retry (10s apart); unparseable or empty responses count as failures.
- refresh.sh uses flock so runs can't overlap (fd 9 is closed before launching metar.py so the lock isn't held for the whole blink window), matches the process by cmdline for pkill, sends one SIGTERM, waits up to 20s, then SIGKILLs.
- LEDs and display are cleaned up on exit/SIGTERM. The SIGTERM handler now just raises SystemExit, fixing a hang/RecursionError when the signal landed during an I2C draw.
- Stale-cache fallback: each good response is cached to last_metar.xml (atomic write). If an update fails and the cache is under `MAX_STALE_MINUTES` (120), the last good map stays on the LEDs and a "NO UPDATE" screen is added to the OLED rotation. With no usable cache, the LEDs clear and the failure screen shows.
- OLED: display errors and per-run status (METAR count, stations, screen ON/OFF, draws) are always logged. The panel is hard-reset (full init) each run.
- Flight category is now estimated from ceiling and any visibility (FAA thresholds) when a station omits visibility and the API leaves it blank (seen on KRPH). Estimates show with `*` on the OLED and missing visibility shows `--SM`. Toggle with `ESTIMATE_MISSING_CATEGORY`.
- Logs are soft-capped in the scripts, and packaging/metarmap-logrotate adds a logrotate config.
- setup.sh reworked (installs the logrotate config, updated flow); start.sh and pixelsoff.py updated.

### LLH1.64 (2026-9-10)
- Updated the METAR API endpoint to the new aviationweather.gov DataAPI (`/api/data/metar`) and updated the parameter documentation link. The `hoursBeforeNow` and `mostRecentForEachStation` parameters were dropped from the request.

### LLH1.63 (2025-9-29)
- Updated the aviationweather.gov url endpoint again.

### LLH1.62 (2024-5-5) 
- Had an issue with icecream logging dependency, so update six library in setup
- Found that issue because None type was getting pulled for flightCategory for some reason. As a fix, I included changes to account for an unknown category.

### LLH1.61 (2023-10-21-23) 
- Little change... Aviationweather updated their api endpoint, so that's fixed. Along with a little structure cleanup.

### LLH1.6 (2023-10-6) "This is still a thing?"
OK, so it's been a long while. All sorts of stuff were wrong on this, and I was running it on a Pi W Zero with a mini 2G card. For a while now I've had to reboot it every hour due to a memory issue.
- Drive space was filling up with logs and junk. Rebuilding on another sdcard from scratch I noticed a few issues. I'm now running it on 64bit and Pi4B. Yeah, power.
- On new install, pytz library needed its own installation for the display to work. There isn't clear messaging that's what the problem is, and it's not in the very outdated instructions below.
- Font library ttf-dejavu changed name to fonts-dejavu
- liblcms1-dev is not found, however liblcms2-dev installs. Unsure exact impact.

### LLH1.5 (2020-01-01) Happy new year!
- Finished build for first METARMap. (yeah)
- Updated all config to initial personal needs for board.
- Added images of build.

### LLH1.4.3 (2020-12-30)
- Updated input file to json.
- Also finished the update for the 2 cycles of screen info. Includes custom text to display right justified on header line. This should be limited to 4 chars in the 'text' param in the airports input file.

### LLH1.4.2 (2020-12-28)
- Added two cycles to each ICAO. It will use half the DISPLAY_ROTATION_SPEED to cycle to the second screen.
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
- - Explicitly setting it to standard web browser compatible user agent

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
