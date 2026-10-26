# Changelog

All notable changes to this project will be documented in this file.

## [1.2.2] - 2026-03-11

### Fixed
- Added explicit CUPS state snapshot and restore logic under `/data/cups-backup` so printer definitions survive future upgrades even if the live `/data/cups` state is missing or incomplete
- Added a `cups-server` shutdown hook to snapshot current CUPS state before service stop

## [1.2.1] - 2026-03-11

### Fixed
- `initialization/up` now uses a direct command instead of shell builtins in the oneshot `up` file, fixing addon startup failure on Home Assistant OS 17.1 (`s6-rc-oneshot-run: fatal: unable to exec set`)

### Documentation
- README s6 guidance now recommends raw commands or explicit interpreter invocations for oneshot `up` files

## [1.2.0] - 2026-02-23

### Changed
- CI workflow now reads base image from `build.yaml` via `yq`; `build.yaml` is the single source of truth for the base image version (#10)
- s6 service scripts standardized: `initialization/up` shebang corrected to `with-contenv bashio`; `exec` prepended to daemon invocations in `avahi-daemon/run`, `cups-server/run`, `dbus-daemon/run` for correct signal handling (#12)

### Documentation
- Dockerfile `apt-get install` block annotated with per-package rationale, distinguishing runtime-required packages from convenience/debug tooling (#13)
- README: added s6-overlay script conventions guide for contributors

## [1.1.8] - 2026-02-23

### Fixed
- "Open Addon Settings" link now uses the correct HA URL path (`/config/app/{slug}/config`) and the full addon slug including repository hash prefix (e.g. `ad135c38_cups`) read from the Supervisor API at startup

## [1.1.7] - 2026-02-23

### Fixed
- nginx now binds to `0.0.0.0:8099` again — the Supervisor connects from its own container, not localhost, so `127.0.0.1` binding prevented ingress from reaching the landing page

## [1.1.6] - 2026-02-23

### Fixed
- CI workflow now triggers on `v`-prefixed tags (e.g. `v1.1.6`), fixing missing GitHub Releases and release badge

## [1.1.5] - 2026-02-23

### Fixed
- Landing page is now a static file baked into the image — nginx starts immediately, fixing "app not ready" dialog on addon start
- Removed `cups-config` dependency from ingress-server service; version loaded asynchronously via JS

## [1.1.4] - 2026-02-23

### Fixed
- Settings link now opens in the HA parent frame instead of inside the ingress iframe

## [1.1.3] - 2026-02-23

### Fixed
- Reduced nginx CPU usage from ~25% to near-zero (disabled access logging, tuned worker settings)

## [1.1.2] - 2026-02-23

### Fixed
- nginx now binds to `127.0.0.1:8099` only, preventing interference with other addon UIs
- Removed Debian's default nginx site configs at build time

## [1.1.1] - 2026-02-23

### Fixed
- CUPS web UI accessible without 401 errors (`Allow all` replaces `Allow @LOCAL` for `/` and `/admin`)

## [1.1.0] - 2026-02-23

### Added
- Sidebar landing page with link to CUPS web UI, addon settings shortcut, and documentation links
- nginx + s6 `ingress-server` service to serve the landing page

### Changed
- `ingress_port` changed from `631` to `8099`; CUPS remains on port 631 via direct access

## [1.0.13] - 2026-02-22

### Fixed
- cups-browsed: replaced `--no-daemon` with `-d` for cups-filters 1.28.17 compatibility

## [1.0.12] - 2026-02-22

### Changed
- Removed `image` field from config.yaml (local Dockerfile builds until ghcr.io resolved)

## [1.0.11] - 2026-02-22

### Added
- Configurable options: `admin_user`, `admin_password`, `cups_log_level`, `default_paper_size`

### Changed
- Admin user created at runtime via `chpasswd` instead of baked into the image

## [1.0.10] - 2026-02-22
- Added CHANGELOG.md

## [1.0.9] - 2026-02-22
- Added `cups-browsed` and `cups-filters` for AirPrint via Avahi

## [1.0.8] - 2026-02-22
- CUPS logs now written to stdout/stderr for HA log viewer

## [1.0.7] - 2026-02-22
- Added CI workflow, `image` field in config.yaml, auto GitHub Releases, README badges

## [1.0.6] - 2026-02-22
- Fixed blank ingress screen (`ServerAlias *`, `DefaultEncryption Never`)

## [1.0.5] - 2026-02-22
- Removed failing `ulimit` calls from startup scripts

## [1.0.4] - Prior
- Forked from [niallr/ha-cups-addon](https://github.com/niallr/ha-cups-addon) with s6 refactor and ingress fixes
