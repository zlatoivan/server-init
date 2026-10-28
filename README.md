# server-init

# Инициализация сервера

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/zlatoivan/server-init.git
chmod +x server-init/config/init_server.sh
./server-init/config/init_server.sh
```

# Инициализация макбука

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/zlatoivan/server-init/main/config/init_mac.sh)"
```
