#!/bin/bash
# Полная настройка нового Mac: программы, терминал, система, Finder.
# Запуск: bash init_mac.sh
#     или bash -c "$(curl -fsSL https://raw.githubusercontent.com/zlatoivan/server-init/main/config/init_mac.sh)"
# Файлы рядом со скриптом (fish/, brewfile/) берутся из репозитория; если их нет — скачиваются с GitHub.
# Чтобы пропустить раздел, закомментируйте его вызов в самом низу файла.

set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
FISH_PATH="/opt/homebrew/bin/fish"
SCREENSHOTS_DIR="$HOME/Скриншоты"   # поменяйте, если нужна другая папка
GIT_NAME="izlatovratskiy"
GIT_EMAIL="zlatoivan4@gmail.com"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# При запуске через curl | bash рядом со скриптом нет файлов репозитория — скачиваем их
if [ ! -d "$DIR/fish" ]; then
  echo "Скачиваю файлы репозитория..."
  curl -fsSL https://github.com/zlatoivan/server-init/archive/refs/heads/main.tar.gz \
    | tar -xz -C "$TMP_DIR" || { echo "Не удалось скачать репозиторий"; exit 1; }
  DIR="$TMP_DIR/server-init-main/config"
fi

FAILED=()

########################################
# Вспомогательное
########################################

# Запускает раздел в подоболочке со строгим режимом:
# раздел останавливается на первой ошибке, но остальные разделы продолжают работу.
run() {
  local title="$1"; shift
  echo ""
  echo "==> $title"
  ( set -e; "$@" )
  if [ $? -ne 0 ]; then
    echo "  ! Раздел «$title» завершился с ошибкой, см. вывод выше"
    FAILED+=("$title")
  fi
}

########################################
# 1. Программы
########################################
install_apps() {
  if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
    echo "Устанавливаю Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"

  local brewfile=""
  for f in "$DIR/Brewfile" "$DIR/brewfile/Brewfile"; do
    [ -f "$f" ] && brewfile="$f" && break
  done
  if [ -z "$brewfile" ]; then
    echo "Brewfile не найден рядом со скриптом"
    return 1
  fi

  brew bundle --file="$brewfile" || echo "  ! Часть пакетов не установилась, см. вывод выше"
}

########################################
# 2. Терминал: Dracula, fish, starship, git
########################################
setup_terminal() {
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Тема Dracula для Терминала
  curl -fsSL -o "$TMP_DIR/Dracula.terminal" \
    https://raw.githubusercontent.com/dracula/terminal-app/master/Dracula.terminal
  open "$TMP_DIR/Dracula.terminal"   # импортирует профиль в Терминал
  sleep 2
  defaults write com.apple.Terminal "Default Window Settings" -string "Dracula"
  defaults write com.apple.Terminal "Startup Window Settings" -string "Dracula"
  # Шрифт с иконками для starship (ставится из Brewfile)
  osascript -e 'tell application "Terminal" to set font name of settings set "Dracula" to "FiraMonoNFM-Regular"' \
    || echo "  ! Шрифт профиля Dracula поставьте вручную: FiraMono Nerd Font Mono"

  # fish как оболочка по умолчанию
  if ! grep -qx "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi
  if [ "$(dscl . -read ~/ UserShell | awk '{print $2}')" != "$FISH_PATH" ]; then
    chsh -s "$FISH_PATH"
  fi

  mkdir -p ~/.config/fish
  [ -f ~/.config/fish/config.fish ] && cp ~/.config/fish/config.fish ~/.config/fish/config.fish.bak
  cp -R "$DIR/fish/." ~/.config/fish/

  # Подсветка ввода в стиле Dracula
  yes | "$FISH_PATH" -c 'fish_config theme save Dracula' >/dev/null 2>&1 \
    || echo "  ! Тему fish поставьте вручную: fish_config"

  # Переменная для mermaid-cli (рендер через установленный Chrome)
  "$FISH_PATH" -c 'set -Ux PUPPETEER_EXECUTABLE_PATH "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"'

  # starship: только directory, git_branch и os.symbols
  mkdir -p ~/.config
  cp "$DIR/starship/mac.toml" ~/.config/starship.toml

  # git: задаём имя и почту, только если они ещё не заданы
  # (чтобы не перезаписать рабочие настройки на корпоративном Mac)
  git config --global user.name  >/dev/null || git config --global user.name  "$GIT_NAME"
  git config --global user.email >/dev/null || git config --global user.email "$GIT_EMAIL"
}

########################################
# 3. Система
########################################
setup_macos() {
  # Скорость трекпада (0–3)
  defaults write NSGlobalDomain com.apple.trackpad.scaling -float 1.5

  # Время по сети
  sudo systemsetup -setusingnetworktime on >/dev/null 2>&1 || true

  # Питание: не затемнять от батареи, не засыпать от сети, дисплей гаснет через 5 минут
  sudo pmset -b lessbright 0
  sudo pmset -c sleep 0
  sudo pmset -b displaysleep 5
  sudo pmset -c displaysleep 10

  # Пароль сразу после заставки / выключения дисплея
  sysadminctl -screenLock immediate -password - 2>/dev/null \
    || echo "  ! Пароль после заставки: настройте вручную (Экран блокировки)"

  # Строка меню: процент заряда, без Spotlight, звук всегда
  defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
  defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1
  defaults -currentHost write com.apple.controlcenter Sound -int 18

  # Dock и окна
  defaults write com.apple.dock autohide -bool true
  for corner in tl tr bl br; do
    defaults write com.apple.dock "wvous-${corner}-corner" -int 1
    defaults write com.apple.dock "wvous-${corner}-modifier" -int 0
  done
  defaults write NSGlobalDomain AppleWindowTabbingMode -string always
  defaults write com.apple.dock minimize-to-application -bool true
  defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

  # Скриншоты в отдельную папку
  mkdir -p "$SCREENSHOTS_DIR"
  defaults write com.apple.screencapture location -string "$SCREENSHOTS_DIR"
}

########################################
# 4. Finder
########################################
setup_finder() {
  # Новые окна открывают «Документы»
  defaults write com.apple.finder NewWindowTarget -string PfDo
  defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Documents/"

  defaults write NSGlobalDomain AppleShowAllExtensions -bool true   # все расширения
  defaults write com.apple.finder _FXSortFoldersFirst -bool true    # папки вверху
  defaults write com.apple.finder FXPreferredViewStyle -string Nlsv # вид «список»
  defaults write com.apple.finder ShowStatusBar -bool true          # строка состояния

  # Сбросить сохранённые виды папок, чтобы везде применился «список»
  find ~/Documents ~/Downloads ~/Desktop -name .DS_Store -delete 2>/dev/null || true
}

########################################
# Запуск
########################################

echo "Нужны права администратора..."
sudo -v
# Держим sudo активным, пока идёт установка (она может длиться дольше 5 минут)
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

run "Программы (Homebrew + Brewfile)" install_apps
run "Терминал (Dracula, fish, starship, git)" setup_terminal
run "Система" setup_macos
run "Finder" setup_finder

killall Finder Dock ControlCenter SystemUIServer 2>/dev/null

echo ""
if [ ${#FAILED[@]} -eq 0 ]; then
  echo "Готово. Перезагрузите Mac."
else
  echo "Готово, но с ошибками в разделах:"
  printf '  - %s\n' "${FAILED[@]}"
  echo "Исправьте и запустите скрипт ещё раз — он безопасен для повторного запуска."
fi

cat <<'EOF'

Вручную осталось:
  Система
  - Touch ID
  - Автояркость дисплея
  - Сочетание Option+Z для снимков экрана
  - Ctrl+Option+T для Терминала (приложение «Команды»)
  - Замены текста
  - Отключить сочетание «Короткая заметка»
  Finder
  - Боковое меню
  Терминал
  - Проверить, что профиль Dracula выбран по умолчанию
  - Option как метаклавиша
  Программы
  - SingularityApp из App Store
  - GoLand: включить Settings Sync
  - Настройки OBS
  - Wispr Flow: войти, выдать доступ к микрофону и «Универсальному доступу»
EOF