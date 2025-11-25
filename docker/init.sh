#!/bin/bash
set -e

BENCH_DIR="/home/frappe/frappe-bench"
SITE="lms.hackforceone.nl"
MYSQL_ROOT_PASSWORD=123
DB_NAME="frappe"
DB_USER="frappe"
DB_PASSWORD="frappe123"
ADMIN_PASSWORD="admin"

# --------------------------
# Als bench al bestaat: alleen starten
# --------------------------
if [ -d "$BENCH_DIR" ]; then
    echo "Bench already exists, starting in production mode..."
    cd $BENCH_DIR
    bench use $SITE
    bench start
    exit 0
fi

echo "Creating new bench..."
bench init --skip-redis-config-generation frappe-bench
cd $BENCH_DIR

# --------------------------
# Database & Redis hosts instellen
# --------------------------
bench set-mariadb-host mariadb
bench set-config db_name $DB_NAME
bench set-config db_password $DB_PASSWORD

bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Watcher niet nodig in container
sed -i '/watch/d' Procfile

# --------------------------
# LMS app ophalen
# (nu pakt hij de standaard lms repo; wil je je fork, vervang dit)
# --------------------------
bench get-app lms

# --------------------------
# Site aanmaken
# --------------------------
bench new-site $SITE \
    --mariadb-root-password $MYSQL_ROOT_PASSWORD \
    --admin-password $ADMIN_PASSWORD \
    --no-mariadb-socket

# --------------------------
# LMS installeren op site
# --------------------------
bench --site $SITE install-app lms

# --------------------------
# Production settings
# --------------------------
bench --site $SITE set-config developer_mode 0
bench --site $SITE enable-scheduler
bench --site $SITE clear-cache

# --------------------------
# Domain koppelen in Frappe
# --------------------------
bench setup add-domain $SITE $SITE
bench setup nginx

bench use $SITE
echo "Starting bench (web + workers + scheduler + socketio)..."
bench start
