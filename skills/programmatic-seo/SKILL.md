---
name: programmatic-seo
description: Build, review, or debug Tomako programmatic SEO tool pages end-to-end, including requirement discovery, default cloud Agent/LLM task decisions, ToolSpec/registry/i18n/widget work, visual assets, SEO content and FAQ, MCP tool generation, online Skills-OL integration, async skill-result state machines, review routing, slug aliases, URL-to-result flows, launch QA, and production readiness for Tomako/Foldos tool pages.
---

# 程序化 SEO Skill

本 Skill 是 Tomako 程序化 SEO 工具页面的总入口。它不只是文档目录，而是一个强制读取、任务路由和验收调度器。每次新建、修复、复盘或发布 Tool/SEO 页面，都必须先读取本文件，再按下面的阅读协议读取关联 MD。

## 三层机制

1. **入口层：`SKILL.md`**  
   判断任务类型，建立“已读/未读”状态表，决定读取顺序，并在交付前检查是否补读完整。

2. **规则层：`references/*.md`**  
   所有 P0 规则、执行流程、验收清单都放在一层 references 文件中。不要依赖深层跳转。

3. **验收层：读后自检 + 真实验证**  
   开发前先读规则；开发中按问题补读；交付前必须回到未读列表补齐，并说明哪些 Gate 已检查。

## 阅读状态协议

读取本 Skill 后，必须在当前对话上下文中维护一张“阅读状态表”。这张表只存在于对话里，不写入项目文件。

格式建议：

```text
阅读状态：
- [x] SKILL.md
- [ ] references/p0-page-brief.md
- [ ] references/p0-content-gates.md
- [ ] references/p0-ui-gates.md
- [ ] references/p0-asset-gates.md
- [ ] references/p0-runtime-gates.md
- [ ] references/p0-launch-checklist.md
- [ ] references/tool-page-implementation.md
- [ ] references/project-map.md
- [ ] references/tool-retro-template.md（仅复盘时必读）
```

执行规则：

- 0 到 1 新页面、重大重构、上线前验收：必须完整读取所有必读 MD，再开始真正实现或最终验收。
- 处理中途临时查 Skill：先读和当前问题最相关的文件，记录未读项；在诊断或交付前补读剩余必读文件。
- 只做小问题定位：可以先读相关 Gate，但不能把局部修复包装成“完整页面已完成”，除非补齐全量阅读和验收。
- 每次最终答复前，必须说明已读哪些 Gate、哪些检查通过、哪些仍是风险或未验证项。

## 必读文件与读取顺序

新建或重做 Tool 页面时，按顺序读取：

1. [p0-page-brief.md](references/p0-page-brief.md)：开工前需求、输入输出、搜索意图和范围确认。
2. [p0-content-gates.md](references/p0-content-gates.md)：先从用户视角、SEO 增长视角和文案视角确定信息架构、模块清单、价值表达和疑问覆盖。
3. [project-map.md](references/project-map.md)：当前 Tomako / Tomako-portal / Skills-OL 项目结构。
4. [p0-runtime-gates.md](references/p0-runtime-gates.md)：是否需要后端、Agent、LLM Task、Skills-OL、Skill Result。
5. [tool-page-implementation.md](references/tool-page-implementation.md)：ToolSpec、container、widget、i18n、registry、组件库和代码落点。
6. [p0-ui-gates.md](references/p0-ui-gates.md)：基于已确定的信息模块，设计表单、布局、交互、响应式和 UI 呈现。
7. [p0-asset-gates.md](references/p0-asset-gates.md)：围绕已确定的价值模块和疑问模块生成视觉图、生图和 before/after 物料。
8. [p0-launch-checklist.md](references/p0-launch-checklist.md)：发布、索引、路由、构建、浏览器 QA 和风险记录。

按任务类型优先读取：

- 需求不清、新页面开工：先读 `p0-page-brief.md`。
- 完整页面诊断、SEO 优化、页面重做：先读 `p0-content-gates.md`，确定信息和文案模块，再读 `p0-ui-gates.md` 做呈现。
- UI、表单、布局、组件、移动端：先读 `p0-ui-gates.md` 和 `tool-page-implementation.md`；若涉及整页结构或模块取舍，必须补读 `p0-content-gates.md`。
- 配图、生图、Hero、视觉物料：先读 `p0-asset-gates.md`。
- 后端、Agent、LLM Task、Skills-OL、异步状态、结果不对：先读 `p0-runtime-gates.md`。
- SEO 文案、FAQ、metadata、页面模块：先读 `p0-content-gates.md`。
- 上线、published、sitemap、noindex、验收：先读 `p0-launch-checklist.md`。
- 复盘和 Skill 自进化：先读 [tool-retro-template.md](references/tool-retro-template.md)，再抽象通用规则。

## 开工前必须确认

任何新页面都先确认三个问题，不能直接脑补：

1. 用户是谁，为什么会搜这个工具。
2. 用户输入什么，允许多粗糙，哪些信息第一轮必须要。
3. 页面或 Agent 输出什么，输出要怎样才算有用。

不需要把需求问成完整 PRD。先拿到足够决定架构、输入输出、风险边界和第一版价值的信息。如果输入、输出、运行时或风险边界仍影响实现，问 2 到 5 个短问题；如果用户要求先做草案，必须写明假设。

## 内容先行流程

新建、重做、优化或诊断 SEO Tool 页面时，第一优先级不是 UI，而是从用户视角和 SEO 增长视角确认页面应该回答哪些问题、展示哪些价值、覆盖哪些搜索需求。

强制顺序：

1. 先确认用户意图、输入、输出、搜索需求和用户疑虑。
2. 再列出页面必须包含的信息模块和每个模块的目的。
3. 再决定哪些信息放首屏、工作台附近、结果区、说明区、FAQ 或 CTA。
4. 最后才进入 UI、布局、视觉物料和组件实现。

禁止先套两栏、卡片、Hero、FAQ 或视觉模板，再倒推文案。UI 的职责是把已经确认的信息更清晰、更有吸引力地呈现出来；如果信息模块不清楚，必须回到 `p0-content-gates.md` 补齐，而不是继续调样式。

## 总体判断

默认判断：大多数 Tomako Tool 页面需要后端、云端 Agent、LLM Task、URL/文档抓取、分析、生成或结构化写回。纯前端只适合明确低风险、确定性、自包含的计算器、转换器、格式化器或清楚标注的本地 demo。

当前代码优先级最高。若文档和代码冲突，以 `Tomako`、`Tomako-portal`、`Skills-OL` 当前源码为准，并在答复中说明冲突。

## 交付前答复要求

最终答复必须简短说明：

- 读取了哪些 Gate 文件。
- 改了哪些文件或做了哪些诊断。
- 跑了哪些验证。
- 远端部署状态：已部署并验证、无需部署，或明确阻塞。
- 哪些生产风险仍未验证，例如后端、cc-connect、Skills-OL 部署、sitemap、真实 Agent 返回。

不要因为 UI 看起来完成、请求返回 200、schema 能 parse、mock 能渲染，就宣称页面完成。必须按照对应 Gate 验收真实用户价值。

Agent-backed 工具还必须完成远端运行时闭环：如果改了前端 LLM task service、后端、Skills-OL、cc-connect、schema、resultType 或环境变量，就要确认目标环境已部署/重启并跑 live QA；如果无法部署，必须把它作为 blocker 明说，不能把页面说成可测试或完成。

## 常用命令

在 `Tomako/` 下按需运行：

```bash
pnpm lint
pnpm build
pnpm tools:generate-mcp
pnpm tools:mcp
```

在 `Tomako-portal/` 下按需运行：

```bash
./mvnw test
./mvnw clean package -Dmaven.test.skip=true
```

在 `Skills-OL/` 下按需验证在线 Skill 和脚本。
