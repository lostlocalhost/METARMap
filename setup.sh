#!/bin/bash
cd /home/pi/METARMap || exit 1

sudo mkdir -p Logs
cd Logs || exit 1
sudo touch metar_refresh.log
sudo touch metar_start.log
sudo chmod 777 metar_refresh.log
sudo chmod 777 metar_start.log

cd /home/pi/METARMap || exit 1

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
sudo apt-get upgrade -y
sudo apt-get install python3 python3-pip i2c-tools fonts-dejavu libjpeg-dev zlib1g-dev libfreetype6-dev liblcms2-dev libopenjp2-7 libtiff5-dev python-six -y
# Soft pins: pillow 9+ has getbbox; astral 2.x matches the geocoder path in metar.py
sudo pip3 install 'rpi_ws281x>=4.3.0' 'adafruit-circuitpython-neopixel>=6.3.0' 'adafruit-circuitpython-ssd1306>=2.12.0' 'pillow>=9.0.0,<12' 'icecream>=2.1.0' 'pytz>=2022.1' 'astral>=2.2,<4'

# Optional: rotate Logs/ so SD card does not fill (safe if logrotate absent)
if [ -f packaging/metarmap-logrotate ]; then
  sudo cp packaging/metarmap-logrotate /etc/logrotate.d/metarmap || true
fi

echo Done
