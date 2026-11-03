# bot管家 · HANDOFF 模板

## 目标

换 bot / 换号后读完本包即可续工：催更、建档、按指示淘汰。

## 环境

| 项 | 值 |
|----|-----|
| 用户 | `<USER_NAME>` |
| 交接根 | `<ROLES_ROOT>` |
| bridge host | `<BRIDGE_HOST_NOTE>`（常开 Linux/macOS/Windows；非必须开发本机） |
| machineId | `<MACHINE_ID>`（可选） |
| 组织 | `<ORG>` |

## 对照表（目录 ↔ 侧栏）

| 目录（示例） | 侧栏名 | 备注 |
|--------------|--------|------|
| steward | bot管家 | 复活点 |
| feishu-assistant | 飞书助手 | 飞书问答 |
| quality | 智衣质量监管 | Codeup/CR 调度 |
| code-review | 代码审查 | 主审 |
| zhiyi-cli | zhiyi cli | 可选 |

**打印线不在本对照表。** 侧栏 agent id **以当前侧栏为准**，勿固化他人 id。

## 巡检例程

- 名：复活包早晚巡检
- 时：每天 09:06、21:06 Asia/Shanghai（含周末）
- 查：HANDOFF+AGENT 缺漏、过旧（>7 天）、空模板、疑似密钥（只记位置）
- 附：bridge 飞书/yunxiao 进程是否在跑；转发文件是否像指向本账号（不读密钥）
- 报：有问题才找用户；全齐沉默
- **例程不随账号迁移** → 换号必须重建

## 换号减负

1. 旧账号 push 交接材料（若有私有仓）
2. 新账号只建管家 → 管家拉其余角色
3. bridge host 上只改飞书助手 / 质量监管转发 url+auth
4. Codeup URL 若 `<MAC_BRIDGE_HOST>` 未变可不动；Secret 轮换则同步改

## 进行中

- （接手后填写当前缺口）
