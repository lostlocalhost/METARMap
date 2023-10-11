#!/bin/bash
echo 'start.sh:' $(date) >> /home/pi/METARMap/Logs/metar_start.log 2>&1 
/home/pi/METARMap/refresh.sh >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1
