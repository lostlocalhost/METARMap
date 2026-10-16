## Updates
Forked from prueker/METARMap  
  
Items updated from orig:  
* The screen was cluttered, so I added a cycle within a given airport to split the info over two screens.
*  Currently it will use half of the DISPLAY_ROTATION_SPEED to cycle. 
* Tweaked with the display items, including adding local update time, and right justified custom text to header.
* Separated out the light list and the display update list. I might have n LEDs I want updated, but only want to see the METAR for a few.
* Changed airports file to json, as I expect to be adding in more input params there in the future.
*  If adding in Nulls for spacing, a code of NULLn where n is unique must be used
* In cases where weather updates are not found, or no airports are selected to be displayed, a message will show in the display to check these items

# METARMap
Raspberry Pi project to visualize flight conditions on a map using WS2811 LEDs addressed via NeoPixel

## Detailed instructions
I've created detailed instructions about the setup and parts used here: https://slingtsi.rueker.com/making-a-led-powered-metar-map-for-your-wall/

## Software Setup
* Install [Raspbian Buster Lite](https://www.raspberrypi.org/downloads/raspbian/) on SD card
* [Enable Wi-Fi and SSH](https://medium.com/@danidudas/install-raspbian-jessie-lite-and-setup-wi-fi-without-access-to-command-line-or-using-the-network-97f065af722e)
* Install SD card and power up Raspberry Pi
* SSH (using [Putty](https://www.putty.org) or some other SSH tool) into the Raspberry and configure password and timezones
	* `passwd`
	* `sudo raspi-config`
* Update packages 
	* `sudo apt-get update`
	* `sudo apt-get upgrade`
* Get the project onto the Pi at **/home/pi/METARMap** (for example `git clone https://github.com/lostlocalhost/METARMap /home/pi/METARMap`). The scripts use that path as a hard-coded location. Note that **`metar.py`** also writes its METAR cache file `last_metar.xml` there (`METAR_CACHE_FILE`).
* Run the setup script, which does the install and permission steps for you (see [Setup script](#setup-script) below):
	* `bash /home/pi/METARMap/setup.sh`
	* If you'd rather install by hand, the libraries are listed in [setup.sh](setup.sh).
* Attach WS2811 LEDs to Raspberry Pi, if you are using just a few, you can connect them directly, otherwise you may need to also attach external power to the LEDs. For my purpose with 22 powered LEDs it was fine to just connect it directly. You can find [more details about wiring here](https://learn.adafruit.com/neopixels-on-raspberry-pi/raspberry-pi-wiring).
* Test the script by running it directly (it needs to run with root permissions to access the GPIO pins):
	* `sudo python3 metar.py`
	* Optional flags: `-l` turns on icecream debug logging, `-t` reads **[airports_tst](airports_tst)** (a two-airport test file) instead of **[airports](airports)**. The airports paths are hard-coded to `/home/pi/METARMap/`.
* Make appropriate changes to the **[airports](airports)** file for the airports you want to use and change the **[metar.py](metar.py)** and **[pixelsoff.py](pixelsoff.py)** script to the correct **`LED_COUNT`** (including NULLs if you have LEDs in between airports that will stay off) and **`LED_BRIGHTNESS`** if you want to change it
* **[setup.sh](setup.sh)** already makes the scripts executable (`chmod +x`) and the python files and airports files readable. If you are not using it, run `chmod +x` on **[refresh.sh](refresh.sh)**, **[lightsoff.sh](lightsoff.sh)** and **[start.sh](start.sh)**, and `chmod +r` on the python files and **[airports](airports)**.
* To have the script start up automatically and refresh in regular intervals, use crontab and set the appropriate interval. For an example you can refer to the [crontab](crontab) file in the GitHub repo (make sure you grant the file execute permissions beforehand to the refresh.sh and lightsoff.sh file). To edit your crontab type: **`crontab -e`**, after you are done with the edits, exit out by pressing **ctrl+x** and confirm the write operation (the sample uses `/home/pi/METARMap/refresh.sh` and `/home/pi/METARMap/lightsoff.sh`)
	* The sample crontab will run the script every 5 minutes (the */5) between the hours of 7 to 21, which includes the 21 hour, so it means it will run until 21:55
	* Then at 22:05 it will run the lightsoff.sh script, which will turn all the lights off

### Setup script
[setup.sh](setup.sh) takes no flags. It does `cd /home/pi/METARMap`, so the checkout must be there. It uses `sudo` and does the following:
* Creates `Logs/` and the `metar_refresh.log` and `metar_start.log` files (mode 777)
* Makes `refresh.sh`, `lightsoff.sh` and `start.sh` executable and sets read permission on the python files and airports files
* Runs `apt-get update` and `apt-get upgrade -y`, then installs the apt packages (python3, pip, i2c-tools, fonts, image libraries)
* Installs the pip packages with version limits (rpi_ws281x and adafruit-circuitpython-neopixel/ssd1306 with minimums, pillow 9 to 11, icecream, pytz, astral 2.2 to 3.x)
* Copies [packaging/metarmap-logrotate](packaging/metarmap-logrotate) to `/etc/logrotate.d/metarmap` if the file exists (a failed copy is ignored)

### How refresh.sh works
[refresh.sh](refresh.sh) is what cron runs. It accepts `-l` (run `metar.py -l`, debug logging) and `-t` (run `metar.py -t`, which reads the `airports_tst` file instead of `airports`), and logs to `Logs/metar_refresh.log`.
* **Lock:** it takes a non-blocking `flock` on `metar.refresh.lock` while it stops the previous run and starts the new one. If another `refresh.sh` holds the lock, it logs "lock held" and exits. The lock is released before `metar.py` is started, so the long-running `metar.py` does not hold it.
* **Restart:** it sends one SIGTERM to the previous `metar.py` python process, waits up to 20 seconds for it to exit, and sends SIGKILL if it is still running. The PID of the new run (the `sudo` wrapper process) is written to `metarpid.pid`, which `lightsoff.sh` uses.
* **Timeouts:** `metar.py` fetches METAR data with a 30 second timeout and retries once after 10 seconds. `BLINK_TOTALTIME_SECONDS` defaults to 280. When wind animation, lightning animation or the display is enabled, `metar.py` loops for about that long (plus fetch time) and then exits. Keep it under the */5 cron interval. If a run is still going, `refresh.sh` stops it anyway.
* **Stale data:** each good response is cached in `last_metar.xml`. If an update fails, the cache is used for up to `MAX_STALE_MINUTES` (120) and a "NO UPDATE" screen is added to the display. The cache age is the file's modification time. After that, or with no cache, the LEDs are cleared, the display shows "NO UPDATE" and `metar.py` exits with status 1.

### start.sh and lightsoff.sh
* [start.sh](start.sh) logs a line to `Logs/metar_start.log` and runs `refresh.sh` once. The sample crontab does not call it, so use it for a manual start or your own `@reboot` entry.
* [lightsoff.sh](lightsoff.sh) stops `pixelsoff.py` and `metar.py` (using `offpid.pid` and `metarpid.pid`), then runs [pixelsoff.py](pixelsoff.py), which turns the LEDs off and powers down the display. Keep `LED_COUNT` in `pixelsoff.py` in sync with `metar.py`.

### Log rotation
`refresh.sh` and `start.sh` trim their logs to the last ~2 MiB and ~1 MiB when they grow past that. In addition, [packaging/metarmap-logrotate](packaging/metarmap-logrotate) rotates `/home/pi/METARMap/Logs/*.log` at 2 MB, keeps 4 old copies (`copytruncate`, compressed except the newest because of `delaycompress`). `setup.sh` installs it; to install it by hand: `sudo cp packaging/metarmap-logrotate /etc/logrotate.d/metarmap`.

## Additional Wind condition blinking/fading functionality
I recently expanded the script to also take wind condition into account and if the wind exceeds a certain threshold, or if it is gusting, make the LED for that airport either blink on/off or to fade between  two shades of the current flight category color.

If you want to use this extra functionality, then inside the **[metar.py](metar.py)** file set the **`ACTIVATE_WINDCONDITION_ANIMATION`** parameter to **True**.
* There are a few additional parameters in the script you can configure to your liking:
	* `FADE_INSTEAD_OF_BLINK` - set this to either **True** or **False** to switch between fading or blinking for the LEDs when conditions are windy
	* `WIND_BLINK_THRESHOLD` - in Knots for normal wind speeds currently at the airport
	* `ALWAYS_BLINK_FOR_GUSTS` - If you always want the blinking/fading to happen for gusts, regardless of the wind speed
	* `BLINK_SPEED` - How fast the blinking happens, I found 1 second to be a happy medium so it's not too busy, but you can also make it faster, for example every half a second by using 0.5
	* `BLINK_TOTALTIME_SECONDS` - How long do you want the script to run. The default is 280 seconds. It only applies when an animation or the display is enabled, and it must stay under the cron interval (5 minutes) so runs do not overlap
	
## Additional Lightning in the vicinity blinking functionality
After the recent addition for wind condition animation, I got another request from someone if I could add a white blinking animation to represent lightning in the area.
Please note that due to the nature of the METAR system, this means that the METAR for this airport reports that there is Lightning somewhere in the vicinity of the airport, but not necessarily right at the airport.

If you want to use this extra functionality, then inside the **[metar.py](metar.py)** file set the **`ACTIVATE_LIGHTNING_ANIMATION`** parameter to **True**.
* This shares two configuration parameters together with the wind animation that you can modify as you like:
	* `BLINK_SPEED` - How fast the blinking happens, I found 1 second to be a happy medium so it's not too busy, but you can also make it faster, for example every half a second by using 0.5
	* `BLINK_TOTALTIME_SECONDS` - How long do you want the script to run. The default is 280 seconds. It only applies when an animation or the display is enabled, and it must stay under the cron interval (5 minutes) so runs do not overlap
	
## Additional LED dimming functionality based on time of day
This optional functionality allows you to run the LEDs at a dimmed lower level between a certain time of the day.

If you want to use this extra functionality, then inside the **[metar.py](metar.py)** file set the **`ACTIVATE_DAYTIME_DIMMING`** parameter to **True**.
Set the `LED_BRIGHTNESS_DIM` setting to the level you want to run when dimmed.

For the timings of the dimming there are two options:
* Fixed time of day dimming:
	* `BRIGHT_TIME_START` - Set this to the beginning of the day when you want to run at the normal `LED_BRIGHTNESS` level
	* `DIM_TIME_START` - Set this to the time where you want to run at a different `LED_BRIGHTNESS_DIM` level
* Dimming based on local sunrise/sunset:
	* For this to work, you need to install an additional library, run:
		* `sudo pip3 install astral`
	* `USE_SUNRISE_SUNSET` - Set this to **True** to use the dimming based on sunrise and sunset
	* `LOCATION` - set this to the city you want to use for sunset/sunrise timings
		* Use the closest city from the list of supported cities from https://astral.readthedocs.io/en/latest/#cities

## Additional mini display to show METAR information functionality
This optional functionality allows you to connect a small mini LED display to show the METAR information of the airports.

For this functionality to work, you will need to buy a compatible LED display and enable and install a few additional things.

I've written up some details on the display I used and the wiring here: https://slingtsi.rueker.com/adding-a-mini-display-to-show-metar-information-to-the-metar-map/

To support the display you need to enable a few new libraries and settings on the Raspberry Pi.
* [Enable I2C](https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c)
	* `sudo raspi-config`
	* Interface Options
	* I2C
	* reboot the Raspberry Pi `sudo reboot`
	* Verify your wiring is working and I2C is enabled
		* `sudo apt-get install i2c-tools`
		* `sudo i2cdetect -y 1` - this should show something connected at **3C**
* install python library for the display
	* `sudo pip3 install adafruit-circuitpython-ssd1306`
	* `sudo pip3 install pillow`
* install additional libraries needed to fill the display
	* `sudo apt-get install fonts-dejavu`
	* `sudo apt-get install libjpeg-dev -y`
	* `sudo apt-get install zlib1g-dev -y`
	* `sudo apt-get install libfreetype6-dev -y`
	* `sudo apt-get install liblcms2-dev -y`
	* `sudo apt-get install libopenjp2-7 -y`
	* `sudo apt-get install libtiff5-dev -y`
* copy new file **[displaymetar.py](displaymetar.py)** into the same folder as **[metar.py](metar.py)**
* Use the latest version of **[metar.py](metar.py)** and **[pixelsoff.py](pixelsoff.py)** for the new functionality
* The display is re-initialised on every run, and display errors are written to the log (even without `-l`)
* Configure **[metar.py](metar.py)** and set **`ACTIVATE_EXTERNAL_METAR_DISPLAY`** parameter to **True**.
* Configure the `DISPLAY_ROTATION_SPEED` to your desired timing, the default in `metar.py` is 6 seconds.

## Changelist
To see a list of changes to the metar script over time, refer to [CHANGELIST.md](CHANGELIST.md)
