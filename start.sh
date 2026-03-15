#!/bin/bash

# -----------------------------------------------
# DaemonMC - Pterodactyl Start Script
# Runtime: .NET 8 | Auto-restart on crash
# -----------------------------------------------

DAEMON_DLL="DaemonMC.dll"
DOWNLOAD_URL="https://github.com/TeamDeamonMC/DaemonMC/releases/latest/download/DaemonMC.dll"

cd /mnt/server || { echo "[ERROR] Could not change to /mnt/server"; exit 1; }

# --- Check for DaemonMC.dll, download if missing ---
if [ ! -f "$DAEMON_DLL" ]; then
    echo "[WARN] $DAEMON_DLL not found. Attempting to download..."
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$DAEMON_DLL" "$DOWNLOAD_URL"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "$DAEMON_DLL" "$DOWNLOAD_URL"
    else
        echo "[ERROR] Neither wget nor curl is available. Cannot download $DAEMON_DLL."
        exit 1
    fi

    if [ ! -f "$DAEMON_DLL" ]; then
        echo "[ERROR] Download failed. Please manually upload $DAEMON_DLL to /mnt/server."
        exit 1
    fi

    echo "[INFO] Download complete."
fi

# --- Auto-restart loop ---
CRASH_COUNT=0
MAX_CRASHES=5
CRASH_WINDOW=60  # seconds
LAST_CRASH_TIME=0

while true; do
    echo "[INFO] Starting DaemonMC..."
    dotnet "$DAEMON_DLL"
    EXIT_CODE=$?

    NOW=$(date +%s)
    TIME_SINCE_LAST=$((NOW - LAST_CRASH_TIME))

    if [ $EXIT_CODE -eq 0 ]; then
        echo "[INFO] Server exited cleanly (code 0). Shutting down."
        exit 0
    fi

    echo "[WARN] Server stopped with exit code $EXIT_CODE."

    # Reset crash counter if last crash was more than CRASH_WINDOW seconds ago
    if [ $TIME_SINCE_LAST -gt $CRASH_WINDOW ]; then
        CRASH_COUNT=0
    fi

    CRASH_COUNT=$((CRASH_COUNT + 1))
    LAST_CRASH_TIME=$NOW

    if [ $CRASH_COUNT -ge $MAX_CRASHES ]; then
        echo "[ERROR] Server crashed $MAX_CRASHES times within ${CRASH_WINDOW}s. Giving up."
        exit 1
    fi

    echo "[WARN] Server crashed. Restarting in 5 seconds... (crash $CRASH_COUNT/$MAX_CRASHES)"
    sleep 5
done
