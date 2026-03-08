# ngrok One-Port Workaround Using nginx

Share your local app with a teammate via a public URL — for free.

---

## The problem & the fix

**The problem:** ngrok free tier only lets you expose **one port** at a time. Your app has two: a frontend and a backend.

**The fix:** nginx sits in the middle. It listens on one port and routes traffic to the right place based on the URL path.

```
Teammate's browser
       │
       ▼
  ngrok tunnel          ← one public URL, free tier
       │
       ▼
  nginx :6969           ← single port, splits traffic by URL path
      /       \
     ▼         ▼
:8000           :3000
Frontend      Backend API
```

**How the routing works in `nginx.conf`:**

```nginx
# Any URL starting with /api/ → goes to your backend on port 3000
location /api/ {
    proxy_pass http://localhost:3000/;
}

# Everything else → goes to your frontend on port 8000
location / {
    proxy_pass http://localhost:8000;
}
```

So `https://abc123.ngrok-free.app/` loads the frontend, and `https://abc123.ngrok-free.app/api/users` hits the backend. One URL, two services.

---

## ⚡ Quick Start

> Already have nginx + ngrok installed? Use the scripts below — they start everything and **auto-stop nginx when you hit Ctrl+C**.

### Linux / macOS / WSL2

**Option A — use the script (recommended):**

1. Open [`start.sh`](start.sh) in a text editor
2. On line 5, replace the path with the full path to your `nginx.conf`, for example:
```bash
NGINX_CONF="/home/yourName/myproject/nginx/nginx.conf"
```
3. Run it:
```bash
./start.sh
```
Ctrl+C stops ngrok and nginx automatically.

**Option B — manually:**

```bash
# 1. Start nginx (use the full path to your nginx.conf)
sudo nginx -c "/home/yourName/myproject/nginx/nginx.conf"

# 2. New terminal — start ngrok, copy the URL it prints
ngrok http 6969

# 3. Paste the ngrok URL into your .env files (see Environment Variables section)
#    then restart your servers

# 4. New terminal — start backend
npm run dev   # port 3000

# 5. New terminal — start frontend
npm run dev   # port 8000

# 6. Send the ngrok URL to your teammate
```

### Windows

**Option A — use the script (recommended):**

1. Open [`start.ps1`](start.ps1) in a text editor
2. On line 4, replace the path with the full path to your `nginx.conf`, for example:
```powershell
$NginxConf = "C:\Users\YourName\myproject\nginx\nginx.conf"
```
3. Run it in PowerShell **as Administrator**:
```powershell
.\start.ps1
```
Ctrl+C stops ngrok and nginx automatically.

**Option B — manually (Admin Command Prompt for step 1, regular terminals for the rest):**

```cmd
:: 1. Start nginx (use the full path to your nginx.conf)
nginx -c C:\Users\YourName\myproject\nginx\nginx.conf

:: 2. New terminal — start ngrok, copy the URL it prints
ngrok http 6969

:: 3. Paste the ngrok URL into your .env files (see Environment Variables section)
::    then restart your servers

:: 4. New terminal — start backend
npm run dev

:: 5. New terminal — start frontend
npm run dev

:: 6. Send the ngrok URL to your teammate
```

---

## First-time setup

### 1. Install nginx

**Ubuntu / Debian / WSL2**

```bash
sudo apt update && sudo apt install nginx -y
```

**macOS**

```bash
brew install nginx
```

**Windows**

1. Download the Stable zip from [nginx.org/en/download.html](https://nginx.org/en/download.html)
2. Extract to `C:\nginx` (no spaces in the path)

---

### 2. Install ngrok

**Ubuntu / Debian / WSL2** — run these 3 commands:

```bash
# Step A — trust ngrok's security key
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

# Step B — add ngrok to apt sources
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list

# Step C — install
sudo apt update && sudo apt install ngrok -y
```

> Have Snap? Just run `snap install ngrok` instead.

**macOS**

```bash
brew install ngrok/ngrok/ngrok
```

**Windows** — pick one:

```powershell
choco install ngrok       # if you have Chocolatey
winget install ngrok.ngrok  # if you have winget
```

Or download manually from [ngrok.com/download](https://ngrok.com/download) and add it to your PATH.

---

### 3. Connect ngrok to your account

1. Create a free account at [ngrok.com](https://ngrok.com)
2. Copy your authtoken from the [ngrok dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)
3. Run:

```bash
ngrok config add-authtoken <YOUR_TOKEN>
```

One-time setup. Done.

---

### 4. Place the nginx config

Copy [`nginx.conf`](nginx.conf) from this repo into your project folder.

The full config is already set up for you. The only things you might want to change are the port numbers if your apps don't run on `3000` and `8000`:

```nginx
location /api/ {
    proxy_pass http://localhost:3000/;  # ← change 3000 to your backend port
}
location / {
    proxy_pass http://localhost:8000;   # ← change 8000 to your frontend port
}
```

---

### 5. Update your environment variables

Your frontend and backend need to know the ngrok URL, otherwise they'll still talk to `localhost` and things will break.

> **Note:** The variable names below are specific to this project (Gatsby + Express + Auth0). Your project will have different names — just find whichever variable holds your API and Frontend URLs and update it.

**Frontend `.env.development`:**

```env
GATSBY_API_URL=https://abc123.ngrok-free.app/api
GATSBY_DOMAIN=https://abc123.ngrok-free.app
```

**Backend `.env`:**

```env
FRONTEND_URL=https://abc123.ngrok-free.app
```

Example env files are in this repo: [`.env.frontend`](.env.frontend) and [`.env.backend`](.env.backend).

**When you're done sharing**, comment these out (don't delete — you'll need them next time):

```env
# GATSBY_API_URL=https://abc123.ngrok-free.app/api
# FRONTEND_URL=https://abc123.ngrok-free.app
```

> The ngrok URL does **not** changes every time you restart ngrok. so you **do not** have to Update it in your `.env` files each session.

---

## Terminating

```bash
# Stop ngrok → Ctrl+C in the ngrok terminal

# Stop nginx
sudo nginx -s stop          # Linux / macOS / WSL2
nginx -s stop               # Windows (Admin Command Prompt)
```

Then **comment out** the ngrok URLs in your `.env` files and restart your servers normally.

---

## Troubleshooting

| Problem                                          | Fix                                                                                       |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| `nginx: open() failed`                           | Use the full absolute path to `nginx.conf`                                                |
| `Address already in use` on port 6969            | Something else is using 6969 — change the port in `nginx.conf` and in `ngrok http <port>` |
| `curl localhost:6969` returns nothing            | Your backend or frontend isn't running yet                                                |
| `ERR_NGROK_3200`                                 | nginx isn't running or nothing is listening on port 6969                                  |
| Teammate sees a browser warning on the ngrok URL | They need to click "Visit Site" — it's just ngrok's free tier interstitial                |
| API calls fail with CORS errors                  | Add the ngrok domain to your backend's CORS allowed origins                               |
| Windows: nginx closes immediately                | Check `C:\nginx\logs\error.log` for the error                                             |

---

## References

- [nginx docs](https://nginx.org/en/docs/) · [nginx on Windows](https://nginx.org/en/docs/windows.html)
- [ngrok docs](https://ngrok.com/docs/getting-started/) · [ngrok free vs paid](https://ngrok.com/pricing)
- [How to add to PATH on Windows](https://www.architectryan.com/2018/03/17/add-to-the-path-on-windows-10/)
