# ─────────────────────────────────────────────
# EDIT THIS: full path to your nginx.conf
$NginxConf = "/home/yacine/turbodocx/nginx/nginx.conf"

# EDIT THIS: the port nginx listens on (must match nginx.conf)
$NgrokPort = 6969

# EDIT THESE: full paths to your frontend and backend .env files
$FrontendEnv = "C:\Users\YourName\myproject\frontend\.env.development"
$BackendEnv  = "C:\Users\YourName\myproject\backend\.env"
# ─────────────────────────────────────────────
# Lines tagged with # [ngrok] in your .env files will be auto-toggled.
# Make sure each ngrok line ends with: # [ngrok]

function Comment-Ngrok($file) {
    (Get-Content $file) -replace '^([^#].*# \[ngrok\])', '#$1' | Set-Content $file
}

function Uncomment-Ngrok($file) {
    (Get-Content $file) -replace '^#(.*# \[ngrok\])', '$1' | Set-Content $file
}

try {
    Write-Host "Uncommenting ngrok vars..."
    Uncomment-Ngrok $FrontendEnv
    Uncomment-Ngrok $BackendEnv

    Write-Host "Starting nginx..."
    $nginx = Start-Process nginx -ArgumentList "-c `"$NginxConf`"" -PassThru -NoNewWindow
    if ($nginx.HasExited) {
        Write-Host "nginx failed to start. Check the path to your nginx.conf."
        exit 1
    }

    Write-Host ""
    Write-Host "nginx is running on port $NgrokPort"
    Write-Host "Starting ngrok... copy the Forwarding URL, update it in your .env files, then restart your servers."
    Write-Host "Press Ctrl+C to stop everything and restore your .env files."
    Write-Host ""

    ngrok http $NgrokPort
}
finally {
    Write-Host ""
    Write-Host "Stopping nginx..."
    nginx -s stop 2>$null

    Write-Host "Commenting out ngrok vars..."
    Comment-Ngrok $FrontendEnv
    Comment-Ngrok $BackendEnv

    Write-Host "Done. Restart your servers to go back to localhost."
}