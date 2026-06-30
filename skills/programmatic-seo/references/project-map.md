# 项目地图

## 使用时机

进入 Tomako workspace 做 Tool/SEO 页面前读取本文件。当前源码永远优先于文档；若文档和代码冲突，以代码为准并说明冲突。

## Workspace

**工作区根目录**（文件夹名称自定）：包含 `Tomako/`、`Tomako-portal/`、`tomako-dev-skills/` 的 multi-repo 目录。在 Cursor / Claude Code / Codex 中打开此根目录，不要只打开 `Tomako/` 子目录。

识别方式：若当前目录下同时存在上述三个子目录，即视为工作区根；下文路径均相对该根目录。

工程协作 Skills：运行 `./tomako-dev-skills/install.sh` 将 skills 链接到各 Agent 平台目录（如 `.cursor/skills/`、`.claude/skills/`、`.codex/skills/`）。

主要子项目：

- `Tomako/`：Next.js 前端，公开 SEO/Tool 页面。
- `Tomako-portal/`：Java/Spring Boot 后端，LLM task、skill-result API。
- `Skills-OL/`：cc-connect/Codex 运行时使用的在线 Skills 和脚本（常见，非必需）。
- `tomako-dev-skills/`：程序化 SEO、部署等工程 Skills 与脚本。

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
- `src/features/tools/registry.ts`：Tool module registry（P0：新建页面必须在此注册，否则 `/tools` 列表、详情路由、`generateStaticParams` 均不可用）。
- `src/features/tools/types.ts`：`ToolSpec` 类型。
- `src/features/tools/{slug}/{slug}.spec.ts`：SEO/list metadata、状态、MCP、widget id。
- `src/features/tools/{slug}/{slug}.container.tsx`：页面组合。
- `src/features/tools/shared/`：shell、guide、CTA、MCP badge。
- `src/components/tools/`：交互 widget 和 widget registry。
- `src/i18n/messages/{zh,en}/tools/`：页面正文、widget、FAQ。
- `src/lib/content/tools.ts`：ToolSpec 转 content entries 和 static params。
- `src/app/sitemap.ts`：sitemap 行为，发布前必须确认。
- `src/services/llm-task/`：前端 LLM task client。
- `src/app/api/[...path]/route.ts`：Next API proxy。
- `@/components/ui`：共享 UI 组件库，Tool widget 必须优先复用。

重要项目文档：

- `docs/modules/interactive-tools.md`
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

## 冲突处理优先级

1. 当前 `Tomako`、`Tomako-portal`、`Skills-OL` 源码。
2. `programmatic-seo` 的 P0 Gate。
3. 当前项目 architecture/module docs。
4. handoff/release docs。
5. 旧 README 或历史文档。

涉及上线时，必须说明观察到的代码/文档/生产状态不一致。
