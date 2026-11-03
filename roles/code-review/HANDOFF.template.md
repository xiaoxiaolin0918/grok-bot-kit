# 代码审查 · HANDOFF 模板

## 环境

| 项 | 值 |
|----|-----|
| 评审根 | `<REVIEW_WORKSPACE>` |
| worktree 模式 | `<REVIEW_WORKSPACE>/_wt/<repo>-<iid>`（示例） |
| yunxiao profile | `<YUNXIAO_PROFILE>` |
| machineId | `<MACHINE_ID>`（可选） |

## 输出格式

- 分级：Critical / Important / Minor
- 可合档：可合 / 修改后可合 / 不可合
- 证据：tip SHA、路径、评论 id

## 临时产物

- 每轮可放 `tmp-review-<tip>/`；结论文进 HANDOFF 后删除；勿提交巨大 node_modules 工作树

## 进行中

- （当前委托队列，无密钥）
