# frp 客户端（可选公网）

把本机 `127.0.0.1:8787` 经 frpc 暴露到已有 frps。

```bash
cp frpc.example.toml ~/.config/mac-bridge/frpc.toml
# 编辑 YOUR_FRPS_* 与域名
# macOS: ../scripts/install-frpc-launchd.sh
# Linux: 由 install-systemd.sh 在非占位时自动 enable frpc unit
```

公网示例：`https://<BRIDGE_HOST>/yunxiao/codeup`  
**未 smoke 通前不要改 Codeup 远端。**
