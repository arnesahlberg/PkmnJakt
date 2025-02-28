# Deployment on Raspberry Pi

## Clone the Repository
Clone the repository using:
```sh
git clone repo/url.git
```

## Install Required Dependencies
Ensure that Nginx and SQLite3 are installed:
```sh
sudo apt install nginx libsqlite3-dev
```

### Install Certbot
Install Certbot to manage SSL certificates:
```sh
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

## API Setup

### Build the API
Ensure the API is built with Cargo:
```sh
cd PkmnJakt/pkmn_api
cargo build --release
```

### Obtain an SSL Certificate
Run the following command to obtain an SSL certificate for your API domain:
```sh
sudo certbot --nginx -d api.yourdomain.com
```

#### Verify that we can renew certificates with a dry-run (optional)
```sh
sudo certbot renew --dry-run
```

### Configure Nginx
Remove the default Nginx configuration:
```sh
sudo vim /etc/nginx/sites-available/default
```

Create a new configuration file under `/etc/nginx/sites-available/api.yourdomain.com`:
```nginx
server {
    listen 443 ssl;
    server_name api.yourdomain.com;

    ssl_certificate     /etc/nginx/ssl/api.yourdomain.com.crt;
    ssl_certificate_key /etc/nginx/ssl/api.yourdomain.com.key;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Enable the Configuration
Create a symbolic link to enable the configuration:
```sh
sudo ln -s /etc/nginx/sites-available/api.yourdomain.com /etc/nginx/sites-enabled/
```

### Validate and Reload Nginx
Check the configuration for errors:
```sh
sudo nginx -t
```
Reload Nginx to apply the changes:
```sh
sudo systemctl reload nginx
```

### Check Nginx Logs
To debug issues, check the logs:
```sh
sudo journalctl -u nginx --no-pager --lines=50
```

## Create a Systemd Service
Create a systemd service file for the API:
```sh
sudo vim /etc/systemd/system/pkmnapi.service
```

Use the following template:
```ini
[Unit]
Description="Pkmn API for web app"
After=network.target

[Service]
ExecStart=/path/to/PkmnJakt/pkmn_api/target/release/pkmn_api
WorkingDirectory=/path/to/PkmnJakt/pkmn_api
Restart=always
User=arnesahlberg
Group=arnesahlberg
Environment="DATABASE_PATH=/path/to/PkmnJakt/Database/base.db"
Environment="PORT=5401"
Environment="EXPOSE_IP='127.0.0.1'"

[Install]
WantedBy=multi-user.target
```

### Apply and Enable the Service
Reload systemd to apply the new service:
```sh
sudo systemctl daemon-reload
```
Enable the service to start on boot:
```sh
sudo systemctl enable pkmnapi.service
```

### Manage the Service
Useful systemd commands:
```sh
sudo systemctl start pkmnapi.service   # Start the service
sudo systemctl status pkmnapi.service  # Check service status
sudo systemctl stop pkmnapi.service    # Stop the service
sudo systemctl restart pkmnapi.service # Restart the service
sudo systemctl disable pkmnapi.service # Disable auto-start on boot
```

### View Service Logs
To check the logs for debugging:
```sh
sudo journalctl -u pkmnapi.service --no-pager --lines=50
```

## Web app setup

### Fetch certificate

```sh
sudo certbot --nginx -d yourdomain.com
```

#### Verify that we can renew certificates with a dry-run (optional)
```sh
sudo certbot renew --dry-run
```

### Configure Nginx

Create a new configuration file under `/etc/nginx/sites-available/yourdomain.com`:
```nginx
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    root /path/to/pkmn_jakt_website;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Enable the Configuration
Create a symbolic link to enable the configuration:
```sh
sudo ln -s /etc/nginx/sites-available/yourdomain.com /etc/nginx/sites-enabled/
```

### Validate and Reload Nginx
Check the configuration for errors:
```sh
sudo nginx -t
```

Reload Nginx to apply the changes:
```sh
sudo systemctl reload nginx
```

### Check Nginx Logs
To debug issues, check the logs:
```sh
sudo journalctl -u nginx --no-pager --lines=50
```