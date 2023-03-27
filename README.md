# CUPS Home Assistant Addon (x86 Compatible)

# Description

A CUPS (Common UNIX Printing System) server with a variety of included drivers, USB support, support for the Home Assistant installation's TLS certificate, and mDNS broadcasting enabled. This was created primarily to support Home Assistant installations on devices with x86 architecture, such as AMD/Intel-based thin clients. The installed driver packages focuses on HP and Brother printer support.

# Considerations

* **SSL must be disabled within the CUPS portal to prevent 502 Bad Gateway errors.** This has already been set within the default cupsd.conf.

* The CUPS portal can be viewed at localhost:631 (e.g. homeassistant:631). HA Ingress support is currently in progress, so expect the sidebar panel functionality to not work (blank pages, etc).

* Logins are disabled from the local network. The web UI from within Home Assistant is automatically authenticated.

* USB printers should be connected to the host device prior to starting this addon. If disconnected/connected during runtime, simply restart the addon.

# Acknowledgements

cupsd.conf and Dockerfile modified from https://github.com/lemariva/wifi-cups-server

Some of the Avahi and D-Bus code is modified from https://github.com/marthoc/docker-homeseer
