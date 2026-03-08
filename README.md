# ngrok One-Port Workaround Using nginx

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

- A machine running **Linux, macOS, Windows (native), or WSL2**
- A free ngrok account → [ngrok.com](https://ngrok.com)
- `sudo` / admin access (needed to run nginx)

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

### Windows (native)

1. Go to [nginx.org/en/download.html](https://nginx.org/en/download.html)
2. Download the latest **Stable version** zip (e.g. `nginx-1.26.x.zip`)
3. Extract the zip to a simple path with no spaces, for example: `C:\nginx`
4. You should now have `C:\nginx\nginx.exe` and `C:\nginx\conf\nginx.conf`

> **Tip**: Avoid paths with spaces (e.g. `C:\Program Files\`) — nginx on Windows does not handle them well.

**Verify it installed:**

```bash
# Linux / macOS / WSL2
nginx -v

# Windows — open Command Prompt, navigate to the nginx folder, then run:
cd C:\nginx
nginx -v
```

Both should print something like: `nginx version: nginx/1.26.x`

> **More info**: [nginx beginner's guide](https://nginx.org/en/docs/beginners_guide.html) | [nginx on Windows](https://nginx.org/en/docs/windows.html)

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

### Windows (native)

**Option A — Chocolatey** (recommended if you have it):

```powershell
choco install ngrok
```

**Option B — winget**:

```powershell
winget install ngrok.ngrok
```

**Option C — manual**:

1. Go to [ngrok.com/download](https://ngrok.com/download)
2. Download the Windows zip
3. Extract `ngrok.exe` to a folder, e.g. `C:\ngrok\`
4. Add `C:\ngrok\` to your system PATH so you can run `ngrok` from any terminal
   - Search **"Environment Variables"** in the Start menu → Edit the system environment variables → Environment Variables → select `Path` → Edit → New → paste `C:\ngrok\`

**Verify it installed:**

```bash
ngrok version
# Should print something like: ngrok version 3.x.x
```

> **More info**: [ngrok installation docs](https://ngrok.com/docs/getting-started/)

---

## Step 3 — Connect ngrok to your account

1. Sign up or log in at [ngrok.com](https://ngrok.com)
2. Go to your [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken) and copy your **authtoken**
3. Run this command in any terminal, replacing `<YOUR_TOKEN>` with your actual token:

```bash
ngrok config add-authtoken <YOUR_TOKEN>
```

You only need to do this once — it saves the token to your local config file.

---

## Step 4 — Set up the nginx config

Clone or download this repo, then place the `nginx.conf` file wherever you want. We recommend your project folder.

The full config is in [`nginx.conf`](nginx.conf) in this repo. Here's what it contains:

```nginx
# Custom nginx config - no root required for this file
# But you'll still need sudo to run nginx on port 80

worker_processes  1;

events {
    worker_connections 1024;
}

http {

    # Linux/WSL2 only: redirect temp files to /tmp to avoid permission issues
    # when running nginx with a custom config file.
    # Windows users: remove or comment out these 5 lines — nginx handles temp files automatically.
    client_body_temp_path /tmp/nginx_client_temp;
    proxy_temp_path       /tmp/nginx_proxy_temp;
    fastcgi_temp_path     /tmp/nginx_fastcgi_temp;
    uwsgi_temp_path       /tmp/nginx_uwsgi_temp;
    scgi_temp_path        /tmp/nginx_scgi_temp;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen 6969;  # Single port for ngrok - nginx listens here
        server_name localhost;

        # Backend API routes - forward to port 3000
        location /api/ {
            proxy_pass http://localhost:3000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }

        # Frontend - forward everything else to port 8000
        location / {
            proxy_pass http://localhost:8000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
```

**You can change the port numbers** (`3000`, `8000`) to match whatever ports your apps run on. Just edit `nginx.conf` in any text editor before starting.

### Windows: temp folder config

The `client_body_temp_path` and related lines in `nginx.conf` are **only needed on Linux/WSL2** — they redirect temp files to `/tmp/` to avoid permission issues when running nginx with a custom config.

On **native Windows**, nginx automatically creates a `temp\` folder inside its own installation directory and uses it by default. You can safely **remove or ignore those lines** when using Windows.

---

## Step 5 — Start nginx with the config

### Linux / macOS / WSL2

> You need `sudo` because nginx binds to a port.

Navigate to the folder containing `nginx.conf`, then run:

```bash
sudo nginx -c "$(pwd)/nginx.conf"
```

`$(pwd)` fills in the absolute path automatically — nginx requires it.

Reload after config changes:

```bash
sudo nginx -c "$(pwd)/nginx.conf" -s reload
```

Stop nginx:

```bash
sudo nginx -s stop
```

### Windows (native)

Open **Command Prompt as Administrator** (right-click → Run as administrator), navigate to where `nginx.conf` is, then run:

```cmd
cd C:\nginx
nginx -c C:\path\to\your\nginx.conf
```

Replace `C:\path\to\your\nginx.conf` with the actual full path to the config file, for example:

```cmd
nginx -c C:\Users\YourName\projects\turbodocx\nginx\nginx.conf
```

Reload after config changes:

```cmd
nginx -c C:\Users\YourName\projects\turbodocx\nginx\nginx.conf -s reload
```

Stop nginx:

```cmd
nginx -s stop
```

**Verify nginx is running** (any OS):

```bash
curl http://localhost:6969
# You should see your frontend's HTML, or a response from your app
```

> **Troubleshooting nginx**: [common nginx errors](https://docs.nginx.com/nginx/admin-guide/monitoring/logging/) | [nginx on Windows docs](https://nginx.org/en/docs/windows.html)

---

## Step 6 — Start your apps

Make sure your actual apps are running on their ports **before** sharing the ngrok URL.

Run each in a separate terminal:

```bash
# Terminal 1 — backend on port 3000
npm run dev

# Terminal 2 — frontend on port 8000
npm run dev
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

> **Note**: The URL changes every time you restart ngrok on the free plan. A paid plan gives you a stable static domain.

> **More info**: [ngrok HTTP tunnels docs](https://ngrok.com/docs/http/)

---

## Full startup checklist

### Linux / macOS / WSL2

Run these in order, each in its own terminal:

```bash
# 1. Start nginx
sudo nginx -c "$(pwd)/nginx.conf"

# 2. Start your backend (new terminal)
npm run dev   # port 3000

# 3. Start your frontend (new terminal)
npm run dev   # port 8000

# 4. Start ngrok (new terminal)
ngrok http 6969
```

### Windows (native)

Open **Command Prompt as Administrator** for step 1, regular terminals for the rest:

```cmd
:: 1. Start nginx (Admin Command Prompt)
nginx -c C:\path\to\nginx.conf

:: 2. Start your backend (new terminal)
npm run dev

:: 3. Start your frontend (new terminal)
npm run dev

:: 4. Start ngrok (new terminal)
ngrok http 6969
```

Then copy the ngrok URL and share it.

---

## Teardown

### Linux / macOS / WSL2

```bash
# Stop ngrok: press Ctrl+C in the ngrok terminal

# Stop nginx
sudo nginx -s stop
```

### Windows (native)

```cmd
:: Stop ngrok: press Ctrl+C in the ngrok terminal

:: Stop nginx (Admin Command Prompt)
nginx -s stop
```

---

## Troubleshooting

| Problem                                                      | Fix                                                                                                                  |
| ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- |
| `nginx: [error] open() "/path/nginx.conf" failed`            | Use the full absolute path. On Linux/macOS use `$(pwd)/nginx.conf`. On Windows write it out: `C:\path\to\nginx.conf` |
| `bind() to 0.0.0.0:6969 failed (98: Address already in use)` | Port 6969 is taken. Stop the other process or change the port in `nginx.conf` and in the ngrok command               |
| Windows: `CreateFile()` or permission errors on temp folders | Create the temp folders manually (see Step 4 Windows section) and run Command Prompt as Administrator                |
| Windows: nginx starts but immediately closes                 | Check `C:\nginx\logs\error.log` for the error message                                                                |
| `curl http://localhost:6969` returns nothing                 | Your app on port 3000 or 8000 isn't running yet                                                                      |
| ngrok shows `ERR_NGROK_3200`                                 | Your local server isn't running or isn't reachable on the expected port                                              |
| Teammate gets a browser warning about the ngrok URL          | They need to click "Visit Site" to bypass ngrok's free tier interstitial page                                        |
| Teammate's API calls fail with CORS errors                   | Make sure your backend's CORS config allows the ngrok domain                                                         |

---

## References

- [nginx documentation](https://nginx.org/en/docs/)
- [nginx on Windows](https://nginx.org/en/docs/windows.html)
- [nginx reverse proxy guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [ngrok getting started](https://ngrok.com/docs/getting-started/)
- [ngrok HTTP tunnels](https://ngrok.com/docs/http/)
- [ngrok free vs paid](https://ngrok.com/pricing)
- [How to add a folder to PATH on Windows](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/)
