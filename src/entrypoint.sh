#!/bin/sh
# ===========================================================================
# Flame entrypoint for TerraMaster TOS 7 (non-root container).
#
# Two jobs:
#
# 1. Writability. The image rewrites its theme CSS inside /app/public at
#    startup, which fails for uid 1000 ("EACCES: permission denied, open
#    '/app/public/flame.css'"). The wrapper therefore runs the server from a
#    writable copy in /tmp and keeps the persistent data directory on the
#    mounted volume.
#
# 2. Credentials. The upstream image bakes a default administrator password
#    into its environment (PASSWORD=flame_password) and the login controller
#    compares the submitted password with that variable. Anyone on the LAN who
#    knows the default could edit the start page and point links at hostile
#    sites. This wrapper generates a random password on the first start, keeps
#    it in the data folder (uid 1000, mode 600) and exports it again on every
#    later start, so the image default is never the effective credential.
# ===========================================================================
set -e
set -u

APP=/tmp/flame
DATA=/app/data
CRED=$DATA/admin-credentials.txt

mkdir -p "$DATA" 2>/dev/null || true

# --- administrator password: generated once, reused afterwards -------------
if [ ! -s "$CRED" ]; then
    umask 077
    NEW_PASSWORD=$(head -c 64 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)
    {
        printf 'Flame web interface - administrator login\n'
        printf 'url:      http://<NAS-IP>:8027/\n'
        printf 'password: %s\n' "$NEW_PASSWORD"
        printf '\nDelete this file and restart the application to generate a new password.\n'
    } > "$CRED" 2>/dev/null || true
    chmod 600 "$CRED" 2>/dev/null || true
fi

PASSWORD=$(awk -F': ' '$1 == "password" {print $2; exit}' "$CRED" 2>/dev/null || true)
if [ -z "${PASSWORD:-}" ]; then
    echo "flamedocker: cannot read the administrator password from $CRED" >&2
    echo "flamedocker: the data folder must be writable by uid 1000" >&2
    exit 1
fi
export PASSWORD

echo "flamedocker: administrator password is stored in $CRED"
echo "flamedocker: (/Volume1/DockerAppData/flamedocker/data/admin-credentials.txt on the NAS)."

# --- writable copy of the application --------------------------------------
rm -rf "$APP"
mkdir -p "$APP"
cp -R /app/. "$APP"/

# data lives on the mounted volume; point the copy at it
rm -rf "$APP/data"
ln -s "$DATA" "$APP/data"

cd "$APP"
exec node server.js
