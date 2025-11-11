#!/bin/bash

# Toggle eww bar visibility
# Check if eww main window is open and toggle accordingly

if eww active-windows | grep -q "main"; then
    eww close main
else
    eww open main
fi
```

Now let me add the keybind to your Hyprland config:
