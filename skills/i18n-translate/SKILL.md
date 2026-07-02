---
name: i18n-translate
description: Batch-translate Tomako-style next-intl TypeScript message modules across apps. Use when the user invokes $i18n-translate, $翻译, asks to add languages/locales, generate missing src/i18n/messages files, resume interrupted translation, or move i18n translation automation into tomako-dev-skills for cross-application reuse.
---

# Tomako i18n 批量翻译 Skill

本 Skill 将 `src/i18n/messages` 下的 TypeScript 文案模块批量翻译到目标 locale，支持断点缓存、OpenCC 简繁转换、OpenAI provider、Google Translate provider。默认以目标应用项目根目录为工作目录，适合 `Tomako/` 以及沿用同一 messages 结构的其他前端应用。

触发词：`$i18n-translate`、`$翻译`、新增语种、补齐多语言、继续翻译、翻译 messages。

## 支持的项目结构

目标应用需有：

```text
src/i18n/messages/
  en/
  zh/
```

消息模块约定为 `export default ... as const` 的 `.ts` 文件。脚本会跳过 `index.ts`，翻译实际叶子模块，再复制 `index.ts` 聚合文件到目标 locale。

## 执行协议

1. 确认目标应用目录，默认优先 `Tomako-FE/`；其他应用用 `--project /abs/path/to/app`。
2. 先查看 `src/i18n/routing.ts`、`src/constants/languages.ts`、`src/i18n/request.ts`，区分“已生成 messages”和“已开放切换”。
3. 优先使用 OpenAI provider；没有 `OPENAI_API_KEY` 时只能用 Google provider，可能触发 429。
4. 默认不覆盖已存在目标文件；继续中断任务时直接重跑同一命令。
5. 翻译完成后，再把完整 locale 接入 `request.ts` 和语言选择器；未完整生成前不要开放切换。

## 常用命令

在 `tomako-workspace` 根目录：

```bash
export OPENAI_API_KEY=...

# 翻译单个 locale，断点续跑
./tomako-dev-skills/skills/i18n-translate/scripts/translate-messages.sh \
  --project ./Tomako-FE \
  --provider=openai \
  --locale es

# 翻译全部配置内 locale
./tomako-dev-skills/skills/i18n-translate/scripts/translate-messages.sh \
  --project ./Tomako-FE \
  --provider=openai

# 只检查待生成模块，不请求翻译接口
./tomako-dev-skills/skills/i18n-translate/scripts/translate-messages.sh \
  --project ./Tomako-FE \
  --provider=openai \
  --locale es \
  --dry-run
```

在目标应用目录内也可以省略 `--project`：

```bash
cd Tomako
../tomako-dev-skills/skills/i18n-translate/scripts/translate-messages.sh --provider=openai --locale es
```

Tomako 前端保留兼容 npm 命令：

```bash
cd Tomako
OPENAI_API_KEY=... pnpm i18n:translate:openai -- --locale es
```

## Provider 与缓存

- `--provider=auto`：默认；有 `OPENAI_API_KEY` 时走 OpenAI，否则走 Google。
- `--provider=openai`：稳定批量翻译，推荐用于大量页面和工具文案。
- `--provider=google`：免费兜底，可能因 429 中断。
- `OPENAI_TRANSLATION_MODEL`：可覆盖默认模型。
- 缓存写入目标应用的 `.i18n/translation-cache.json`，同一文本同一目标语种不会重复请求。

## 交付前答复要求

- 说明目标应用目录、目标 locale、provider。
- 说明生成了哪些 locale，哪些仍未完成。
- 如果只生成 messages 但未接入 `request.ts` / 语言选择器，明确说“尚未开放切换”。
- 若因缺少 `OPENAI_API_KEY` 或 provider 限流中断，给出可续跑命令。
