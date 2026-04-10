#!/bin/bash
# Post-process wallust-generated theme files:
# - GTK 3/4: resolve mix(#hex, #hex, ratio) to pre-computed hex values
# - QT 5/6: convert colors and compute mixed surface colors

# Resolve mix() in GTK CSS files
for css in ~/.config/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk-dark.css ~/.config/gtk-3.0/gtk.css; do
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

    # Convert #RRGGBB to #ffRRGGBB
    sed -i 's/#\([0-9A-Fa-f]\{6\}\)/#ff\1/g' "$conf"

    # Extract background (pos 4) and color1 (pos 1) from active_colors
    IFS=',' read -ra COLS <<< "$(grep '^active_colors=' "$conf" | cut -d'=' -f2)"
    BG="${COLS[4]// /}"   # Dark role = background
    C1="${COLS[1]// /}"   # Button role = color1

    BG="${BG/#\#ff/}"
    C1="${C1/#\#ff/}"

    # Compute mix(bg, c1, ratio) for surface colors
    SURFACE=$(python3 -c "
bg='$BG'; c1='$C1'
for f in [0.35, 0.45]:
    r=int(int(bg[0:2],16)*(1-f)+int(c1[0:2],16)*f)
    g=int(int(bg[2:4],16)*(1-f)+int(c1[2:4],16)*f)
    b=int(int(bg[4:6],16)*(1-f)+int(c1[4:6],16)*f)
    print(f'{r:02X}{g:02X}{b:02X}')
")
    MIXED=$(echo "$SURFACE" | head -1)
    MIXED_BTN=$(echo "$SURFACE" | tail -1)

    # Replace surface roles: Base(9), Window(10), AlternateBase(16), ToolTipBase(17) with MIXED
    # Replace Button(1) with MIXED_BTN
    python3 -c "
import re
mixed, mixed_btn = '#ff$MIXED', '#ff$MIXED_BTN'
c1 = '#ff$C1'
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
    out.append(key + '=' + ', '.join(cols) + '\n')
with open('$conf', 'w') as f: f.writelines(out)
"
done
