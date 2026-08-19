#!/bin/bash
# USB soft plug/unplug menu (rofi), compositor-agnostic.
# "Unplug" = deauthorize the device in sysfs: kernel unbinds its drivers and it
# behaves as if pulled out, but the sysfs node stays so it can be plugged back.
# Storage devices are unmounted/powered off through udisks instead (no root).

set -u

SYSUSB=/sys/bus/usb/devices

# Optional device map (KEYBOARD_USB=...). Missing file is fine: autodetect kicks in.
# shellcheck source=/dev/null
[[ -r ${0%/*}/usb_devices.sh ]] && source "${0%/*}/usb_devices.sh"

notify() {
    command -v notify-send >/dev/null && notify-send -a "USB" "$1" "${2:-}"
}

# --- device helpers ---------------------------------------------------------

# echo every real device node (skip interfaces "1-5:1.0" and root hubs "usb1")
usb_paths() {
    local d
    for d in "$SYSUSB"/*; do
        local n=${d##*/}
        [[ $n == usb* || $n == *:* ]] && continue
        [[ -f $d/idVendor ]] && echo "$n"
    done
}

dev_name() {
    local p=$SYSUSB/$1 vendor product
    product=$(cat "$p/product" 2>/dev/null)
    vendor=$(cat "$p/manufacturer" 2>/dev/null)
    if [[ -n $product ]]; then
        [[ -n $vendor && $product != "$vendor"* ]] && echo "$vendor $product" || echo "$product"
    else
        echo "$(cat "$p/idVendor" 2>/dev/null):$(cat "$p/idProduct" 2>/dev/null)"
    fi
}

dev_authorized() { cat "$SYSUSB/$1/authorized" 2>/dev/null; }

# block devices belonging to this usb device, e.g. "sdb"
dev_blocks() {
    local b
    for b in "$SYSUSB/$1"/*/host*/target*/*/block/*; do
        [[ -e $b ]] && echo "${b##*/}"
    done
}

is_hub() { [[ $(cat "$SYSUSB/$1"/*:*/bInterfaceClass 2>/dev/null | head -1) == "09" ]]; }

# sysfs path of the keyboard: configured value wins, else the USB device whose
# input children expose a kbd handler and are not a pointer.
keyboard_path() {
    if [[ -n ${KEYBOARD_USB:-} && -d $SYSUSB/$KEYBOARD_USB ]]; then
        echo "$KEYBOARD_USB"
        return
    fi
    # Fallback only. Combo receivers (Razer/ROG) register fake keyboard inputs on
    # mice too, so this can pick the wrong one — set KEYBOARD_USB to be sure.
    local i dev p
    for i in /sys/class/input/input*; do
        [[ -e $i/capabilities/key ]] || continue
        [[ $(cat "$i/name" 2>/dev/null) == *[Kk]eyboard* ]] || continue
        # skip pointers (they own a mouse/js handler)
        compgen -G "$i/mouse*" >/dev/null && continue
        dev=$(readlink -f "$i/device" 2>/dev/null) || continue
        # walk up to the usb_device node
        while [[ $dev == /sys/* && $dev != / ]]; do
            if [[ -f $dev/idVendor ]]; then
                p=${dev##*/}
                [[ -d $SYSUSB/$p ]] && { echo "$p"; return; }
                break
            fi
            dev=${dev%/*}
        done
    done
}

# --- actions ----------------------------------------------------------------

set_auth() {
    local path=$1 val=$2
    if [[ -w $SYSUSB/$path/authorized ]]; then
        echo "$val" > "$SYSUSB/$path/authorized"
    else
        pkexec /bin/sh -c "echo $val > $SYSUSB/$path/authorized"
    fi
}

unplug() {
    local path=$1 name blocks
    name=$(dev_name "$path")
    blocks=$(dev_blocks "$path")
    if [[ -n $blocks ]]; then
        local b part
        for b in $blocks; do
            for part in /sys/block/"$b"/"$b"*; do
                [[ -e $part ]] && udisksctl unmount -b "/dev/${part##*/}" --no-user-interaction 2>/dev/null
            done
            udisksctl unmount -b "/dev/$b" --no-user-interaction 2>/dev/null
        done
        for b in $blocks; do
            if udisksctl power-off -b "/dev/$b" --no-user-interaction; then
                notify "Ejected" "$name ($b)"
                return 0
            fi
        done
    fi
    set_auth "$path" 0 && notify "Unplugged" "$name [$path]"
}

plug() {
    local path=$1
    set_auth "$path" 1 && notify "Plugged" "$(dev_name "$path") [$path]"
}

replug() {
    local path=$1
    set_auth "$path" 0 || return 1
    sleep 1
    set_auth "$path" 1 && notify "Replugged" "$(dev_name "$path") [$path]"
}

rereplug_keyboard() {
    local p
    p=$(keyboard_path)
    [[ -n $p ]] || { notify "No keyboard found" "set KEYBOARD_USB in usb_devices.sh"; return 1; }
    replug "$p"
}

plug_all() {
    local p
    for p in $(usb_paths); do
        [[ $(dev_authorized "$p") == 1 ]] || continue
        set_auth "$p" 0 || continue
        sleep 1
        set_auth "$p" 1
    done
    notify "All USB devices replugged"
}

replug_keyboard() {
    local p
    p=$(keyboard_path)
    [[ -n $p ]] || { notify "No keyboard found" "set KEYBOARD_USB in usb_devices.sh"; return 1; }
    replug "$p"
}

plug_all() {
    local p
    for p in $(usb_paths); do
        [[ $(dev_authorized "$p") == 0 ]] && set_auth "$p" 1
    done
    notify "All USB devices plugged"
}

# JSON for a waybar custom module.
waybar_json() {
    local total=0 off=0 p kb kbname state
    for p in $(usb_paths); do
        total=$((total + 1))
        [[ $(dev_authorized "$p") == 0 ]] && off=$((off + 1))
    done
    kb=$(keyboard_path)
    if [[ -n $kb ]]; then
        kbname="$(dev_name "$kb") [$kb]"
        [[ $(dev_authorized "$kb") == 1 ]] && state="plugged" || state="UNPLUGGED"
        kbname="keyboard: $kbname ($state)"
    else
        kbname="keyboard: not identified"
    fi
    local tip="left click: USB menu\nright click: replug keyboard\nmiddle click: replug all\n\n$kbname\n$off of $total devices unplugged"
    printf '{"text":"\uf287","tooltip":"%s","class":"%s"}\n' "$tip" "$([[ $off -gt 0 ]] && echo unplugged || echo ok)"
}

# --- menus ------------------------------------------------------------------

list_devices() {
    local p state icon blocks extra kb line
    kb=$(keyboard_path)
    for p in $(usb_paths); do
        state=$(dev_authorized "$p")
        [[ $state == 1 ]] && icon="🔌" || icon="⛔"
        blocks=$(dev_blocks "$p" | tr '\n' ' ')
        extra=""
        [[ -n $blocks ]] && extra=" [${blocks% }]"
        is_hub "$p" && extra="$extra [hub]"
        [[ $p == "$kb" ]] && extra="$extra [⌨️ keyboard]"
        line=$(printf '%s %s%s  (%s)' "$icon" "$(dev_name "$p")" "$extra" "$p")
        # keyboard first — it is the one you need when you cannot type
        [[ $p == "$kb" ]] && printf '0\t%s\n' "$line" || printf '1\t%s\n' "$line"
    done | sort -s -k1,1 | cut -f2-
}

menu() {
    local choice path
    choice=$(printf '%s\n🔄 Replug All\n💡 Plug All\n❌ Cancel\n' "$(list_devices)" | rofi -dmenu -p "USB" -i)
    [[ -z $choice ]] && exit 0

    case "$choice" in
        "🔄 Replug All") replug_all; return ;;
        "💡 Plug All")   plug_all; return ;;
        "❌ Cancel")   return ;;
    esac

    path=$(sed -n 's/.*(\(.*\))$/\1/p' <<<"$choice")
    [[ -d $SYSUSB/$path ]] || { notify "Unknown device" "$choice"; return; }

    local name state actions act
    name=$(dev_name "$path")
    state=$(dev_authorized "$path")
    if [[ $state == 1 ]]; then
        if [[ $path == "$(keyboard_path)" ]]; then
            actions="🔄 Replug\n⛔ Unplug"
        else
            actions="⛔ Unplug\n🔄 Replug"
        fi
        [[ -n $(dev_blocks "$path") ]] && actions="⏏️ Eject (unmount + power off)\n$actions"
    else
        actions="🔌 Plug\n🔄 Replug"
    fi
    act=$(printf '%b\n❌ Cancel\n' "$actions" | rofi -dmenu -p "$name" -i)

    case "$act" in
        "⏏️ Eject (unmount + power off)") unplug "$path" ;;
        "⛔ Unplug") unplug "$path" ;;
        "🔌 Plug")   plug "$path" ;;
        "🔄 Replug") replug "$path" ;;
    esac
}

# --- entry ------------------------------------------------------------------

case "${1:-menu}" in
    menu)   menu ;;
    list)   list_devices ;;
    off)    unplug "${2:?usage: $0 off <sysfs-path e.g. 1-5.2>}" ;;
    on)     plug   "${2:?usage: $0 on <sysfs-path>}" ;;
    replug) replug "${2:?usage: $0 replug <sysfs-path>}" ;;
    all-on)     plug_all ;;
    all-replug) replug_all ;;
    replug-keyboard|kb) replug_keyboard ;;
    waybar) waybar_json ;;
    *) echo "usage: ${0##*/} [menu|list|off <path>|on <path>|replug <path>|all-on|all-replug|replug-keyboard|waybar]" >&2; exit 1 ;;
esac
