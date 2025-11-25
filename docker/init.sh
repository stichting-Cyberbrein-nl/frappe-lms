#!/bin/bash

set -e

BENCH_DIR="/home/frappe/frappe-bench"
SITE="lms.hackforceone.nl"
MYSQL_PASSWORD=123
ADMIN_PASSWORD=admin
LMS_REPO="https://github.com/stichting-Cyberbrein-nl/frappe-lms.git"

echo "Starting LMS init script..."

# ---------------------------------------------------
# 1. ALS BENCH BESTAAT → DIRECT STARTEN
# ---------------------------------------------------
if [ -d "$BENCH_DIR" ]; then
    echo "Bench already exists → Starting bench..."
    cd $BENCH_DIR
    bench start
    exit 0
fi

# ---------------------------------------------------
# 2. NIEUWE BENCH MAKEN
# ---------------------------------------------------
echo "Creating new Frappe Bench..."
bench init --skip-redis-config-generation frappe-bench

cd $BENCH_DIR

# ---------------------------------------------------
# 3. DATABASE & REDIS CORRECT INSTELLEN
#
# Je Compose gebruikt:
# - mariadb
# - redis-cache
# - redis-queue
# - redis-socketio
# ---------------------------------------------------
echo "Configuring DB + Redis hosts..."

bench set-mariadb-host mariadb

bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# ---------------------------------------------------
# 4. WATCHER VERWIJDEREN (NIET NODIG IN DOCKER)
# ---------------------------------------------------
sed -i '/watch/d' Procfile || true

# ---------------------------------------------------
# 5. LMS INSTALLEREN VANUIT JOUW FORK
# ---------------------------------------------------
echo "Downloading LMS app from GitHub..."
bench get-app lms $LMS_REPO

# ---------------------------------------------------
# 6. NIEUWE SITE MAKEN
# ---------------------------------------------------
echo "Creating new site $SITE..."

bench new-site $SITE \
    --mariadb-root-password $MYSQL_PASSWORD \
    --admin-password $ADMIN_PASSWORD \
    --no-mariadb-socket \
    --force

# ---------------------------------------------------
# 7. LMS INSTALLEREN OP DE SITE
# ---------------------------------------------------
echo "Installing LMS..."
bench --site $SITE install-app lms

# ---------------------------------------------------
# 8. DEVELOPER MODE AAN (HANDIG VOOR DEBUG)
# ---------------------------------------------------
bench --site $SITE set-config developer_mode 1

# ---------------------------------------------------
# 9. SOCKETIO FIX → GEEN 11000 MEER
#    We laten socketio op 9000 draaien
# ---------------------------------------------------
echo "Fixing realtime config (SocketIO)..."

bench --site $SITE set-config socketio_port 9000
bench --site $SITE set-config eventlet_port ""

# ---------------------------------------------------
# 10. CACHE OPSCHONEN
# ---------------------------------------------------
bench --site $SITE clear-cache
bench --site $SITE clear-website-cache

# ---------------------------------------------------
# 11. DOMEIN TOEVOEGEN
# ---------------------------------------------------
echo "Adding domain to site..."
bench setup add-domain $SITE $SITE

# ---------------------------------------------------
# 12. NGINX GENEREREN
# ---------------------------------------------------
echo "Generating Nginx config..."
bench setup nginx

# ---------------------------------------------------
# 13. BENCH STARTEN
# ---------------------------------------------------
bench use $SITE

echo "Starting bench..."
bench start
