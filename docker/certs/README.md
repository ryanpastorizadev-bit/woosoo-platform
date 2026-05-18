# TLS Certificates

Place your certificate files in this directory:

| File | Purpose |
|------|---------|
| `fullchain.pem` | Certificate chain (leaf + any intermediates) |
| `privkey.pem` | Private key — **never commit this file** |

Both files are bind-mounted **read-only** into the `nginx` container at `/etc/nginx/certs/`.
No other container receives the private key.

---

## Development — self-signed certificate

Requires `openssl`.

```sh
chmod +x generate-dev-certs.sh
./generate-dev-certs.sh 192.168.100.10   # replace with your actual Pi IP
```

This generates a cert valid for the IP, `woosoo.local`, `admin.woosoo.local`, `app.woosoo.local`, and `localhost`.

### Trusting the cert on each device

| Platform | Steps |
|----------|-------|
| **Chrome / Edge (Windows)** | Settings → Privacy → Security → Manage certificates → Authorities → Import `fullchain.pem` |
| **Firefox** | Settings → Privacy → View Certificates → Authorities → Import `fullchain.pem` |
| **macOS** | `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain fullchain.pem` |
| **Android** | AirDrop / copy the file → Settings → Security → Install from storage |
| **iOS** | AirDrop `fullchain.pem` → Settings → General → VPN & Device Management → trust the profile |

---

## Production — real certificate

**Option A — copy from Let's Encrypt:**
```sh
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ./fullchain.pem
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem   ./privkey.pem
```

**Option B — mount Certbot's live directory directly in `compose.yaml`:**
```yaml
nginx:
  volumes:
    - /etc/letsencrypt/live/yourdomain.com:/etc/nginx/certs:ro
```

> Make sure to restart the `nginx` container after renewing certificates.

---

**`.gitignore` reminder:** Add `privkey.pem` and `fullchain.pem` to `.gitignore` if not already present.
