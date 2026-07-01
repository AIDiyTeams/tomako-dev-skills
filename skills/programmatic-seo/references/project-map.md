# 项目地图

## 使用时机

进入 Tomako workspace 做 Tool/SEO 页面前读取本文件。当前源码永远优先于文档；若文档和代码冲突，以代码为准并说明冲突。

## Workspace

根目录：

```text
/Users/ereneren/Downloads/workspace/Tomako Workspace
```

主要子项目：

- `Tomako/`：Next.js 前端，公开 SEO/Tool 页面。
- `Tomako-portal/`：Java/Spring Boot 后端，LLM task、skill-result API。
- `Skills-OL/`：cc-connect/Codex 运行时使用的在线 Skills 和脚本。
- `lark-product-monitor/`：飞书产品线索和 SEO 机会分析工具，曾作为 DataForSEO 参考实现；Tomako Tool 页面关键词查询不再要求跨项目运行。
- `designs/`：设计相关文件，当前按实际文件再确认。

工作区可能存在用户或其他 agent 的未提交改动。不要 revert 不属于自己的改动。

## Tomako 前端

技术栈：

- Next.js 16。
- React 19。
- TypeScript。
- Tailwind CSS v4。
- `next-intl`。
- `ky` API client。

核心路径：

- `src/app/[locale]/tools/page.tsx`：Tools index。
- `src/app/[locale]/tools/[slug]/page.tsx`：共享详情路由。
- `src/app/[locale]/blog/[slug]/page.tsx`：Blog MDX 详情路由。
- `src/app/[locale]/template/[slug]/page.tsx`：Template MDX 详情路由。
- `src/app/[locale]/mcp/[slug]/page.tsx`：MCP MDX 详情路由。
- `src/features/tools/registry.ts`：Tool module registry。
- `src/features/tools/types.ts`：`ToolSpec` 类型。
- `src/features/tools/{slug}/{slug}.spec.ts`：SEO/list metadata、状态、MCP、widget id。
- `src/features/tools/{slug}/{slug}.container.tsx`：页面组合。
- `src/features/tools/shared/`：shell、guide、CTA、MCP badge。
- `src/features/tools/shared/tool-content-sections.tsx`：Tool 页常见正文 section presets，例如价值、标准、场景、边界、FAQ、对比和卡片网格；优先复用但不强制套用。
- `src/components/tools/`：交互 widget 和 widget registry。
- `src/components/content/content-page-shell.tsx`：内容页产品化外壳。
- `src/components/content/content-explore-cta.tsx`：内容页相关工具/模板/下一步 CTA。
- `src/i18n/messages/{zh,en}/tools/`：页面正文、widget、FAQ。
- `src/lib/content/tools.ts`：ToolSpec 转 content entries 和 static params。
- `src/app/sitemap.ts`：sitemap 行为，发布前必须确认。
- `src/services/llm-task/`：前端 LLM task client。
- `src/app/api/[...path]/route.ts`：Next API proxy。
- `@/components/ui`：共享 UI 组件库，Tool widget 必须优先复用。

内容页路径：

- `content/blog/{zh,en}/{slug}.mdx`：Blog 内容页。
- `content/template/{zh,en}/{slug}.mdx`：Template 内容页。
- `content/mcp/{zh,en}/{slug}.mdx`：MCP 内容页。
- `content/_examples/`：示例副本，不参与公开路由。
- `src/lib/content/loader.ts`：MDX frontmatter 校验和加载。
- `src/lib/content/mdx-components.tsx`：MDX 渲染组件。
- `src/components/content/`：内容页 shell、CTA 和可复用内容组件。
- `docs/modules/marketing-content-mdx.md`：Blog / Template / MCP 落地规范。
- `docs/modules/blog-generate.md`：内部内容生成器说明。

重要项目文档：

- `docs/modules/interactive-tools.md`
- `docs/modules/marketing-content-mdx.md`
- `docs/modules/blog-generate.md`
- `docs/modules/tools-mcp-workflow.md`
- `docs/architecture/frontend-tool-spec.md`
- `docs/architecture/frontend-seo-metadata.md`
- `docs/architecture/frontend-i18n.md`
- `docs/architecture/frontend-module-boundaries.md`
- `docs/handoff/RELEASE_CHECKLIST.md`

注意：旧 `docs/modules/tools-ui-style-guide.md` 已拆分合并进 `programmatic-seo` 的 P0 Gate，不再作为独立规范来源。

## Tomako 前端已知事实

- Tool 页面采用 code-first，不使用 MDX tool page。
- 详情页由共享 dispatcher 负责，不为每个 tool 新建 route。
- Blog / Template / MCP 内容页采用 MDX，通常新增或修改 `content/{kind}/{locale}/{slug}.mdx`，不为每篇内容新建 route。
- MDX 只负责内容，不代表完整页面 UI；内容页应通过共享 Content Shell / MDX components 呈现产品化 Hero、阅读布局、CTA、侧栏和正文样式。
- 内容页 frontmatter 必填 `title`、`description`、`category`、`keywords`、`updatedAt`、`readingTime`；`keywords` 必须是数组。
- 面向 SEO 的内容页可用 `seoCluster`、`parentToolSlug`、`primaryKeyword`、`pageIntent`、`conversionTarget` 和 `indexable` 管理主题簇、父工具、主关键词、转化承接和索引边界。
- 当前 sitemap 包含首页、Tools index、published Tools，以及 `indexable !== false` 的 Blog / MCP 内容页。
- 内容页站内链接不要写 `/{locale}/` 前缀。
- 内容页图片放到 `public/`，不要只放在 `content/` 下。
- `published` 只代表前端状态，不等于生产 Agent/后端链路就绪。
- 本地 `/api/...` 可能通过 `API_PROXY_TARGET` 代理到生产或其他上游。
- 一些旧文档可能仍说页面是 frontend/mock；以当前源码和本 Skill Gate 为准。

## Tomako-portal 后端

技术栈：

- Maven multi-module。
- Java/Spring Boot。

关键模块：

- `web-portal-adapt`
- `web-portal-domain`
- `web-portal-infra`
- `web-portal-api`
- `web-portal-server`

LLM task 相关路径按实际源码搜索：

- `LlmTaskController.java`
- `LlmTaskEventStreamController.java`
- `LlmTaskWsHandler.java`
- `SkillResultController.java`
- `LlmTaskApplicationService.java`
- `LlmTaskEventRouter.java`
- `SkillResultDO.java`
- `JpaSkillResultRepository.java`

主要 API：

- `POST /api/llm/tasks`
- `GET /api/llm/tasks/{taskId}`
- `GET /api/llm/tasks/{taskId}/turns`
- `GET /api/llm/tasks/{taskId}/events`
- `POST /api/llm/tasks/{taskId}/messages`
- `POST /api/llm/tasks/{taskId}/confirm`
- `POST /api/skill-results`
- `GET /api/skill-results/{taskId}`
- `WS /ws/llm?taskIds=...`

状态模型：

```text
PENDING -> STREAMING -> AWAITING_INPUT -> SUCCEEDED
any -> FAILED
```

`AWAITING_INPUT` 不等于失败。Skill Result 可能在 task 仍为 `AWAITING_INPUT` 时已经可读。

## Skills-OL

用途：在线 Skill 仓库，部署到 cc-connect/Codex 运行目录。

关键文件：

- `CONTRIBUTING.md`
- `docs/llm-task-deployment-guide.md`
- `skills/result-writer/SKILL.md`
- `skills/brand-crawl-eval/SKILL.md`
- `brand-crawl.mjs`
- `skills/llm-task-deployer/SKILL.md`

涉及新 Skill、新脚本、脚本参数、写回逻辑、resultType 或依赖变更时，必须读取 `docs/llm-task-deployment-guide.md`。本地 `Skills-OL/` 文件变更和 Git push 不等于 cc-connect runtime 已更新；必须确认服务器 `~/Skills-OL` 已拉取目标 commit，并且 `cc-connect` 已重启或明确不需要重启。

结构化写回契约：

```json
{
  "taskId": "llm-...",
  "skillName": "my-skill",
  "resultType": "my_result_type",
  "sourceUrl": "https://example.com",
  "resultJson": {},
  "summary": "..."
}
```

Agent 回复应简短，不粘贴完整 JSON。

## Tomako 本地 SEO Brief / DataForSEO

用途：为 Tomako SEO 页面沉淀可复用的关键词证据。标准入口位于 Tomako repo 内，不放到浏览器前端，也不暴露给 Next client。

可用命令：

```bash
pnpm seo:keyword-brief -- --slug <tool-slug> --keyword "primary keyword"
pnpm seo:keyword-brief -- --slug <tool-slug> --keyword "primary keyword" --refresh
```

代码位置：

```text
Tomako/scripts/seo-keyword-brief.mjs
```

结果位置：

```text
Tomako/docs/seo-keyword-briefs/{tool-slug}.md
Tomako/docs/seo-keyword-briefs/{tool-slug}.json
```

当前能力：

- Google Ads Search Volume Live：月搜索量、CPC、付费竞争度。
- Google Organic SERP Live Advanced：SERP Top 10 摘要。

环境变量：

```text
DATAFORSEO_LOGIN
DATAFORSEO_PASSWORD
```

脚本会读取 Tomako 项目根目录的 `.env` 和 `.env.local`，但真实密钥不能提交到 Git。

使用约束：

- DataForSEO 是付费数据源，SEO 页面开工前应先基于上下文筛出高置信关键词，再查询。
- 查询数量按实际场景决定，不设固定默认数量；CLI 单次硬上限是 50 个关键词。上下文不足时先问问题或写明假设，不调用 API。
- 不要只依赖 slug 自动推词。先在对话框给出候选关键词小表，再把最高置信的关键词通过 `--keyword` 传给 CLI。
- 当前不包含 Ahrefs/Semrush KD 和页面自然流量，DataForSEO 结果只能作为部分 SEO 证据。
- `docs/seo-keyword-briefs/{slug}.md` 和 `.json` 可以提交到 Git；密钥、`.env` 和不想公开的原始 provider 响应不能提交。
- 若已有 brief 且工具范围、目标市场和时间没有明显变化，优先复用，不重复刷新。
- 无密钥时标准命令不会写入可提交 brief。只有明确需要临时占位时才使用 `--scaffold`，并且不能把 scaffold 当成正式数据证据。
- `lark-product-monitor/src/monitor.mjs` 只作为历史实现参考，不作为 Tomako Skill 的标准运行入口。

## 冲突处理优先级

1. 当前 `Tomako`、`Tomako-portal`、`Skills-OL` 源码。
2. `programmatic-seo` 的 P0 Gate。
3. 当前项目 architecture/module docs。
4. handoff/release docs。
5. 旧 README 或历史文档。

涉及上线时，必须说明观察到的代码/文档/生产状态不一致。

如果页面需要真实 Agent/LLM 才能测试，必须同时说明 Tomako 前端、Tomako-portal 后端、Skills-OL 和 cc-connect 的目标环境状态。任何一层未部署或版本未知，都不能宣称页面可测试或完成。
