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
