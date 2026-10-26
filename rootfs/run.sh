#!/usr/bin/with-contenv bashio
set -euo pipefail
#
# BACKWARD-COMPAT ENTRYPOINT
# This script is retained for use cases where s6-overlay is not the process
# supervisor (e.g. direct Docker invocation). Under normal addon operation,
# config.yaml has 'init: false' and s6-overlay is the runtime; this file is
# not invoked.
#
# All configuration logic lives in cups-config.sh (the canonical source of
# truth). This script delegates to it to prevent drift, then handles the
# responsibilities that s6-overlay normally splits across separate services:
#   - cups-server/run: waits for Avahi socket and launches cupsd
#

# Delegate all CUPS/Avahi configuration to the canonical script
/usr/bin/with-contenv /bin/bash /usr/share/cups-config.sh

# Legacy flag retained for any tooling that may poll for it

hostname=$(bashio::info.hostname)

# Get all possible hostnames from configuration
result=$(bashio::api.supervisor GET /core/api/config true || true)
internal=$(bashio::jq "$result" '.internal_url' | cut -d'/' -f3 | cut -d':' -f1)
external=$(bashio::jq "$result" '.external_url' | cut -d'/' -f3 | cut -d':' -f1)

# Fill config file templates with runtime data
config=$(jq --arg internal "$internal" --arg external "$external" --arg hostname "$hostname" \
    '{internal: $internal, external: $external, hostname: $hostname}' \
    /data/options.json)

echo "$config" | tempio \
    -template /usr/share/cupsd.conf.tempio \
    -out /etc/cups/cupsd.conf

echo "$config" | tempio \
    -template /usr/share/avahi-daemon.conf.tempio \
    -out /etc/avahi/avahi-daemon.conf
    
# Start Avahi, wait for it to start up
touch /var/run/avahi_configured

# Wait for Avahi daemon socket (cups-server/run does this in s6 path)
WAIT_MAX_RETRIES=30
WAIT_INTERVAL=1
retries=0
until [ -e /var/run/avahi-daemon/socket ]; do
  if [ "$retries" -ge "$WAIT_MAX_RETRIES" ]; then
    bashio::log.error "Timed out waiting for Avahi socket (/var/run/avahi-daemon/socket); aborting."
    exit 1
  fi
  retries=$((retries + 1))
  sleep "${WAIT_INTERVAL}s"
done

bashio::log.info "Starting CUPS server..."
cupsd -f
