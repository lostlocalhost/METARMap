#/usr/bin/sudo pkill -F /home/pi/METARMap/offpid.pid
/usr/bin/sudo pkill -F /home/pi/METARMap/metarpid.pid
echo 'refresh.sh:' $(date) >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1

log=false
test=false
while getopts 'lt' opt; do
        case $opt in
            l) log=true ;;
            t) test=true ;;
            *) echo 'Error in command line parsing' >&2
               exit 1
        esac
    done
   #  shift "$(( OPTIND - 1 ))"

if [ $log = true ] && [ $test = true ]; then
   /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py -l -t >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1 & echo $! > /home/pi/METARMap/metarpid.pid
elif "$log"; then
   /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py -l >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1 & echo $! > /home/pi/METARMap/metarpid.pid
elif "$test"; then
   /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py -t >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1 & echo $! > /home/pi/METARMap/metarpid.pid
else
   /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1 & echo $! > /home/pi/METARMap/metarpid.pid
fi

