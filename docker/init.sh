#!/bin/bash

set -e

BENCH_DIR="/home/frappe/frappe-bench"
SITE="lms.hackforceone.nl"
MYSQL_PASSWORD=123
ADMIN_PASSWORD=admin

# --------------------------
# Check of bench al bestaat
# --------------------------
if [ -d "$BENCH_DIR" ]; then
    echo "Bench already exists, starting bench..."
    cd $BENCH_DIR
    bench start
    exit 0
fi

echo "Creating new bench..."
bench init --skip-redis-config-generation frappe-bench
cd $BENCH_DIR

# --------------------------
# Correcte Redis hosts
# --------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# --------------------------
# Frappe-lms app installeren
# --------------------------
bench get-app lms /workspace

# --------------------------
# Nieuwe site maken
# --------------------------
bench new-site $SITE \
    --mariadb-root-password $MYSQL_PASSWORD \
    --admin-password $ADMIN_PASSWORD \
    --no-mariadb-socket

# --------------------------
# LMS installeren
# --------------------------
bench --site $SITE install-app lms

# --------------------------
# Fix Developer mode
# --------------------------
bench --site $SITE set-config developer_mode 1
bench --site $SITE clear-cache

# --------------------------
# Domain koppelen
# --------------------------
bench setup add-domain $SITE $SITE
bench setup nginx

# --------------------------
# Worker processen goedzetten
# (Procfile van socketio + web intact laten!)
# --------------------------
# Watcher niet nodig
sed -i '/watch/d' Procfile

# --------------------------
# Services starten
# --------------------------
bench use $SITE
bench start
