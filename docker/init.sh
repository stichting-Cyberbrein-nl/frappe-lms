#!/bin/bash
set -e

BENCH_DIR="/home/frappe/frappe-bench"
SITE="lms.hackforceone.nl"
MYSQL_ROOT_PASSWORD=123
DB_NAME="frappe"
DB_USER="frappe"
DB_PASSWORD="frappe123"
ADMIN_PASSWORD="admin"

# ------------------------------------------
# Als bench al bestaat → alleen starten
# ------------------------------------------
if [ -d "$BENCH_DIR" ]; then
    echo "Bench already exists — starting in production mode..."
    cd $BENCH_DIR
    bench use $SITE
    bench start
    exit 0
fi

# ------------------------------------------
# Nieuwe bench maken
# ------------------------------------------
echo "Creating new bench..."
bench init --skip-redis-config-generation frappe-bench
cd $BENCH_DIR

# ------------------------------------------
# Redis en MariaDB hosts instellen
# (Deze werken zonder --site)
# ------------------------------------------
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Watch tasks uit Procfile halen
sed -i '/watch/d' Procfile

# ------------------------------------------
# LMS app binnenhalen
# ------------------------------------------
bench get-app lms

# ------------------------------------------
# Nieuwe site aanmaken
# ------------------------------------------
bench new-site $SITE \
    --mariadb-root-password $MYSQL_ROOT_PASSWORD \
    --admin-password $ADMIN_PASSWORD \
    --no-mariadb-socket

# ------------------------------------------
# ✨ SITE-bestemming bestaat nu pas
# Nu mag je set-config gebruiken!
# ------------------------------------------
bench --site $SITE set-config db_name $DB_NAME
bench --site $SITE set-config db_password $DB_PASSWORD

# LMS installeren
bench --site $SITE install-app lms

# Production settings
bench --site $SITE set-config developer_mode 0
bench --site $SITE enable-scheduler
bench --site $SITE clear-cache

# Domain koppelen
bench setup add-domain $SITE $SITE
bench setup nginx

bench use $SITE

echo "Production-ready bench starting..."
bench start
