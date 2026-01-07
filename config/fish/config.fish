# Starship
set fish_greeting
starship init fish | source

# GPG key
export GPG_TTY=$(tty)

# Docker (for route 256)
# set -x DOCKER_HOST unix://$HOME/.colima/default/docker.sock
# set -x TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE /var/run/docker.sock
