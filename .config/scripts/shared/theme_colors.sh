#!/bin/bash
# Post-process wallust-generated theme files:
# - GTK 3/4: resolve mix(#hex, #hex, ratio) to pre-computed hex values
# - QT 5/6: convert colors and compute mixed surface colors

# Configure ~/.gtkrc-2.0:
# - Force gtk-theme-name to Raleigh (minimal, no pixmap engine, lets our colors through)
# - Ensure our include is parsed LAST so our styles win
GTKRC="$HOME/.gtkrc-2.0"
MINE_INC='include "/home/tahinli/.gtkrc-2.0.mine"'
if [ -f "$GTKRC" ] && grep -qF "$MINE_INC" "$GTKRC"; then
    grep -vF "$MINE_INC" "$GTKRC" | sed 's/^gtk-theme-name=.*/gtk-theme-name="Raleigh"/' > "$GTKRC.tmp"
    echo "$MINE_INC" >> "$GTKRC.tmp"
    mv "$GTKRC.tmp" "$GTKRC"
fi

# Convert hex colors to KDE's R,G,B integer format in kdeglobals
KDEGLOBALS="$HOME/.config/kdeglobals"
if [ -f "$KDEGLOBALS" ]; then
    python3 -c "
import re
def mix(c1, c2, f):
    r = int(int(c1[1:3],16)*(1-f) + int(c2[1:3],16)*f)
    g = int(int(c1[3:5],16)*(1-f) + int(c2[3:5],16)*f)
    b = int(int(c1[5:7],16)*(1-f) + int(c2[5:7],16)*f)
    return f'#{r:02x}{g:02x}{b:02x}'
with open('$KDEGLOBALS') as f:
    content = f.read()
content = re.sub(
    r'mix\(\s*(#[0-9A-Fa-f]{6})\s*,\s*(#[0-9A-Fa-f]{6})\s*,\s*([0-9.]+)\s*\)',
    lambda m: mix(m.group(1), m.group(2), float(m.group(3))),
    content
)
content = re.sub(
    r'#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})',
    lambda m: f'{int(m.group(1),16)},{int(m.group(2),16)},{int(m.group(3),16)}',
    content
)
with open('$KDEGLOBALS', 'w') as f:
    f.write(content)
"
fi

# Resolve mix() in GTK CSS / gtkrc files
for css in ~/.config/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk-dark.css ~/.config/gtk-3.0/gtk.css ~/.gtkrc-2.0.mine; do
    [ -f "$css" ] || continue
    python3 -c "
import re
def mix(c1, c2, f):
    r = int(int(c1[1:3],16)*(1-f) + int(c2[1:3],16)*f)
    g = int(int(c1[3:5],16)*(1-f) + int(c2[3:5],16)*f)
    b = int(int(c1[5:7],16)*(1-f) + int(c2[5:7],16)*f)
    return f'#{r:02x}{g:02x}{b:02x}'

with open('$css') as f:
    content = f.read()
content = re.sub(
    r'mix\(\s*(#[0-9A-Fa-f]{6})\s*,\s*(#[0-9A-Fa-f]{6})\s*,\s*([0-9.]+)\s*\)',
    lambda m: mix(m.group(1), m.group(2), float(m.group(3))),
    content
)
with open('$css', 'w') as f:
    f.write(content)
"
done

for conf in ~/.config/qt5ct/colors/wallust.conf ~/.config/qt6ct/colors/wallust.conf; do
    [ -f "$conf" ] || continue

    # Convert #RRGGBB to #ffRRGGBB (strip any existing ff first to avoid double-prefix)
    sed -i 's/#ff\([0-9A-Fa-f]\{6\}\)/#\1/g; s/#\([0-9A-Fa-f]\{6\}\)/#ff\1/g' "$conf"

    # Extract foreground (pos 0), color1 (pos 1), background (pos 4), color4 (pos 12)
    IFS=',' read -ra COLS <<< "$(grep '^active_colors=' "$conf" | cut -d'=' -f2)"
    FG="${COLS[0]// /}"
    C1="${COLS[1]// /}"
    BG="${COLS[4]// /}"
    C4="${COLS[12]// /}"

    FG="${FG/#\#ff/}"
    C1="${C1/#\#ff/}"
    BG="${BG/#\#ff/}"
    C4="${C4/#\#ff/}"

    # Compute mixed colors:
    # surface = mix(bg, c1, 0.35) - window/base
    # button  = mix(bg, c1, 0.45) - button bg
    # accent  = mix(c4, fg, 0.3)  - lightened selection
    COMPUTED=$(python3 -c "
def m(a, b, f):
    r = int(int(a[0:2],16)*(1-f) + int(b[0:2],16)*f)
    g = int(int(a[2:4],16)*(1-f) + int(b[2:4],16)*f)
    bl = int(int(a[4:6],16)*(1-f) + int(b[4:6],16)*f)
    return f'{r:02X}{g:02X}{bl:02X}'
print(m('$BG', '$C1', 0.35))
print(m('$BG', '$C1', 0.45))
print(m('$C4', '$FG', 0.3))
")
    MIXED=$(echo "$COMPUTED" | sed -n '1p')
    MIXED_BTN=$(echo "$COMPUTED" | sed -n '2p')
    MIXED_ACCENT=$(echo "$COMPUTED" | sed -n '3p')

    # Replace surface roles: Base(9), Window(10), AlternateBase(16), ToolTipBase(17) with MIXED
    # Replace Button(1) with MIXED_BTN
    # Replace Highlight(12) and pos 20 with MIXED_ACCENT
    python3 -c "
mixed = '#ff$MIXED'
mixed_btn = '#ff$MIXED_BTN'
mixed_accent = '#ff$MIXED_ACCENT'
c1 = '#ff$C1'
c4 = '#ff$C4'
with open('$conf') as f: lines = f.readlines()
out = []
for line in lines:
    if '=' not in line or line.startswith('['):
        out.append(line); continue
    key, vals = line.strip().split('=', 1)
    cols = [v.strip() for v in vals.split(',')]
    for i in [9, 10, 16, 17]:
        if i < len(cols) and cols[i] == c1:
            cols[i] = mixed
    if 1 < len(cols) and cols[1] == c1:
        cols[1] = mixed_btn
    for i in [12, 20]:
        if i < len(cols) and cols[i] == c4:
            cols[i] = mixed_accent
    out.append(key + '=' + ', '.join(cols) + '\n')
with open('$conf', 'w') as f: f.writelines(out)
"
done
