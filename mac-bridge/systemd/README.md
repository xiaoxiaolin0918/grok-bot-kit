# systemd（Linux bridge host）

1. 填好 `~/.config/mac-bridge/config.json` 与密钥文件  
2. `./scripts/install-systemd.sh`（替换 `__BRIDGE_ROOT__` / node / frpc 路径并 `systemctl --user enable --now`）  
3. 若要用 user lingering：`loginctl enable-linger $USER`（注销后仍跑）

macOS 请用 `../launchd` + `../scripts/install-launchd.sh`。
