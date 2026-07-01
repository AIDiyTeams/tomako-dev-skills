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

## 页面模块复用与自定义判断

Tool 页面不是每次从零写所有 section。先完成 `p0-content-gates.md` 的信息模块清单，再为每个模块做复用决策。

当前优先复用：

- `src/features/tools/shared/tool-page-shell.tsx`：页面外壳、导航、Hero、JSON-LD。
- `src/features/tools/shared/tool-guide-section.tsx`：工作台区、图文区、图片视觉。
- `src/features/tools/shared/tool-content-sections.tsx`：价值、好标准、适用场景、边界、FAQ、对比、卡片网格等常见正文模块。
- `src/features/tools/shared/tool-cta.tsx`：底部 CTA。
- `@/components/ui`：表单、按钮、下拉、弹层、tab、checkbox、radio 等基础控件。

决策规则：

- 共享模块能准确承载当前信息、视觉上限足够、不会制造重复表达时，优先复用。
- 共享模块只差轻微文案、顺序、图片或 children 组合时，使用组合方式解决，不复制一份本地组件。
- 共享模块会迫使页面变成错误结构时，必须自定义。例如：左右两侧重复讲同一件事、结果区被压窄、价值模块变成流程说明、表单被迫复杂、视觉图无法表达当前场景。
- 自定义开发不是例外失败，而是正常选项。先在当前 container/widget 内实现；如果同类结构在两个以上页面稳定复现，再抽成共享组件。
- 不要从另一个 Tool container 复制局部 section 后只改名字。要么引用共享模块，要么基于当前信息架构重新写清楚。
- 交付说明中写明：复用了哪些共享模块，哪些模块自定义，为什么没有复用模板库。

模板库的目标是提高效率和一致性，不是限制页面上限。最终判断以用户价值、疑问覆盖、交互可用性和视觉效果为准。

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
- 表单、横向选择器、图片、结果卡和两栏布局必须有明确边界约束。grid/flex 子项按需加 `min-w-0`，控件和卡片加 `max-w-full`，横向轨道只能在自身容器内 `overflow-x-auto`，不能撑破页面或覆盖相邻字段。

避免：

- route file 里藏业务逻辑。
- 组件里写中英双语对象。
- 复制别的 widget 布局但不检查移动端和输出长度。
- 表单里每个字段都堆 helper 和 icon。
- raw `<select>`、checkbox、radio、tab、button、menu。
- 大量标签墙。
- 超宽风格/Type/模板选择器直接撑出表单列。
- 右侧视觉、图片或 absolute 装饰覆盖左侧输入控件。
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

只要本轮修改了 `Skills-OL/` 对应功能的 Agent Skill、脚本、prompt、resultType、schema 或写回字段，完成代码修改后的默认下一步就是执行 `$deploy-skills-ol` 部署闭环。无法自动部署时，必须主动询问用户是否部署或标为 blocker，不能继续用云端旧 Agent 结果判断新逻辑。

长报告 / 渐进式 Agent Tool 额外检查：

- 新增或改名 LLM task service 后，如果前端从 `@/services/llm-task` barrel import，必须同步更新 `src/services/llm-task/index.ts`。
- schema 要能区分 partial/final；normalizer 能接受 partial 缺省字段，final 再做完整字段要求。
- 结果组件支持 `completedSections`、`inProgressSection` 或等价字段，并按用户可见模块渲染。
- partial/final 的 `resultType`、slug、scene、Skill script 不与旧工具误复用；如需迁移，保留兼容并写清风险。
- Skills-OL 脚本尽量校验 partial 顺序、一次新增粒度和 schema，不只依赖 prompt。
- 完成前至少运行 `pnpm exec tsc --noEmit --pretty false`；不要只依赖浏览器热更新、局部 lint 或 mock 渲染。

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
- 每个 Tool 页面都重复手写 FAQ、场景、边界、价值卡片等通用 section，而不是先评估共享模块。
- 为了套共享模块保留无价值、重复或关系不清的 section。
- 没有检查 `document.documentElement.scrollWidth > document.documentElement.clientWidth`，导致桌面或移动端出现意外横向滚动。
- 横向选择器只写“可左右滑动”，但没有把滚动限制在内部轨道。
- 新增 LLM task service 后忘记从 `src/services/llm-task/index.ts` 导出，导致构建或运行时引用失败。
- 渐进式结果只在 prompt 里要求，没有在 schema、normalizer、UI 状态机和 Skills-OL 脚本里形成闭环。
- partial 已经出现后，final 超时或 SSE 抖动把整页切成失败并清空已完成内容。
- 只跑 dev server 或页面点击通过，没有运行 `tsc --noEmit`，遗漏 import/export 或类型问题。
