#!/bin/bash
# Installs the udev rule that lets usb_menu.sh work without a password prompt.
# Run once as root:  sudo bash ~/.config/scripts/system/install-usb-nopasswd.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root: sudo bash $0" >&2; exit 1; }

src="$(dirname "$(readlink -f "$0")")/usb-nopasswd.rules"
install -m 0644 "$src" /etc/udev/rules.d/90-usb-authorized.rules
udevadm control --reload

# Apply to devices already plugged in (udev add events already fired for them).
for d in /sys/bus/usb/devices/*/authorized; do
    chgrp wheel "$d" && chmod 0660 "$d"
done

echo "installed: /etc/udev/rules.d/90-usb-authorized.rules"
ls -l /sys/bus/usb/devices/1-*/authorized 2>/dev/null | head -3
