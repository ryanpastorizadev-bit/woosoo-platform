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

openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out    "$CERT_DIR/fullchain.pem" \
    -days   "$DAYS" \
    -subj   "/C=PH/ST=Local/L=Local/O=Woosoo/CN=$IP" \
    -addext "subjectAltName=IP:$IP,DNS:woosoo.local,DNS:admin.woosoo.local,DNS:app.woosoo.local,DNS:localhost"

echo ""
echo "Done."
echo "  Certificate : $CERT_DIR/fullchain.pem"
echo "  Private Key : $CERT_DIR/privkey.pem"
echo ""
echo "To trust this cert (suppress browser warnings), import fullchain.pem"
echo "as a trusted CA authority on each device that will access the app."
echo "See docker/certs/README.md for device-specific instructions."
