#!/bin/bash
cd /home/pi/METARMap

sudo mkdir Logs
cd Logs
sudo touch metar_refresh.log
sudo touch metar_start.log
sudo chmod 777 metar_refresh.log
sudo chmod 777 metar_start.log

cd /home/pi/METARMap

sudo chmod +x refresh.sh
sudo chmod +x lightsoff.sh
sudo chmod +x start.sh
sudo chmod +r metar.py
sudo chmod +r pixelsoff.py
sudo chmod +r displaymetar.py
sudo chmod +r find_airports.py
sudo chmod +r airports
sudo chmod +r airports_tst

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install python3 python3-pip i2c-tools fonts-dejavu libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev libopenjp2-7 libtiff5-dev -y
sudo pip3 install rpi_ws281x adafruit-circuitpython-neopixel adafruit-circuitpython-ssd1306 pillow icecream pytz

echo Done
