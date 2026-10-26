#!/usr/bin/with-contenv bash
# shellcheck source=/dev/null

source /usr/lib/bashio/bashio.sh
set -euo pipefail

if [ ! -d /etc/cups ]; then
    bashio::log.warning "Skipping CUPS state snapshot because /etc/cups is unavailable"
    exit 0
fi

snapshot_dir=$(mktemp -d /data/cups-backup.tmp.XXXXXX)
cp -a /etc/cups/. "$snapshot_dir"/
rm -rf /data/cups-backup
mv "$snapshot_dir" /data/cups-backup
