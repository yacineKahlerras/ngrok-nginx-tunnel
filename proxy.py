import subprocess

NGINX_CONF_PATH="/home/yacine/turbodocx/nginx/nginx.conf"

def start_nginx(args):
    print('$ starting nginx...')
    print(f'$ {" ".join(args)}')

    res = subprocess.run(args, capture_output=True, text=True)
    if res.stderr:
        print(f'$ nginx error: {res.stderr}')
    else:        
        print(f'$ nginx output: {res.stdout}')
    
    return res

def start_ngrok(port):
    print('$ starting ngrok...')
    print(f'$ {" ".join(["ngrok", "http", str(port)])}')

    p = subprocess.Popen(["ngrok", "http", str(port)], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    try:
        for line in p.stdout:
            print(line, end='')  # Print ngrok output in real-time
    except KeyboardInterrupt:
        pass
    finally:
        p.terminate()  # Terminate ngrok process on exit
        p.wait()

def main():
    # Start nginx
    nginxResult  = start_nginx(["nginx", "-t", "-c", NGINX_CONF_PATH, "-T"])
    if nginxResult.returncode != 0:
        print('$ nginx configuration test failed. Exiting.')
        return

    # 2) start nginx in foreground with debug logs
    # run nginx in background process (foreground mode) so we can continue
    nginx_proc = subprocess.Popen(
        ["nginx", "-g", "error_log /dev/stderr debug; daemon off;", "-c", str(NGINX_CONF_PATH)],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    # 3) start ngrok and stream its output (this blocks until ngrok exits)
    try:
        start_ngrok(6969)
    except FileNotFoundError:
        print("ngrok not found in PATH. Install or add it to PATH.", file=sys.stderr)
    finally:
        nginx_proc.terminate()
        nginx_proc.wait()

main()
