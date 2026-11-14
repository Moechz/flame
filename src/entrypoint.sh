#!/bin/sh
# ===========================================================================
# Flame entrypoint for a non-root container (TOS 7 requirement).
#
# The image rewrites its theme CSS inside /app/public at startup, which fails
# for uid 1000 ("EACCES: permission denied, open '/app/public/flame.css'").
# This wrapper runs the server from a writable copy in /tmp and keeps the
# persistent data directory on the mounted volume.
# ===========================================================================
set -e
set -u

APP=/tmp/flame

rm -rf "$APP"
mkdir -p "$APP"
cp -a /app/. "$APP"/

# data lives on the mounted volume (/app/data); point the copy at it
rm -rf "$APP/data"
ln -s /app/data "$APP/data"
mkdir -p /app/data 2>/dev/null || true

cd "$APP"
exec node server.js
