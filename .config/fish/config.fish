if status is-interactive
    # Commands to run in interactive sessions can go here
end

function fish_greeting
    echo (date +%T)
end

alias ls="eza"
alias sudo="sudo-rs"

starship init fish | source
zoxide init fish | source

# opencode
fish_add_path /home/tahinli/.opencode/bin

# surrealdb
fish_add_path /home/tahinli/.surrealdb

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Hermes Agent — ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"
