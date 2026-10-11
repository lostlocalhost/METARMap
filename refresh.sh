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

# Stop the previous run with ONE SIGTERM to the python process itself (not sudo,
# which would relay a second signal), then wait for it to actually exit so the
# old run cannot touch the LEDs/OLED after the new one starts.
PAT='^/usr/bin/python3 /home/pi/METARMap/metar.py'
/usr/bin/sudo /usr/bin/pkill -TERM -f "$PAT" >> "$LOG" 2>&1 || true
for _ in $(seq 1 20); do
    /usr/bin/pgrep -f "$PAT" > /dev/null || break
    sleep 1
done
if /usr/bin/pgrep -f "$PAT" > /dev/null; then
    echo "refresh.sh: previous metar.py did not exit after 20s, killing at $(date)" >> "$LOG"
    /usr/bin/sudo /usr/bin/pkill -KILL -f "$PAT" >> "$LOG" 2>&1 || true
    sleep 1
fi

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
