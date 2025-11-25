#!/bin/bash

set -e

BENCH_DIR="/home/frappe/frappe-bench"
SITE="lms.hackforceone.nl"
MYSQL_PASSWORD=123
ADMIN_PASSWORD=admin
LMS_REPO="https://github.com/cyberbrein-dokploy/lms.git"

echo "Starting LMS init script..."

# ---------------------------------------------------
# Bench bestaat → check of alles compleet is
# ---------------------------------------------------
if [ -d "$BENCH_DIR" ] && [ -f "$BENCH_DIR/Procfile" ] && [ -d "$BENCH_DIR/sites" ]; then
    echo "Bench already exists and is valid → Starting bench..."
    cd $BENCH_DIR
    bench start
    exit 0
fi

echo "Bench does not exist or is incomplete → Recreating bench..."
rm -rf "$BENCH_DIR" || true

# ---------------------------------------------------
# Nieuwe bench maken
# ---------------------------------------------------
bench init --skip-redis-config-generation frappe-bench
cd $BENCH_DIR

# ---------------------------------------------------
# DB + Redis instellen
# ---------------------------------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis-cache:6379
bench set-redis-queue-host redis://redis-queue:6379
bench set-redis-socketio-host redis://redis-socketio:6379

# Watcher verwijderen
sed -i '/watch/d' Procfile || true

# ---------------------------------------------------
# LMS installeren
# ---------------------------------------------------
bench get-app lms $LMS_REPO

# ---------------------------------------------------
# Nieuwe site maken
# ---------------------------------------------------
bench new-site $SITE \
    --mariadb-root-password $MYSQL_PASSWORD \
    --admin-password $ADMIN_PASSWORD \
    --no-mariadb-socket \
    --force

bench --site $SITE install-app lms
bench --site $SITE set-config developer_mode 1
bench --site $SITE set-config socketio_port 9000
bench --site $SITE set-config eventlet_port ""

bench --site $SITE clear-cache

bench setup add-domain $SITE $SITE
bench setup nginx

bench use $SITE

echo "Starting bench..."
bench start
