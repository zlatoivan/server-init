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

  # Тема Dracula для Терминала, Option — метаклавиша
  curl -fsSL -o "$TMP_DIR/Dracula.terminal" \
    https://raw.githubusercontent.com/dracula/terminal-app/master/Dracula.terminal
  plutil -replace useOptionAsMetaKey -bool true "$TMP_DIR/Dracula.terminal"
  open "$TMP_DIR/Dracula.terminal"   # импортирует профиль в Терминал
  sleep 2

  # Шрифт с иконками для starship (ставится из Brewfile) и профиль по умолчанию.
  # Через сам Терминал, а не defaults: иначе он перезапишет настройки при выходе.
  osascript >/dev/null <<'APPLESCRIPT' || true
tell application "Terminal"
  set font name of settings set "Dracula" to "FiraMonoNFM-Regular"
  set default settings to settings set "Dracula"
  set startup settings to settings set "Dracula"
end tell
APPLESCRIPT
  if [ "$(osascript -e 'tell application "Terminal" to name of default settings' 2>/dev/null)" != "Dracula" ]; then
    echo "  ! Профиль Dracula не стал профилем по умолчанию: Терминал → Настройки → Профили"
  fi
  if [ "$(osascript -e 'tell application "Terminal" to font name of settings set "Dracula"' 2>/dev/null)" != "FiraMonoNFM-Regular" ]; then
    echo "  ! Шрифт профиля Dracula поставьте вручную: FiraMono Nerd Font Mono"
  fi

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

  # Option+Z — снимок выделенной области в буфер обмена (вместо ⌃⇧⌘4)
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 31 \
    '<dict><key>enabled</key><true/><key>value</key><dict><key>type</key><string>standard</string>
     <key>parameters</key><array><integer>122</integer><integer>6</integer><integer>524288</integer></array></dict></dict>'
  /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
    || echo "  ! Сочетание Option+Z заработает после перезахода в систему"
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
# 5. IDE от JetBrains: GoLand, PyCharm
########################################
# setup_jetbrains <имя приложения> — одинаковые настройки для любой IDE JetBrains
setup_jetbrains() {
  local ide="$1"
  local app="/Applications/$ide.app"
  if [ ! -d "$app" ]; then
    echo "$ide не установлен"
    return 1
  fi
  if ps -axo comm= | grep -q "^$app/Contents/MacOS/"; then
    echo "Закройте $ide и запустите раздел заново: иначе он перезапишет настройки при выходе"
    return 1
  fi

  # Папка настроек текущей версии, например GoLand2026.2 (создаётся и до первого запуска)
  local name
  name="$(plutil -extract dataDirectoryName raw "$app/Contents/Resources/product-info.json")"
  local options="$HOME/Library/Application Support/JetBrains/$name/options"
  mkdir -p "$options"

  # Без этого флага при первом запуске IDE «переходит на новый интерфейс» и сбрасывает тему на Islands Dark
  jetbrains_registry "$options/../early-access-registry.txt" ide.experimental.ui true

  # Меняем только нужные параметры, остальное в файлах не трогаем
  jetbrains_set "$options/laf.xml" LafManager '<laf ' '<laf themeId="Islands Darcula" />'
  jetbrains_set "$options/colors.scheme.xml" EditorColorsManagerImpl '<global_color_scheme ' '<global_color_scheme name="Darcula" />'

  jetbrains_option "$options/editor-font.xml" DefaultFont VERSION 1
  jetbrains_option "$options/editor-font.xml" DefaultFont FONT_SIZE 12
  jetbrains_option "$options/editor-font.xml" DefaultFont FONT_SIZE_2D 12.0
  jetbrains_option "$options/editor-font.xml" DefaultFont LINE_SPACING 1.1

  jetbrains_option "$options/terminal-local.xml" TerminalLocalOptions shellPath "$FISH_PATH"
  jetbrains_option "$options/terminal.xml" TerminalOptionsProvider terminalEngine CLASSIC
  jetbrains_option "$options/terminal-font.xml" TerminalFontOptions VERSION 1
  jetbrains_option "$options/terminal-font.xml" TerminalFontOptions FONT_SIZE 12
  jetbrains_option "$options/terminal-font.xml" TerminalFontOptions FONT_SIZE_2D 12.0
}

# jetbrains_registry <файл> <ключ> <значение> — файл из пар строк «ключ», «значение»
jetbrains_registry() {
  local file="$1" key="$2" value="$3"
  touch "$file"
  awk -v key="$key" -v value="$value" '
    NR % 2 == 1 { k = $0; print; next }
    { print (k == key ? value : $0); if (k == key) found = 1 }
    END { if (!found) { print key; print value } }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# jetbrains_option <файл> <component> <имя> <значение> — задаёт <option name="..." value="..." />
jetbrains_option() {
  jetbrains_set "$1" "$2" "<option name=\"$3\"" "<option name=\"$3\" value=\"$4\" />"
}

# jetbrains_set <файл> <component> <начало строки> <строка целиком>
# Заменяет строку внутри component (или добавляет её); недостающие файл и component создаёт.
jetbrains_set() {
  local file="$1" component="$2" key="$3" line="$4"
  grep -q '</application>' "$file" 2>/dev/null || printf '<application>\n</application>\n' > "$file"
  awk -v comp="<component name=\"$component\"" -v key="$key" -v line="$line" '
    index($0, comp) {
      found = 1
      if ($0 ~ /\/>[[:space:]]*$/) {   # пустой <component ... />
        sub(/[[:space:]]*\/>[[:space:]]*$/, ">"); print; print "    " line; print "  </component>"; next
      }
      inside = 1; print; next
    }
    inside && index($0, key) { print "    " line; done = 1; next }
    inside && /<\/component>/ { if (!done) print "    " line; inside = 0 }
    /<\/application>/ && !found { print "  " comp ">"; print "    " line; print "  </component>" }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
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
run "GoLand" setup_jetbrains GoLand
run "PyCharm" setup_jetbrains PyCharm

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
    - Отключить сочетание «Короткая заметка» (настройки → Клавиатура → Сочетания клавиш → Mission Control → «Короткая заметка» → снять галочку)
    - Замены текста (должны подтянуться с аккаунтом Apple)
    - Ctrl+Option+T для Терминала (приложение «Команды»)
  Finder
    - Боковое меню
  Программы
    - GoLand: проверить, что настройки подтянудись
    - OBS: настроить
    - Wispr Flow: войти, выдать доступ к микрофону и «Универсальному доступу»
EOF