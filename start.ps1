# ─────────────────────────────────────────────
# EDIT THIS: full path to your nginx.conf
$NginxConf = "C:\Users\YourName\myproject\nginx\nginx.conf"

# EDIT THIS: the port nginx listens on (must match nginx.conf)
$NgrokPort = 6969
# ─────────────────────────────────────────────

try {
    Write-Host "Starting nginx..."
    $nginx = Start-Process nginx -ArgumentList "-c `"$NginxConf`"" -PassThru -NoNewWindow
    if ($nginx.HasExited) {
        Write-Host "nginx failed to start. Check the path to your nginx.conf."
        exit 1
    }

    Write-Host ""
    Write-Host "nginx is running on port $NgrokPort"
    Write-Host "Starting ngrok... copy the Forwarding URL and paste it into your .env files."
    Write-Host "Press Ctrl+C to stop everything."
    Write-Host ""

    ngrok http $NgrokPort
}
finally {
    Write-Host ""
    Write-Host "Stopping nginx..."
    nginx -s stop 2>$null
    Write-Host "Done."
}
