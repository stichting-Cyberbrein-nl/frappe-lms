#!/bin/bash

set -e

BENCH_DIR="/home/frappe/frappe-bench"
SITE="lms.hackforceone.nl"
MYSQL_PASSWORD=123
ADMIN_PASSWORD=admin
LMS_REPO="/workspace"   # lokale app, geen GitHub

echo "Starting LMS init script..."

# ---------------------------------------------------
# Check: bestaat een complete bench?
# ---------------------------------------------------
if [ -f "$BENCH_DIR/Procfile" ] && [ -d "$BENCH_DIR/sites" ]; then
    echo "Bench already exists → starting bench..."
    cd $BENCH_DIR
    bench start
    exit 0
fi

echo "Bench missing → creating new bench..."
rm -rf "$BENCH_DIR" || true

bench init --skip-redis-config-generation frappe-bench
cd $BENCH_DIR

# ---------------------------------------------------
# Correcte Redis protocollen
# ---------------------------------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis-cache:6379
bench set-redis-queue-host redis://redis-queue:6379
bench set-redis-socketio-host redis://redis-socketio:6379

# ---------------------------------------------------
# LMS installeren
# ---------------------------------------------------
bench get-app lms $LMS_REPO

# ---------------------------------------------------
# Site aanmaken
# ---------------------------------------------------
bench new-site $SITE \
  --mariadb-root-password $MYSQL_PASSWORD \
  --admin-password $ADMIN_PASSWORD \
  --no-mariadb-socket \
  --force

bench --site $SITE install-app lms
bench --site $SITE set-config developer_mode 1
bench --site $SITE clear-cache

bench setup nginx
bench use $SITE

echo "Starting bench..."
bench start
