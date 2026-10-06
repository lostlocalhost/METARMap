#!/bin/bash
# Invoked by cron every 5 minutes. Ensures only one refresh starts at a time,
# stops any leftover metar.py, then launches a new run.
MAPDIR=/home/pi/METARMap
LOG=$MAPDIR/Logs/metar_refresh.log
LOCK=$MAPDIR/metar.refresh.lock
PIDFILE=$MAPDIR/metarpid.pid
MAX_LOG_BYTES=2097152   # ~2 MiB soft cap

mkdir -p "$MAPDIR/Logs"

# Soft-cap log growth so a runaway log cannot fill the SD card
if [ -f "$LOG" ]; then
    size=$(wc -c < "$LOG" 2>/dev/null || echo 0)
    if [ "$size" -gt "$MAX_LOG_BYTES" ]; then
        tail -c "$MAX_LOG_BYTES" "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
        echo "refresh.sh: truncated log at $(date)" >> "$LOG"
    fi
fi

echo 'refresh.sh:' $(date) >> "$LOG" 2>&1

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

# Non-blocking flock: only cover kill+start. Close fd 9 before launching
# metar.py so the long-lived process does not inherit (and hold) the lock.
(
flock -n 9 || {
    echo "refresh.sh: lock held by another instance, exiting at $(date)" >> "$LOG"
    exit 0
}

# Prefer killing by script path (survives sudo PID reuse); fall back to pidfile
/usr/bin/sudo /usr/bin/pkill -f '/home/pi/METARMap/metar.py' >> "$LOG" 2>&1 || true
if [ -f "$PIDFILE" ]; then
    /usr/bin/sudo /usr/bin/pkill -F "$PIDFILE" >> "$LOG" 2>&1 || true
fi
# Brief pause so NeoPixel DMA can release before the next init
sleep 1

# Drop the lock before starting metar — otherwise sudo/python inherits fd 9
# and holds the lock for the whole blink window (~280s), so the next cron
# exits and the map goes dark until the cycle after that.
exec 9>&-

if [ $log = true ] && [ $test = true ]; then
   /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py -l -t >> "$LOG" 2>&1 & echo $! > "$PIDFILE"
elif "$log"; then
   /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py -l >> "$LOG" 2>&1 & echo $! > "$PIDFILE"
elif "$test"; then
   /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py -t >> "$LOG" 2>&1 & echo $! > "$PIDFILE"
else
   /usr/bin/sudo /usr/bin/python3 /home/pi/METARMap/metar.py >> "$LOG" 2>&1 & echo $! > "$PIDFILE"
fi
echo "refresh.sh: started metar.py pid $(cat "$PIDFILE") at $(date)" >> "$LOG"
) 9>"$LOCK"
