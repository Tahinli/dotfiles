# Names of the app workspaces, sourced by the niri workspace scripts.
# Not executable on purpose.
#
# These are NOT declared in config.kdl: a declared `workspace "name"` node makes
# niri keep that workspace alive forever, which left eight empty workspaces
# sitting around. Instead workspace_app.sh names a fresh workspace on launch and
# workspace_reaper.sh un-names it once it empties, letting niri reap it.
#
# Only names in this list are ever un-named, so a workspace you name by hand is
# left alone.

APP_WORKSPACES=(code github whatsapp discord deezer youtube mail signal)

# True if $1 is one of the app workspaces.
is_app_workspace() {
    local candidate="$1" name
    for name in "${APP_WORKSPACES[@]}"; do
        [ "$name" = "$candidate" ] && return 0
    done
    return 1
}
