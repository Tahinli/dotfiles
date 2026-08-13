complete -c zed -l user-data-dir -d 'Sets a custom directory for all user data (e.g., database, extensions, logs). This overrides the default platform-specific data directory location: `$XDG_DATA_HOME/zed`' -r -f -a "(__fish_complete_directories)"
complete -c zed -l zed -d 'Custom path to Zed.app or the zed binary' -r -F
complete -c zed -l dev-server-token -d 'Run zed in dev-server mode' -r
complete -c zed -l diff -d 'Pairs of file paths to diff. Can be specified multiple times. When directories are provided, recurses into them and shows all changed files in a single multi-diff view' -r -F
complete -c zed -l completions -d 'Generate shell completions for Zed' -r -f -a "bash\t''
elvish\t''
fish\t''
nushell\t''
powershell\t''
zsh\t''"
complete -c zed -l askpass -d 'Used for SSH/Git password authentication, to remove the need for netcat as a dependency, by having Zed act like netcat communicating over a Unix socket' -r
complete -c zed -s w -l wait -d 'Wait for all of the given paths to be opened/closed before exiting'
complete -c zed -s a -l add -d 'Add files to the currently open workspace'
complete -c zed -s n -l new -d 'Create a new workspace'
complete -c zed -s r -l reuse -d 'Reuse an existing window, replacing its workspace'
complete -c zed -s e -l existing -d 'Open in existing Zed window'
complete -c zed -l classic -d 'Use the classic open behavior: new window for directories, reuse for files'
complete -c zed -s v -l version -d 'Print Zed\'s version and the app path'
complete -c zed -l foreground -d 'Run zed in the foreground (useful for debugging)'
complete -c zed -l system-specs -d 'Not supported in Zed CLI, only supported on Zed binary Will attempt to give the correct command to run'
complete -c zed -l dev-container -d 'Open the project in a dev container'
complete -c zed -l uninstall -d 'Uninstall Zed from user system'
complete -c zed -s h -l help -d 'Print help (see more with \'--help\')'
