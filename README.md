# ngrok-port-forwarding

Share your local dev environment with teammates using **nginx + ngrok** — without paying for a ngrok upgrade.

The trick: ngrok free tier only lets you expose **one port at a time**. nginx acts as a router that listens on that one port and forwards traffic to multiple local services (frontend, backend, etc.).

```
Teammate's browser
       │
       ▼
  ngrok tunnel  (one public URL)
       │
       ▼
  nginx :6969   (single port)
      / \
     /   \
:8000   :3000
Frontend  Backend API
```

---

## Prerequisites

- A machine running **Linux, macOS, or WSL2** (Windows Subsystem for Linux)
- A free ngrok account → [ngrok.com](https://ngrok.com)
- `sudo` access (needed to run nginx)

---

## Step 1 — Install nginx

### Ubuntu / Debian / WSL2

```bash
sudo apt update
sudo apt install nginx -y
```

### macOS (Homebrew)

```bash
brew install nginx
```

Verify it installed:

```bash
nginx -v
# Should print something like: nginx version: nginx/1.24.0
```

> **More info**: [nginx beginner's guide](https://nginx.org/en/docs/beginners_guide.html)

---

## Step 2 — Install ngrok

### Ubuntu / Debian / WSL2

```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list

sudo apt update && sudo apt install ngrok -y
```

### macOS (Homebrew)

```bash
brew install ngrok/ngrok/ngrok
```

### Windows

Download the installer from [ngrok.com/download](https://ngrok.com/download) and run it.

Verify it installed:

```bash
ngrok version
# Should print something like: ngrok version 3.x.x
```

> **More info**: [ngrok installation docs](https://ngrok.com/docs/getting-started/)

---

## Step 3 — Connect ngrok to your account

1. Sign up or log in at [ngrok.com](https://ngrok.com)
2. Go to your [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken) and copy your **authtoken**
3. Run this command, replacing `<YOUR_TOKEN>` with your actual token:

```bash
ngrok config add-authtoken <YOUR_TOKEN>
```

You only need to do this once — it saves the token to your local config.

---

## Step 4 — Set up the nginx config

Clone or download this repo, then copy the config file to wherever you want to keep it. We recommend your project folder.

The config file is `nginx.conf`. Here's what it does:

```nginx
server {
    listen 6969;  # <-- nginx listens on this single port

    # Anything starting with /api/ goes to your backend (port 3000)
    location /api/ {
        proxy_pass http://localhost:3000/;
    }

    # Everything else goes to your frontend (port 8000)
    location / {
        proxy_pass http://localhost:8000;
    }
}
```

**You can change the port numbers** (`3000`, `8000`) to match whatever ports your apps run on. Just edit `nginx.conf` in a text editor before starting.

---

## Step 5 — Start nginx with the config

> **Important**: You must use `sudo` because nginx needs to bind to a port.

Navigate to the folder containing `nginx.conf`, then run:

```bash
sudo nginx -c "$(pwd)/nginx.conf"
```

The `$(pwd)` automatically fills in the full path to your current folder — nginx requires an **absolute path** to the config file.

**Verify nginx is running:**

```bash
curl http://localhost:6969
# You should see your frontend's HTML, or a response from your app
```

**If nginx is already running** and you want to reload after changing the config:

```bash
sudo nginx -c "$(pwd)/nginx.conf" -s reload
```

**To stop nginx:**

```bash
sudo nginx -s stop
```

> **Troubleshooting nginx**: [common nginx errors](https://docs.nginx.com/nginx/admin-guide/monitoring/logging/)

---

## Step 6 — Start your apps

Make sure your actual apps are running on their respective ports **before** you share the ngrok URL.

For example (run each in a separate terminal):

```bash
# Terminal 1 — start your backend on port 3000
npm run dev   # or whatever your backend start command is

# Terminal 2 — start your frontend on port 8000
npm run dev   # or whatever your frontend start command is
```

---

## Step 7 — Start ngrok

In a new terminal, run:

```bash
ngrok http 6969
```

ngrok will display a screen like this:

```
Session Status     online
Account            your@email.com
Version            3.x.x
Forwarding         https://abc123.ngrok-free.app -> http://localhost:6969
```

Copy the `https://abc123.ngrok-free.app` URL and send it to your teammate.

- **Frontend**: `https://abc123.ngrok-free.app/`
- **Backend API**: `https://abc123.ngrok-free.app/api/`

> **Note**: The URL changes every time you restart ngrok on the free plan. If your teammate needs a stable URL, you'll need a paid ngrok plan or a static domain.

> **More info**: [ngrok HTTP tunnels docs](https://ngrok.com/docs/http/)

---

## Full startup checklist

Every time you want to share your environment, run these steps in order:

```bash
# 1. Start nginx (from the folder containing nginx.conf)
sudo nginx -c "$(pwd)/nginx.conf"

# 2. Start your backend (in a separate terminal)
npm run dev   # backend on port 3000

# 3. Start your frontend (in a separate terminal)
npm run dev   # frontend on port 8000

# 4. Start ngrok (in a separate terminal)
ngrok http 6969
```

Then copy the ngrok URL and share it.

---

## Teardown

When you're done:

```bash
# Stop ngrok: press Ctrl+C in the ngrok terminal

# Stop nginx
sudo nginx -s stop
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `nginx: [error] open() "/path/nginx.conf" failed` | Make sure you run the command from the same folder as `nginx.conf`, and use `$(pwd)` |
| `bind() to 0.0.0.0:6969 failed (98: Address already in use)` | Something is already on port 6969. Either stop it or change the port in `nginx.conf` and in the ngrok command |
| `curl http://localhost:6969` returns nothing | Your app on port 3000 or 8000 isn't running yet |
| ngrok shows `ERR_NGROK_3200` | Your local server isn't running or isn't reachable |
| Teammate gets a browser warning about the ngrok URL | They need to click "Visit Site" to bypass ngrok's free tier interstitial page |

---

## References

- [nginx documentation](https://nginx.org/en/docs/)
- [nginx reverse proxy guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [ngrok getting started](https://ngrok.com/docs/getting-started/)
- [ngrok HTTP tunnels](https://ngrok.com/docs/http/)
- [ngrok free vs paid](https://ngrok.com/pricing)
