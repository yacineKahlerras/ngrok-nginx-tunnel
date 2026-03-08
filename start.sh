#!/bin/bash

# ─────────────────────────────────────────────
# EDIT THIS: full path to your nginx.conf
NGINX_CONF="/home/yourName/myproject/nginx/nginx.conf"

# EDIT THIS: the port nginx listens on (must match nginx.conf)
NGROK_PORT=6969
# ─────────────────────────────────────────────

# Stop nginx when the script exits (Ctrl+C or any exit)
cleanup() {
    echo ""
    echo "Stopping nginx..."
    sudo nginx -s stop 2>/dev/null
    echo "Done."
}
trap cleanup EXIT

echo "Starting nginx..."
sudo nginx -c "$NGINX_CONF"
if [ $? -ne 0 ]; then
    echo "nginx failed to start. Check the path to your nginx.conf."
    exit 1
fi

echo ""
echo "nginx is running on port $NGROK_PORT"
echo "Starting ngrok... copy the Forwarding URL and paste it into your .env files."
echo "Press Ctrl+C to stop everything."
echo ""

ngrok http $NGROK_PORT
