#/usr/bin/sudo pkill -F /home/pi/METARMap/offpid.pid
/usr/bin/sudo pkill -F /home/pi/METARMap/metarpid.pid
echo 'refresh.sh:' $(date) >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1


while getopts 'l' opt; do
        case $opt in
            l) flag=true ;;
            *) echo 'Error in command line parsing' >&2
               exit 1
        esac
    done
    shift "$(( OPTIND - 1 ))"

    if "$flag"; then
       /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py -l >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1 & echo $! > /home/pi/METARMap/metarpid.pid
    else
       /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1 & echo $! > /home/pi/METARMap/metarpid.pid
    fi
