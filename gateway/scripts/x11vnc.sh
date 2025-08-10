#!/bin/bash

# Clear Xvfb lockfile
rm -f /tmp/.X0-lock

# Start Xvfb so that TWS/IBGateway will run
Xvfb :0 -ac -screen 0 1920x1080x24 &

export DISPLAY=:0

# Start VNC server, listening at 5900 by default
if [ -n "$VNC_SERVER_PASSWORD" ]; then
    echo "Starting VNC server"
    x11vnc -ncache 10 -ncache_cr -display :0 -forever -shared -bg -noipv6 -passwd $VNC_SERVER_PASSWORD &
else
    x11vnc -ncache 10 -ncache_cr -display :0 -forever -shared -bg -noipv6 &
fi