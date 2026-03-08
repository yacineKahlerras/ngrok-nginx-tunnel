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

## Quick Start

Already have nginx and ngrok installed? Here's the full sequence every time you want to share.

### Linux / macOS / WSL2

```bash
# 1. Start nginx — use the full path to your nginx config file
sudo nginx -c "/home/yourName/myproject/nginx/nginx.conf"

# 2. Start ngrok in a new terminal — copy the URL it gives you
ngrok http 6969

# 3. Update your .env files with the ngrok URL, then save

# 4. Start your backend in a new terminal
npm run dev   # port 3000

# 5. Start your frontend in a new terminal
npm run dev   # port 8000

# 6. Share the ngrok URL with your teammate
```

### Windows (native)

```cmd
:: 1. Start nginx — Admin Command Prompt, use the full path to your nginx config file
nginx -c C:\Users\YourName\myproject\nginx\nginx.conf

:: 2. Start ngrok in a new terminal — copy the URL it gives you
ngrok http 6969

:: 3. Update your .env files with the ngrok URL, then save

:: 4. Start your backend in a new terminal
npm run dev

:: 5. Start your frontend in a new terminal
npm run dev

:: 6. Share the ngrok URL with your teammate
```

> First time? Read the step-by-step setup below.

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

Run these 3 commands one at a time. They add ngrok as a trusted source so `apt` can install it like any other package.

**Command 1** — download and trust ngrok's security key:
```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
```

**Command 2** — tell apt where to find ngrok:
```bash
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
```

**Command 3** — install it:
```bash
sudo apt update && sudo apt install ngrok -y
```

> **Simpler alternative**: if you have Snap installed, just run `snap install ngrok` and skip the 3 commands above.

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

create and place this `nginx.conf` file wherever you want. We recommend your project folder.

The full config is in [`nginx.conf`](nginx.conf) in this repo. Here's what it contains:

```nginx
worker_processes  1;

events {
    worker_connections 1024;
}

http {
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

---

## Step 5 — Update your environment variables

Your frontend and backend need to know the ngrok URL so they talk to each other through the tunnel instead of `localhost`.

> **Heads up**: The variables below are specific to my project's stack (Gatsby frontend + Express backend + Auth0). **Your project probably uses different variable names** — that's fine. The concept is the same: find whichever env var holds your API URL or backend URL, and swap `localhost` for your ngrok URL. The names don't matter, only what they point to.

We've included two ready-to-use env files in this repo as examples: [`.env.frontend`](.env.frontend) and [`.env.backend`](.env.backend).

### The idea in plain English

Think of it like this: your frontend has a note somewhere that says _"send API calls to `http://localhost:3000`"_. While you're sharing via ngrok, you need to change that note to say _"send API calls to `https://abc123.ngrok-free.app/api`"_ instead. That's all this step is — find that note in your `.env` file and update the URL.

When you're done sharing, you change it back (or comment it out and restore the localhost one).

### What the variables do in this project

**Frontend** — copy these into your frontend `.env.development` (or equivalent):

```env
GATSBY_API_URL=https://<YOUR-NGROK-URL>.ngrok-free.app/api  # tells the frontend where to send API calls
GATSBY_DOMAIN=https://<YOUR-NGROK-URL>.ngrok-free.app       # the public URL of the app itself
GATSBY_AUTH0_DOMAIN=dev-<YOUR-AUTH0>.us.auth0.com           # your Auth0 domain (unchanged)
GATSBY_AUTH0_CLIENT_ID=<YOUR-CLIENT-ID>                     # your Auth0 client ID (unchanged)
GATSBY_AUTH0_AUDIENCE=https://dev-<YOUR-AUTH0>.us.auth0.com/api/v2/  # your Auth0 audience (unchanged)
```

**Backend** — copy these into your backend `.env` (or equivalent):

```env
FRONTEND_URL=https://<YOUR-NGROK-URL>.ngrok-free.app        # tells the backend which origin to trust (CORS)
AUTH0_AUDIENCE=https://dev-<YOUR-AUTH0>.us.auth0.com/api/v2/  # your Auth0 audience (unchanged)
AUTH0_ISSUERBASEURL=https://dev-<YOUR-AUTH0>.us.auth0.com   # your Auth0 issuer (unchanged)
```

### How to do it

**1. Start ngrok to get your URL**

Open a terminal and run:

```bash
ngrok http 6969
```

ngrok will show a screen like this:

```
Forwarding    https://abc123.ngrok-free.app -> http://localhost:6969
```

That `https://abc123.ngrok-free.app` part is your URL. Copy it — you'll paste it into your `.env` files next.

> Keep this terminal open. Closing it kills the tunnel and the URL stops working.

**2. Update your `.env` files**

Open your frontend `.env.development` and your backend `.env` in a text editor, find the relevant lines, and replace `localhost` (or the old ngrok URL) with the new one. For example:

```env
# Before
GATSBY_API_URL=http://localhost:3000

# After
GATSBY_API_URL=https://abc123.ngrok-free.app/api
```

**3. Restart both servers** so they pick up the new values:

```bash
# Stop each server with Ctrl+C, then start it again
npm run dev
```

**To stop ngrok** when you're done: go to the ngrok terminal and press `Ctrl+C`. The tunnel closes immediately and the URL stops working for your teammate.

### When you're done sharing

Comment out those lines instead of deleting them — you'll want them ready for next time:

**Frontend `.env.development`:**

```env
# GATSBY_API_URL=https://<YOUR-NGROK-URL>.ngrok-free.app/api
# GATSBY_DOMAIN=https://<YOUR-NGROK-URL>.ngrok-free.app
```

**Backend `.env`:**

```env
# FRONTEND_URL=https://<YOUR-NGROK-URL>.ngrok-free.app
```

Next time you share, just uncomment those lines, update the URL (it changes every ngrok restart), and restart your servers.

---

## Step 6 — Start nginx with the config

### Linux / macOS / WSL2

> You need `sudo` because nginx needs special permission to open a port.

Run this command with the **full path** to your `nginx.conf` file:

```bash
sudo nginx -c "/home/yourName/myproject/nginx/nginx.conf"
```

Just replace `/home/yourName/myproject/nginx/nginx.conf` with the actual location of your file. Not sure what your full path is? Open a terminal in the folder where `nginx.conf` lives and run `pwd` — it prints the full path for you.

Reload after config changes (same path):

```bash
sudo nginx -c "/home/yourName/myproject/nginx/nginx.conf" -s reload
```

Stop nginx:

```bash
sudo nginx -s stop
```

### Windows (native)

Open **Command Prompt as Administrator** (right-click the Start menu → "Command Prompt (Admin)"), then run:

```cmd
nginx -c C:\Users\YourName\myproject\nginx\nginx.conf
```

> **Don't know your full path?** Open File Explorer, go to the folder where `nginx.conf` is, click the address bar at the top — it shows the full path. Copy and paste it, then add `\nginx.conf` at the end.

Reload after config changes:

```cmd
nginx -c C:\Users\YourName\myproject\nginx\nginx.conf -s reload
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

## Step 7 — Start your apps

Make sure your actual apps are running on their ports **before** sharing the ngrok URL.

Run each in a separate terminal:

```bash
# Terminal 1 — backend on port 3000
npm run dev

# Terminal 2 — frontend on port 8000
npm run dev
```

---

## Step 8 — Start ngrok

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
# 1. Start nginx — replace the path with your actual nginx.conf location
sudo nginx -c "/home/yourName/myproject/nginx/nginx.conf"

# 2. Start ngrok (new terminal) — copy the URL it gives you
ngrok http 6969

# 3. Update your .env files with the ngrok URL

# 4. Start your backend (new terminal)
npm run dev   # port 3000

# 5. Start your frontend (new terminal)
npm run dev   # port 8000

# 6. Share the ngrok URL with your teammate
```

### Windows (native)

Open **Command Prompt as Administrator** for step 1, regular terminals for the rest:

```cmd
:: 1. Start nginx (Admin Command Prompt)
nginx -c C:\Users\YourName\myproject\nginx\nginx.conf

:: 2. Start ngrok (new terminal) — copy the URL it gives you
ngrok http 6969

:: 3. Update your .env files with the ngrok URL

:: 4. Start your backend (new terminal)
npm run dev

:: 5. Start your frontend (new terminal)
npm run dev

:: 6. Share the ngrok URL with your teammate
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

Then open your `.env.development` (frontend) and `.env` (backend) and comment out the ngrok lines:

```env
# GATSBY_API_URL=https://...
# GATSBY_DOMAIN=https://...
# FRONTEND_URL=https://...
```

Restart your servers normally so they go back to using `localhost`.

### Windows (native)

```cmd
:: Stop ngrok: press Ctrl+C in the ngrok terminal

:: Stop nginx (Admin Command Prompt)
nginx -s stop
```

Then open your `.env.development` (frontend) and `.env` (backend) and comment out the ngrok lines:

```env
# GATSBY_API_URL=https://...
# GATSBY_DOMAIN=https://...
# FRONTEND_URL=https://...
```

Restart your servers normally so they go back to using `localhost`.

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
