#!/bin/sh
# Запуск: bash -c "$(curl -fsSL https://raw.githubusercontent.com/zlatoivan/server-init/main/config/init_server.sh)"

# important
sudo apt update
sudo apt install -y apt-transport-https ca-certificates software-properties-common gnupg lsb-release debian-keyring debian-archive-keyring curl rsync

# Конфиги берём рядом со скриптом; при запуске по ссылке скачиваем репозиторий.
DIR="$(cd "$(dirname "$0")" && pwd)" || exit 1
if [ ! -d "$DIR/fish" ]; then
  TMP_DIR="$(mktemp -d)" || exit 1
  trap 'rm -rf "$TMP_DIR"' EXIT
  echo "Скачиваю файлы репозитория..."
  if ! curl -fsSL -o "$TMP_DIR/repository.tar.gz" \
    https://github.com/zlatoivan/server-init/archive/refs/heads/main.tar.gz \
    || ! tar -xzf "$TMP_DIR/repository.tar.gz" -C "$TMP_DIR"; then
    echo "Не удалось скачать или распаковать репозиторий"
    exit 1
  fi
  DIR="$TMP_DIR/server-init-main/config"
fi

# repositories
sudo add-apt-repository -y ppa:neovim-ppa/stable # nvim
sudo add-apt-repository -y ppa:longsleep/golang-backports # go
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test # make
sudo apt-add-repository -y ppa:fish-shell/release-3 # fish
  # docker
sudo curl -fsSL 'https://download.docker.com/linux/ubuntu/gpg' | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  # caddy
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

sudo apt update
sudo apt install -y neovim golang-go make fish docker-ce caddy docker-compose-plugin

# cron
sudo mkdir -p /etc/cron.d
sudo rsync -a "$DIR/cron.d/docker-cleanup" /etc/cron.d/docker-cleanup

# go
mkdir -p $HOME/go/bin

# fish
mkdir -p ~/.config/fish
rsync -a "$DIR/fish/config.fish" ~/.config/fish/config.fish
rsync -a "$DIR/fish/conf.d" ~/.config/fish/
chsh -s /usr/bin/fish $USER

# starship
curl -sS https://starship.rs/install.sh | sh -s -- -y
rsync -a "$DIR/starship/server.toml" ~/.config/starship.toml

# caddy
rsync -a "$DIR/caddy/Caddyfile" /etc/caddy/Caddyfile
sudo systemctl start caddy

# ssh (убрать приветствие)
sudo chmod -x /etc/update-motd.d/*

# new terminal
fish
