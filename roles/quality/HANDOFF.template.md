# 智衣质量监管 · HANDOFF 模板

## Webhook

- 例程名建议：`codeup-cr-webhook`（自定）
- 公网：`https://<MAC_BRIDGE_HOST>/yunxiao/codeup`
- Secret：与 bridge `yunxiao_ingress_secret` 相同；头 **`X-Codeup-Token`**
- **先 smoke 再改 Codeup 远端**

## 分派

- 默认主审侧栏名：代码审查
- 可溢出临时审角（不建复活包）
- yunxiao CLI profile：`<YUNXIAO_PROFILE>`（密钥在本机 CLI 配置，不写本文件）

## 评审工作区（若用本机）

- 根：`<REVIEW_WORKSPACE>`
- **禁止**在开发主力工作区直接改 tip 做 CR

## 进行中

- （当前闸门：如暂停某自动审工具、合 master 策略等，用非密钥短句记录）
