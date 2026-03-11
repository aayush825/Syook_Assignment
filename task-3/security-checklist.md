# Security Checklist

This document covers the security measures implemented and recommended for the production deployment.

---

## 1. SSH Hardening

### Disable Root Login

Edit `/etc/ssh/sshd_config`:

```
PermitRootLogin no
```

### Use Key-Based Authentication Only

```
PasswordAuthentication no
PubkeyAuthentication yes
```

### Change Default SSH Port (optional but recommended)

```
Port 2222
```

### Apply changes

```bash
sudo systemctl restart sshd
```

---

## 2. Firewall Configuration

Using UFW (Uncomplicated Firewall):

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw limit 22/tcp       # SSH with rate limiting
sudo ufw allow 80/tcp       # HTTP
sudo ufw allow 443/tcp      # HTTPS
sudo ufw enable
```

Database ports (3306, 27017) are not exposed externally. They're only accessible within the Docker bridge network.

See `firewall.sh` for the full script.

---

## 3. SSL/TLS Configuration

### Generate Self-Signed Certificate (for testing/staging)

```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/server.key \
  -out /etc/ssl/certs/server.crt \
  -subj "/CN=$(hostname)"
```

### For Production

Use Let's Encrypt with Certbot:

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com
```

Certbot automatically sets up auto-renewal via a systemd timer.

### SSL Best Practices (implemented in nginx-secure.conf)

- TLS 1.2 and 1.3 only (no SSLv3, TLS 1.0, TLS 1.1)
- Strong cipher suites
- HTTP → HTTPS redirect
- HSTS header enabled

---

## 4. Security Headers

The following headers are set in the Nginx config:

| Header                    | Value                           | Purpose                   |
| ------------------------- | ------------------------------- | ------------------------- |
| Strict-Transport-Security | max-age=31536000                | Force HTTPS for 1 year    |
| X-Frame-Options           | SAMEORIGIN                      | Prevent clickjacking      |
| X-Content-Type-Options    | nosniff                         | Prevent MIME sniffing     |
| X-XSS-Protection          | 1; mode=block                   | XSS filter                |
| Content-Security-Policy   | default-src 'self'              | Restrict resource loading |
| Referrer-Policy           | strict-origin-when-cross-origin | Control referrer info     |

---

## 5. Rate Limiting

Configured in Nginx to prevent DDoS and brute force:

- **Global**: 10 requests/second per IP (burst of 20)
- **API endpoints**: 5 requests/second per IP (burst of 10)

```nginx
limit_req_zone $binary_remote_addr zone=global_limit:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=5r/s;
```

---

## 6. Log Rotation

Use logrotate to prevent disk space issues:

```bash
sudo tee /etc/logrotate.d/docker-apps <<EOF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 $(cat /var/run/nginx.pid)
    endscript
}
EOF
```

Docker logs rotation (add to `/etc/docker/daemon.json`):

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Then restart Docker:

```bash
sudo systemctl restart docker
```

---

## 7. Automatic Security Updates

Install and enable unattended-upgrades:

```bash
sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure -plow unattended-upgrades
```

Verify it's enabled:

```bash
cat /etc/apt/apt.conf.d/20auto-upgrades
```

Expected output:

```
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

---

## 8. Docker Security

- Run containers as non-root users where possible
- Use `restart: unless-stopped` policy
- Don't expose unnecessary ports to the host
- Use specific image tags instead of `latest` in production
- Scan images for vulnerabilities:
  ```bash
  docker scout quickview <image>
  ```

---

## 9. Database Security

### MongoDB

- In production, enable authentication:
  ```yaml
  environment:
    MONGO_INITDB_ROOT_USERNAME: admin
    MONGO_INITDB_ROOT_PASSWORD: <strong-password>
  ```
- Don't expose port 27017 to the internet

### MySQL

- Use strong root password
- Create application-specific database users
- Don't expose port 3306 to the internet

---

## 10. Monitoring and Alerting

Recommended tools:

- **Prometheus + Grafana** for metrics
- **Docker health checks** for container monitoring
- **fail2ban** to ban IPs with too many failed SSH attempts:
  ```bash
  sudo apt install fail2ban -y
  sudo systemctl enable fail2ban
  ```

---

## Summary Checklist

| #   | Measure                     | Status     |
| --- | --------------------------- | ---------- |
| 1   | SSH root login disabled     | Configured |
| 2   | SSH key authentication only | Configured |
| 3   | UFW firewall enabled        | Configured |
| 4   | SSL/TLS enabled             | Configured |
| 5   | Security headers set        | Configured |
| 6   | Rate limiting enabled       | Configured |
| 7   | Log rotation configured     | Configured |
| 8   | Auto security updates       | Configured |
| 9   | Database ports not exposed  | Configured |
| 10  | Docker log limits set       | Configured |
