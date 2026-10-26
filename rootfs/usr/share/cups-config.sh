#!/usr/bin/with-contenv bash
# shellcheck source=/dev/null
#
# CANONICAL STARTUP SCRIPT
# This script is the single source of truth for CUPS/Avahi configuration.
# It is invoked by the cups-config s6 oneshot service (s6-rc.d/cups-config/up)
# during normal addon startup via s6-overlay.
#
# run.sh delegates to this script to avoid logic drift.
# Any startup config changes should be made here, not in run.sh.
#
source /usr/lib/bashio/bashio.sh
set -euo pipefail

bashio::log.info "Configuring CUPS and Avahi..."

restore_cups_backup_if_needed() {
    if [ ! -d /data/cups-backup ]; then
        return 0
    fi

    if [ -f /data/cups/printers.conf ] || [ -f /data/cups/classes.conf ]; then
        return 0
    fi

    bashio::log.warning "Persistent printer definitions missing; restoring CUPS state from /data/cups-backup"
    cp -a /data/cups-backup/. /data/cups/
}

snapshot_cups_state() {
    local snapshot_dir
    snapshot_dir=$(mktemp -d /data/cups-backup.tmp.XXXXXX)

    cp -a /etc/cups/. "$snapshot_dir"/
    rm -rf /data/cups-backup
    mv "$snapshot_dir" /data/cups-backup
}

hostname=$(bashio::info.hostname)

# Read user-configurable options
admin_user=$(bashio::config 'admin_user')
admin_password=$(bashio::config 'admin_password')
cups_log_level=$(bashio::config 'cups_log_level')
default_paper_size=$(bashio::config 'default_paper_size')

# Get all possible hostnames from configuration
result=$(bashio::api.supervisor GET /core/api/config true || true)
internal=$(bashio::jq "$result" '.internal_url // empty' | cut -d'/' -f3 | cut -d':' -f1 || true)
external=$(bashio::jq "$result" '.external_url // empty' | cut -d'/' -f3 | cut -d':' -f1 || true)

if [ -z "$internal" ] || [ -z "$external" ]; then
    bashio::log.warning "Could not determine internal/external URLs from HA config; ServerAlias may be incomplete"
fi

# Build template variables
config=$(jq --arg internal "$internal" --arg external "$external" --arg hostname "$hostname" \
    --arg log_level "$cups_log_level" --arg paper_size "$default_paper_size" \
    '{internal: $internal, external: $external, hostname: $hostname, log_level: $log_level, paper_size: $paper_size}' \
    /data/options.json)

# Render Avahi config before Avahi daemon starts
echo "$config" | tempio \
    -template /usr/share/avahi-daemon.conf.tempio \
    -out /etc/avahi/avahi-daemon.conf

# Set up /data/cups persistent storage on first run, then symlink /etc/cups to it
if [ ! -L /etc/cups ]; then
    if [ ! -d /data/cups ]; then
        if ! cp -R /etc/cups /data/cups; then
            bashio::log.error "Failed to initialize persistent CUPS configuration under /data/cups; aborting."
            exit 1
        fi
    fi

    rm -rf /etc/cups
    ln -s /data/cups /etc/cups
fi

restore_cups_backup_if_needed

# Render CUPS config (always refresh so hostname/URL changes are picked up)
echo "$config" | tempio \
    -template /usr/share/cupsd.conf.tempio \
    -out /etc/cups/cupsd.conf

snapshot_cups_state

# Create or update the admin user at runtime
if ! id "$admin_user" &>/dev/null; then
    bashio::log.info "Creating CUPS admin user: ${admin_user}"
    useradd \
        --groups=sudo,lp,lpadmin \
        --create-home \
        --home-dir="/home/${admin_user}" \
        --shell=/bin/bash \
        "$admin_user"
fi
echo "${admin_user}:${admin_password}" | chpasswd
bashio::log.info "CUPS admin user '${admin_user}' configured."

bashio::log.info "CUPS configuration completed."

# Write version metadata for the ingress landing page
self_info=$(bashio::api.supervisor GET /addons/self/info true || true)
addon_version=$(bashio::jq "$self_info" '.data.version // "unknown"' || true)
addon_slug=$(bashio::jq "$self_info" '.data.slug // "cups"' || true)
echo "{\"version\":\"${addon_version}\",\"slug\":\"${addon_slug}\"}" > /var/www/ingress/version.json
