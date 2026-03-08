#!/bin/bash

# ─────────────────────────────────────────────
# EDIT THIS: full path to your nginx.conf
NGINX_CONF="/home/yacine/turbodocx/nginx/nginx.conf"

# EDIT THIS: the port nginx listens on (must match nginx.conf)
NGROK_PORT=6969

# EDIT THESE: full paths to your frontend and backend .env files
FRONTEND_ENV="/home/yacine/turbodocx/f/.env.development"
BACKEND_ENV="/home/yacine/turbodocx/b/.env"
# ─────────────────────────────────────────────
# Lines tagged with # [ngrok] in your .env files will be auto-toggled.
# Make sure each ngrok line ends with: # [ngrok]

comment_ngrok() {
    sed -i 's/^\([^#].*# \[ngrok\]\)/#\1/' "$1"
}

uncomment_ngrok() {
    sed -i 's/^#\(.*# \[ngrok\]\)/\1/' "$1"
}

cleanup() {
    echo ""
    echo "Stopping nginx..."
    sudo nginx -s stop 2>/dev/null

    echo "Commenting out ngrok vars..."
    comment_ngrok "$FRONTEND_ENV"
    comment_ngrok "$BACKEND_ENV"

    echo "Done. Restart your servers to go back to localhost."
}
trap cleanup EXIT

echo "Uncommenting ngrok vars..."
uncomment_ngrok "$FRONTEND_ENV"
uncomment_ngrok "$BACKEND_ENV"

echo "Starting nginx..."
sudo nginx -c "$NGINX_CONF"
if [ $? -ne 0 ]; then
    echo "nginx failed to start. Check the path to your nginx.conf."
    exit 1
fi

echo ""
echo "nginx is running on port $NGROK_PORT"
echo "Starting ngrok... copy the Forwarding URL, update it in your .env files, then restart your servers."
echo "Press Ctrl+C to stop everything and restore your .env files."
echo ""

ngrok http $NGROK_PORT