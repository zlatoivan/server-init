Серверная инициализация Ansible (замена config/init_server.sh)

Запуск

1) Перейдите в каталог ansible и укажите целевой хост в inventory.ini.

2) Выполните плейбук (подставьте пользователя SSH):

```
ansible-playbook -i inventory.ini init_server.yml -u <ssh_user> --ask-become-pass
```

Переменные

- target_user — пользователь, для которого настраиваются fish и starship (по умолчанию совпадает с ansible_user).
  Пример:

```
ansible-playbook -i inventory.ini init_server.yml -u ubuntu --extra-vars "target_user=ubuntu"
```

Что делает плейбук

- Обновляет apt-cache, ставит базовые утилиты.
- Подключает PPA: neovim, golang-backports, toolchain, fish.
- Подключает репозитории Docker CE и Caddy (через signed-by keyring).
- Устанавливает: neovim, golang-go, make, fish, docker-ce, docker-compose-plugin, caddy.
- Добавляет target_user в группу docker.
- Создаёт каталоги, разворачивает `config.fish`, `starship.toml`, делает fish логин‑шеллом.
- Устанавливает starship (если нет).
- Кладёт `Caddyfile` в `/etc/caddy/Caddyfile`, включает и стартует сервис caddy.
- Убирает исполняемые биты у `/etc/update-motd.d/*`.

Заметки

- Конфиги берутся из репозитория: `../config/config.fish`, `../config/starship.toml`, `../config/Caddyfile`.
- Если нужен иной домен/бекенд — измените `config/Caddyfile` перед запуском.
- Скрипт запуска `fish` в конце из shell‑версии не переносится (Ansible не интерактивен).
*** End Patch```}endphp.язан

