#!/bin/bash
MAPDIR=/home/pi/METARMap
LOG=$MAPDIR/Logs/metar_start.log
MAX_LOG_BYTES=1048576   # ~1 MiB soft cap

mkdir -p "$MAPDIR/Logs"
if [ -f "$LOG" ]; then
    size=$(wc -c < "$LOG" 2>/dev/null || echo 0)
    if [ "$size" -gt "$MAX_LOG_BYTES" ]; then
        tail -c "$MAX_LOG_BYTES" "$LOG" > "$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG"
        echo "start.sh: truncated log at $(date)" >> "$LOG"
    fi
fi

echo 'start.sh:' $(date) >> "$LOG" 2>&1
/home/pi/METARMap/refresh.sh >> /home/pi/METARMap/Logs/metar_refresh.log 2>&1
