#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="/etc/woosoo/woosoo.env"

if [[ $EUID -ne 0 ]]; then
  echo "Run as root: sudo bash scripts/deployment/woosoo-backup.sh"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Missing $CONFIG_FILE"
  exit 1
fi

set -a
# shellcheck source=/dev/null
source "$CONFIG_FILE"
set +a

WOOSOO_DOCKER_COMPOSE="${WOOSOO_DOCKER_COMPOSE:-docker compose -f compose.yaml}"
WOOSOO_NEXUS_PATH="${WOOSOO_NEXUS_PATH:-/opt/woosoo/woosoo-nexus}"
WOOSOO_BACKUP_DIR="${WOOSOO_BACKUP_DIR:-/opt/woosoo/backups}"
WOOSOO_BACKUP_RETENTION_DAYS="${WOOSOO_BACKUP_RETENTION_DAYS:-14}"
MYSQL_SERVICE="${WOOSOO_MYSQL_SERVICE:-mysql}"
DB_NAME="${WOOSOO_DB_DATABASE:-woosoo}"
DB_USER="${WOOSOO_DB_USERNAME:-woosoo}"
DB_PASS="${WOOSOO_DB_PASSWORD:-change_this_password}"
LOCK_DIR="/run/lock/woosoo"
LOCK_FILE="$LOCK_DIR/woosoo-backup.lock"

read -r -a DOCKER_COMPOSE_CMD <<< "$WOOSOO_DOCKER_COMPOSE"

docker_compose() {
  "${DOCKER_COMPOSE_CMD[@]}" "$@"
}

if [[ -L "$LOCK_DIR" ]]; then
  echo "ERROR: unsafe lock directory: $LOCK_DIR"
  exit 1
fi
if ! install -d -o root -g root -m 0755 "$LOCK_DIR"; then
  echo "ERROR: unable to create secure lock directory: $LOCK_DIR"
  exit 1
fi
if [[ -L "$LOCK_DIR" || ! -d "$LOCK_DIR" ]]; then
  echo "ERROR: unsafe lock directory: $LOCK_DIR"
  exit 1
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "ERROR: another Woosoo backup is already running"
  exit 1
fi

mkdir -p "$WOOSOO_BACKUP_DIR/db"

if [[ ! -d "$WOOSOO_NEXUS_PATH" ]]; then
  echo "Nexus path missing: $WOOSOO_NEXUS_PATH"
  exit 1
fi

cd "$WOOSOO_NEXUS_PATH"

BACKUP_FILE="$WOOSOO_BACKUP_DIR/db/${DB_NAME}_$(date +%F_%H%M%S).sql.gz"
TEMP_SQL_FILE="${BACKUP_FILE%.gz}.tmp"
TEMP_GZ_FILE="$BACKUP_FILE.tmp"

cleanup() {
  rm -f "$TEMP_SQL_FILE" "$TEMP_GZ_FILE"
}
trap cleanup EXIT

echo "Creating DB backup: $BACKUP_FILE"

if docker_compose exec -T "$MYSQL_SERVICE" sh -c 'command -v mariadb-dump >/dev/null 2>&1'; then
  DUMP_CMD="mariadb-dump"
else
  DUMP_CMD="mysqldump"
fi

if ! docker_compose exec -T \
  -e MYSQL_PWD="$DB_PASS" \
  "$MYSQL_SERVICE" \
  "$DUMP_CMD" -u"$DB_USER" "$DB_NAME" > "$TEMP_SQL_FILE"; then
  echo "ERROR: database dump failed; no backup written"
  exit 1
fi

if [[ ! -s "$TEMP_SQL_FILE" ]]; then
  echo "ERROR: database dump produced an empty file; no backup written"
  exit 1
fi

gzip -c "$TEMP_SQL_FILE" > "$TEMP_GZ_FILE"
mv "$TEMP_GZ_FILE" "$BACKUP_FILE"
rm -f "$TEMP_SQL_FILE"

echo "Backup complete: $BACKUP_FILE"

echo "Deleting backups older than ${WOOSOO_BACKUP_RETENTION_DAYS} days..."
find "$WOOSOO_BACKUP_DIR/db" -name "*.sql.gz" -type f -mtime +"$WOOSOO_BACKUP_RETENTION_DAYS" -delete

echo "Remaining backups:"
find "$WOOSOO_BACKUP_DIR/db" -maxdepth 1 -type f -name "*.sql.gz" -printf '%TY-%Tm-%Td %TH:%TM %s bytes %p\n' | sort || true
