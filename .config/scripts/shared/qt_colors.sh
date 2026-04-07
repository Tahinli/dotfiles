#!/bin/bash
# Compute mixed surface colors for QT to match GTK mix(background, color1, ratio)

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
