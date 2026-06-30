# Tool 页面实现规范

## 使用时机

涉及 Tomako Tool 页面代码落地时读取本文件。它只说明当前项目怎么实现页面；产品、UI、物料、运行时、文案和上线验收分别看对应 P0 Gate。

## 架构原则

Tool 页面是代码模块，不是 MDX。

不要创建：

- `content/tools/*.mdx`
- `src/app/[locale]/tools/{slug}/page.tsx`
- 每个工具单独 route file

必须使用共享 detail dispatcher：

- `src/app/[locale]/tools/page.tsx`
- `src/app/[locale]/tools/[slug]/page.tsx`

## 新增页面文件

标准结构：

```text
src/features/tools/{slug}/
  {slug}.spec.ts
  {slug}.container.tsx

src/components/tools/
  {widget}.tsx
  registry.ts

src/i18n/messages/{zh,en}/tools/
  {tool-message-file}.ts
  index.ts
```

新增步骤：

1. 选择用户自然会访问的 kebab-case slug。
2. 添加 `src/features/tools/{slug}/{slug}.spec.ts`。
3. 添加 `src/features/tools/{slug}/{slug}.container.tsx`。
4. 有交互时添加 `src/components/tools/{widget}.tsx`。
5. 注册 `src/features/tools/registry.ts`。
6. 有 widget 时注册 `src/components/tools/registry.ts`。
7. 添加中英文 i18n messages，并在两个 locale 的 `tools/index.ts` 导出。
8. 有图片时放到 `public/tools/`，并按 `p0-asset-gates.md` 做页面渲染验收。
9. 按需运行 lint/build/MCP 生成，并检查桌面和移动端。

## ToolSpec

`ToolSpec` 负责 SEO/list metadata、状态、MCP、widget id 等，不承载正文文案。

常见字段：

```ts
slug: string;
status: "draft" | "review" | "published" | "deprecated";
toolType: "calculator" | "generator" | "analyzer";
locales: {
  zh: { title, description, intro?, category, keywords },
  en: { title, description, intro?, category, keywords },
};
seo: { publishedAt?, updatedAt, readingTime, featured?, ogImage? };
mcp?: { enabled: boolean; toolName?: string };
widget?: { id: string; mode: "custom" | "spec" };
```

规则：

- `locales` 只放 SEO/list metadata。
- 页面正文、FAQ、widget 文案放 i18n messages。
- `published` 只代表前端公开状态，不代表后端、Agent、Skills-OL 已生产就绪。
- draft/review/internal 不得被索引或推广。
- `mcp.enabled: true` 必须配 manifest、handler，并运行 MCP 生成。
- `updatedAt` 在能力、内容、运行时变化时要更新。

## Slug 与 review 路由

slug 要来自用户自然输入或分享的 URL，而不是内部 feature 名。

规则：

- 工具名可能对应多个英文 URL 时，先确认 public slug。
- 改名后加 alias 或 redirect，避免自然 URL 404。
- 测试 `/zh/tools/{slug}` 和 `/en/tools/{slug}`。
- 不要为了本地可访问而把未验证工具设为 `published`。
- review/draft 页面应能在本地、preview 或明确允许的 review 环境访问。
- review/draft 页面必须 `noindex, nofollow`，不进 sitemap，不进公开 tools index。

## Container

Container 负责页面组合：

- 使用 `ToolPageShell`。
- SEO/Tool 页顶部导航由 `ToolPageShell` 统一渲染共享官网导航组件，不在单个工具 container 或 widget 里手写导航。
- 导航源以本地当前前端源码为准，复用 `src/components/marketing/site-navigation.tsx` 和 `@/components/ui/navigation-menu`；不要复制线上已部署页面，也不要用只含“返回工具”的临时导航。
- `ToolPageShell` 调用共享导航时必须使用 Tool/SEO 页专用的 solid surface，让导航有独立背景；官网首页 Hero 仍可使用默认透明 surface。
- Tool 页 logo 链接到当前 locale 官网首页，主导航链接到官网首页锚点；除语言切换等基础状态外，不为具体工具页添加 active 选中态。
- immersive Hero 使用透明背景 PNG 配图，Hero 区域背景色默认 `#F7F6F2`。
- `ToolPageShell` 默认把 Hero 配图放在 1200px 容器范围内居右，并使用 `object-contain object-right` 与 `(min-width: 1200px) 1200px, 100vw` sizes；不要在单个工具里改回带背景色整图、`object-cover` 或无限铺满。
- 工具交互区放进 `ToolWorkspaceSection`。
- guide sections 通过 i18n messages 和 `getTranslations` 组合。
- CTA 在 container 内定义。
- MCP badge 通过 shell 展示，但不能放进顶部官网导航栏。
- 不重复写 route-level metadata。
- 不在 TSX 里硬编码中英双语正文。

## Widget

用户可以输入、生成、检查、复制、下载、提交时使用 widget。

必须：

- 复杂输入/输出用 `zod` schema，放在 `src/lib/tools/{slug}-schema.ts`。
- 校验只拦真正阻断任务的字段。
- 错误指向真实字段，不写泛泛“请填完整”。
- 拦截明显 placeholder、纯数字 brief、空 URL、demo 值。
- 支持 idle、loading、success、error、reset、disabled、mobile。
- 支持当前任务真正需要的状态。下载/转换/解析类要有无效输入、处理中、成功预览、下载动作、失败原因；生成/分析类要有等待、缺失信息、结构化结果、复制/下载/重试。
- 业务逻辑尽量从 JSX 拆出可测试函数。
- 使用 `@/components/ui` 控件。
- 表单 UI 遵守 `p0-ui-gates.md`。
- Agent-backed 结果遵守 `p0-runtime-gates.md`。

避免：

- route file 里藏业务逻辑。
- 组件里写中英双语对象。
- 复制别的 widget 布局但不检查移动端和输出长度。
- 表单里每个字段都堆 helper 和 icon。
- raw `<select>`、checkbox、radio、tab、button、menu。
- 大量标签墙。
- 复杂表单居中撑满。
- 结果放在表单同一个卡片背景里。
- icon-led 短生成按钮。
- 把内部技术方案评估、Agent 是否参与、LLM 是否参与写进普通用户 widget 的主要交互路径。

## i18n

文案位置：

| 内容 | 位置 |
| --- | --- |
| SEO/list metadata | `{slug}.spec.ts` 的 `locales.zh/en` |
| 页面正文、FAQ、widget labels、mock words | `src/i18n/messages/{locale}/tools/` |
| 共享短标签 | `toolsUi.*` 或 `toolsPages.shared` |

公开文案至少覆盖：

- title / description。
- 页面主标题和 intro。
- 表单 label 和 placeholder。
- 校验、错误、空、加载、成功状态。
- CTA。
- FAQ。

本地化必须按 locale 重写，不是逐字硬翻译。

## MCP 路径

当确定性逻辑需要被 AI client 或外部客户端调用时使用 MCP。

手写文件：

- `src/services/tools/manifests/{slug}.json`
- `src/services/tools/handlers/{handlerModule}.ts`
- ToolSpec 中 `mcp: { enabled: true }`

然后运行：

```bash
pnpm tools:generate-mcp
```

不要手改生成文件：

- `src/generated/tools-spec-catalog.json`
- `src/generated/mcp-tools-registry.json`
- `packages/foldos-mcp/src/registry.generated.ts`
- `content/mcp/{zh,en}/{slug}.mdx`
- `packages/foldos-mcp/README.md`

Handler 规则：

- 导出 `inputSchema` 和 `execute`。
- 使用 `zod`。
- 保持纯逻辑，不依赖 React。
- manifest schema 与 handler schema 保持一致。

## Online Agent 路径

当工具需要用户上下文、抓取、生成、判断、报告或长文档时，使用 online LLM task。

常见落点：

- `src/services/llm-task/`
- `src/features/{feature}/hooks/`
- `Skills-OL/skills/{skill-name}/SKILL.md`
- `Skills-OL/{skill-name}.mjs`

具体运行时要求看 `p0-runtime-gates.md`。

## 当前可参考案例

- `gtm-readiness-checklist`：ToolSpec + container + widget + MCP 的较完整样例。
- `product-name-generator`：Agent-backed 创意生成器，需要特别注意候选必须来自 Agent，不是 fallback。
- `logo-generator`：本地 deterministic 方向工具，只能参考低风险前端逻辑，不能复制到高上下文工具。

不要把 frontend-only 样例套到协议、隐私、政策、合规、品牌分析、URL 分析、创意判断或个性化生成工具上。

## 常见错误

- spec 写了但忘记 feature registry。
- widget 写了但忘记 widget registry。
- 正文写在 TSX 而不是 i18n。
- `mcp.enabled` 开了但没有 manifest/handler。
- 忘记运行 `pnpm tools:generate-mcp`。
- 手改生成 MCP 文档。
- 只因 route 404 就错误改成 `published`。
- 使用内部 slug，用户自然 slug 404。
- 用前端 fallback 掩盖 Agent 失败。
- sample/demo 数据进入生产结果。
- 请求 200、schema 有效、mock 渲染就宣称修复。
- repeated failure 时继续 UI 打磨，不查 runtime 链路。
