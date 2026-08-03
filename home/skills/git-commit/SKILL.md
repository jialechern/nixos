---
name: git-commit
description: "根据 git 变更生成符合 Conventional Commits 规范的中文提交信息并提交。当用户要求提交代码、生成 commit message、或处理 git 提交相关任务时使用本 skill。会先检查 git status 与 diff, 生成规范提交信息, 经用户确认后执行 git commit (不 push)。"
license: MIT
compatibility: git 仓库
metadata:
  audience: ai-agents
---

# Git 提交信息生成 (git-commit)

## 流程

### 1. 检查仓库状态

```bash
git status --short     # 变更概览 (暂存/未暂存/未跟踪)
git log --oneline -5   # 参考仓库最近的提交风格
```

- 已暂存 (staged) 变更存在且无未暂存变更 → 基于暂存区
- 否则基于全部变更 (相对 HEAD)

### 2. 获取差异

```bash
git diff HEAD          # 全部变更 (默认)
git diff --cached      # 仅暂存区 (用户已明确 stage 时)
```

差异过长时按文件分段阅读关键内容, 不要忽略新增文件。

### 3. 生成提交信息

用户可能提供补充说明: 它是理解变更动机与背景的第一手信息, 优先级高于对 diff
的推测; 与 diff 有出入时以补充说明为准描述动机、以 diff 为准描述实际改动。

规则:

1. 严格遵循 Conventional Commits: `<type>(<scope>): <description>`
2. type 从: feat, fix, docs, style, refactor, perf, test, chore, ci, build,
   revert
3. 变更范围明确时加 scope (例: `fix(auth): 修复登录验证码失效问题`)
4. description 使用中文, 简洁明了, 以句号结尾, 不超过 50 字
5. body 使用中文描述: 变更内容 (改了什么、怎么改的) / 变更原因 (为什么这样改) /
   影响范围; body 与 subject 之间留一空行
6. 破坏性变更在 footer 添加 `BREAKING CHANGE` 段落后跟中文说明
7. 有关联 issue / PR 时 footer 以 `Closes #xxx` / `Refs #xxx` 引用
8. 仅输出 commit message 本身, 不要包裹在 markdown code block 中

### 4. 提交前确认

- 将生成的提交信息完整展示给用户
- **明确征得确认后才执行** `git commit`
- 执行时保证信息与展示一致 (可用 `git commit -m <subject> -m <body>` 分段提交)

## 注意事项

- 未跟踪的新文件若属于本次变更应加入暂存区, 但 `git add` 前先与用户确认
- 不要提交与本次变更无关的文件
- 不要执行 `git push` (除非用户明确要求)
