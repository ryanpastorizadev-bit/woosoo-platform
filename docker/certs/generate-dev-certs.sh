#!/bin/sh
# Generates a self-signed TLS certificate for local / development use.
# Requires: openssl
#
# Usage:   ./generate-dev-certs.sh [SERVER_IP]
# Example: ./generate-dev-certs.sh 192.168.100.10

set -e

CERT_DIR="$(cd "$(dirname "$0")" && pwd)"
DAYS=825   # maximum Chrome will accept for a self-signed cert
IP="${1:?Usage: $0 SERVER_IP  (e.g. 192.168.100.10)}"

echo "Generating self-signed certificate ..."
echo "  IP  : $IP"
echo "  Days: $DAYS"
echo ""

# Write to .tmp files first; live files are only touched after keypair verification.
openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$CERT_DIR/privkey.pem.tmp" \
    -out    "$CERT_DIR/fullchain.pem.tmp" \
    -days   "$DAYS" \
    -subj   "/C=PH/ST=Local/L=Local/O=Woosoo/CN=$IP" \
    -addext "subjectAltName=IP:$IP,DNS:woosoo.local,DNS:admin.woosoo.local,DNS:app.woosoo.local,DNS:localhost"

# Verify the keypair before touching any live file.
_pub_from_key="$(openssl pkey -in "$CERT_DIR/privkey.pem.tmp" -pubout 2>/dev/null)"
_pub_from_cert="$(openssl x509 -in "$CERT_DIR/fullchain.pem.tmp" -noout -pubkey 2>/dev/null)"
if [ -z "$_pub_from_key" ] || [ -z "$_pub_from_cert" ] || [ "$_pub_from_key" != "$_pub_from_cert" ]; then
    printf 'ERROR: keypair verification failed — privkey.pem and fullchain.pem do not match.\n' >&2
    rm -f "$CERT_DIR/privkey.pem.tmp" "$CERT_DIR/fullchain.pem.tmp"
    exit 1
fi

# Back up live certs (best-effort) then atomically promote the .tmp files.
cp -f "$CERT_DIR/privkey.pem"   "$CERT_DIR/privkey.pem.bak"   2>/dev/null || true
cp -f "$CERT_DIR/fullchain.pem" "$CERT_DIR/fullchain.pem.bak" 2>/dev/null || true
cp -f "$CERT_DIR/rootCA.crt"    "$CERT_DIR/rootCA.crt.bak"    2>/dev/null || true
mv -f "$CERT_DIR/privkey.pem.tmp"   "$CERT_DIR/privkey.pem"
mv -f "$CERT_DIR/fullchain.pem.tmp" "$CERT_DIR/fullchain.pem"

# For a self-signed cert the server cert IS the CA root.
# Nginx serves rootCA.crt over HTTP so devices can bootstrap trust before
# they have a valid HTTPS connection (see docker/nginx/default.conf).
cp -f "$CERT_DIR/fullchain.pem" "$CERT_DIR/rootCA.crt"

echo ""
echo "Done."
echo "  Certificate : $CERT_DIR/fullchain.pem"
echo "  Private Key : $CERT_DIR/privkey.pem"
echo "  CA root     : $CERT_DIR/rootCA.crt  (copy of fullchain.pem for device trust)"
echo ""
echo "To trust this cert (suppress browser warnings), install rootCA.crt"
echo "as a trusted CA authority on each device that will access the app."
echo "See docker/certs/README.md for device-specific instructions."
