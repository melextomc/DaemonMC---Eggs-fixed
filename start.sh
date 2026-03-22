#!/bin/bash
while true; do
    echo "Starting server..."
    dotnet DaemonMC.dll
    echo "Server crashed. Restarting in 5 seconds..."
    sleep 5
done
