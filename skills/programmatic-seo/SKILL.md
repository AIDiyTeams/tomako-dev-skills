---
name: programmatic-seo
description: Build, review, or debug Tomako programmatic SEO pages end-to-end, including interactive Tool pages, MDX Blog/Template/MCP content pages, content hubs, keyword evidence and SEO copy calibration, DataForSEO-backed keyword briefs, requirement discovery, default cloud Agent/LLM task decisions, ToolSpec/registry/i18n/widget work, visual assets, SEO content and FAQ, online Skills-OL integration, async skill-result state machines, review routing, slug aliases, MDX/frontmatter/internal-link work, launch QA, and production readiness for Tomako/Foldos SEO pages.
---

# 程序化 SEO Skill

本 Skill 是 Tomako 程序化 SEO 页面的总入口，覆盖两条路线：

- **Tool Page**：可交互工具页，代码落点在 `src/features/tools/`，通常包含 widget、Agent/LLM、结果区和生图物料。
- **Content Page**：内容型 SEO 页，当前主要落点在 `content/blog/`、`content/template/`、`content/mcp/`，用于教程、清单、对比、模板、解释型内容和内容集群，并由共享 Content Shell / MDX 组件负责产品化呈现。

它不只是文档目录，而是一个强制读取、任务路由和验收调度器。每次新建、修复、复盘或发布 SEO 页面，都必须先读取本文件，再按下面的阅读协议读取关联 MD。

## 三层机制

1. **入口层：`SKILL.md`**  
   判断任务类型，建立“已读/未读”状态表，决定读取顺序，并在交付前检查是否补读完整。

2. **规则层：`references/*.md`**  
   所有 P0 规则、执行流程、验收清单都放在一层 references 文件中。不要依赖深层跳转。

3. **验收层：读后自检 + 真实验证**  
   开发前先读规则；开发中按问题补读；交付前必须回到未读列表补齐，并说明哪些 Gate 已检查。

## Agent Skill 修改后必须部署

这是超强 P0 规则。

只要本轮改动触碰 `Skills-OL/` 中对应功能的在线 Agent Skill、脚本、prompt strategy、result writer、resultType、schema 或依赖，即使只是改了几句 prompt，也必须把 Skills-OL 部署到 cc-connect 运行环境后再继续真实测试。

原因：当前开发环境通常是本地前端连接云端 Agent。本地改了 `Skills-OL/` 文件，如果不部署，云端 Agent 仍然运行旧版本。继续反复测试只是在测试旧逻辑，会浪费大量排查时间。

执行规则：

- 修改 `Skills-OL/` 后，默认下一步就是部署：按 `$deploy-skills-ol` / `deploy-skills-ol` 流程执行 `git pull`、依赖安装和 cc-connect 重启。
- 如果部署流程要求先 push 到 Git，必须确认对应改动已 push；未 push 时不能假装部署生效。
- 如果有权限、密钥、发布窗口或风险原因导致不能自动部署，必须主动询问用户是否部署，或把“未部署”标为 blocker。
- 未部署时不能宣称 Agent 效果已修复、页面可测试或功能完成。
- 部署后必须记录本地/远端 commit、是否重启 cc-connect、部署结果和至少一次真实 live QA。

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
- [ ] references/p0-content-page-brief.md（内容页任务必读）
- [ ] references/p0-content-page-structure-gates.md（内容页任务必读）
- [ ] references/p0-content-page-writing-gates.md（内容页任务必读）
- [ ] references/p0-content-page-ui-gates.md（内容页任务必读）
- [ ] references/content-page-implementation.md（内容页任务必读）
- [ ] references/project-map.md
- [ ] references/tool-retro-template.md（仅复盘时必读）
```

执行规则：

- 0 到 1 新页面、重大重构、上线前验收：必须完整读取所有必读 MD，再开始真正实现或最终验收。
- 处理中途临时查 Skill：先读和当前问题最相关的文件，记录未读项；在诊断或交付前补读剩余必读文件。
- 只做小问题定位：可以先读相关 Gate，但不能把局部修复包装成“完整页面已完成”，除非补齐全量阅读和验收。
- 每次最终答复前，必须说明已读哪些 Gate、哪些检查通过、哪些仍是风险或未验证项。

## 页面类型路由

先判断任务属于哪一类，再读取对应路线。不要把 Tool 页面规范强行套到纯内容页，也不要把内容页写法套到需要真实交互和运行时闭环的工具页。

| 任务 | 判断标准 | 主要读取路线 |
| --- | --- | --- |
| Tool Page | 用户要输入 URL、文本、文件或业务信息，并得到生成、分析、下载、评分、报告或可操作结果 | Tool 页面路线 |
| Content Page | 页面主要靠可抓取正文解决搜索问题，没有核心交互 widget，通常是 blog/template/mcp MDX | 内容页路线 |
| 内容集群 / 批量选题 | 目标是规划大量文章、模板页、解释页、对比页或 hub-spoke | 内容页路线 + `p0-content-gates.md` |
| 现有页面文案校准 | 目标是让页面更符合关键词、用户需求和数据证据 | 先读 `p0-content-gates.md`；Tool 页再补 Tool 路线，内容页再补内容页路线 |
| 技术 SEO / 上线检查 | 目标是路由、索引、sitemap、canonical、hreflang、部署或 QA | `p0-launch-checklist.md` + `project-map.md` |

## Tool 页面必读顺序

新建或重做 Tool 页面时，按顺序读取：

1. [p0-page-brief.md](references/p0-page-brief.md)：开工前需求、输入输出、搜索意图和范围确认。
2. [p0-content-gates.md](references/p0-content-gates.md)：先从用户视角、SEO 增长视角和文案视角确定信息架构、模块清单、价值表达和疑问覆盖。
3. [project-map.md](references/project-map.md)：当前 Tomako / Tomako-portal / Skills-OL 项目结构。
4. [p0-runtime-gates.md](references/p0-runtime-gates.md)：是否需要后端、Agent、LLM Task、Skills-OL、Skill Result。
5. [tool-page-implementation.md](references/tool-page-implementation.md)：ToolSpec、container、widget、i18n、registry、组件库和代码落点。
6. [p0-ui-gates.md](references/p0-ui-gates.md)：基于已确定的信息模块，设计表单、布局、交互、响应式和 UI 呈现。
7. [p0-asset-gates.md](references/p0-asset-gates.md)：围绕已确定的价值模块和疑问模块生成视觉图、生图和 before/after 物料。
8. [p0-launch-checklist.md](references/p0-launch-checklist.md)：发布、索引、路由、构建、浏览器 QA 和风险记录。

## 内容页必读顺序

新建、重写、批量规划或校准 Blog / Template / MCP 内容页时，按顺序读取：

1. [p0-page-brief.md](references/p0-page-brief.md)：确认用户、搜索意图、页面目标、关键词证据和发布边界。
2. [p0-content-gates.md](references/p0-content-gates.md)：先确定用户需求、关键词证据、Copy Brief、信息模块和价值表达。
3. [p0-content-page-brief.md](references/p0-content-page-brief.md)：确定内容页类型、读者任务、漏斗阶段、内容承诺、集群关系和转化承接。
4. [p0-content-page-structure-gates.md](references/p0-content-page-structure-gates.md)：按页面类型选择结构，避免薄内容、重复内容和孤立页面。
5. [p0-content-page-writing-gates.md](references/p0-content-page-writing-gates.md)：写作质量、信息增益、E-E-A-T、来源、示例、FAQ 和反 AI 味检查。
6. [p0-content-page-ui-gates.md](references/p0-content-page-ui-gates.md)：确定内容页共享 shell、Hero、阅读布局、CTA、侧栏和 MDX 组件呈现。
7. [project-map.md](references/project-map.md)：确认 Tomako 当前 MDX 路由、content 目录、frontmatter、内链和 sitemap 事实。
8. [content-page-implementation.md](references/content-page-implementation.md)：按 Tomako MDX 规范和共享 Content Shell 落地 blog/template/mcp 页面。
9. [p0-asset-gates.md](references/p0-asset-gates.md)：当内容页需要 Hero 图、正文图、模板预览或原创图片时读取。
10. [p0-launch-checklist.md](references/p0-launch-checklist.md)：发布、索引、构建、双语、内链、图片和风险记录。

按任务类型优先读取：

- 需求不清、新页面开工：先读 `p0-page-brief.md`。
- 完整页面诊断、SEO 优化、页面重做：先读 `p0-content-gates.md`，确定信息和文案模块；Tool 页再读 `p0-ui-gates.md`，内容页再读 `p0-content-page-ui-gates.md` 做呈现。
- UI、表单、布局、组件、移动端：Tool 页先读 `p0-ui-gates.md` 和 `tool-page-implementation.md`；内容页先读 `p0-content-page-ui-gates.md` 和 `content-page-implementation.md`；若涉及整页结构或模块取舍，必须补读 `p0-content-gates.md`。
- 配图、生图、Hero、视觉物料：先读 `p0-asset-gates.md`。
- 后端、Agent、LLM Task、Skills-OL、异步状态、结果不对：先读 `p0-runtime-gates.md`。
- SEO 文案、FAQ、metadata、页面模块：先读 `p0-content-gates.md`；若是内容页，再补读内容页三份 P0 Gate。
- 上线、published、sitemap、noindex、验收：先读 `p0-launch-checklist.md`。
- 复盘和 Skill 自进化：先读 [tool-retro-template.md](references/tool-retro-template.md)，再抽象通用规则。

## 开工前必须确认

任何新页面都先确认三个问题，不能直接脑补：

1. 用户是谁，为什么会搜这个工具。
2. 用户输入什么，允许多粗糙，哪些信息第一轮必须要。
3. 页面或 Agent 输出什么，输出要怎样才算有用。

不需要把需求问成完整 PRD。先拿到足够决定架构、输入输出、风险边界和第一版价值的信息。如果输入、输出、运行时或风险边界仍影响实现，问 2 到 5 个短问题；如果用户要求先做草案，必须写明假设。

## 内容先行流程

新建、重做、优化、诊断或单独校准 SEO 页面文案时，第一优先级不是 UI，而是从用户视角和 SEO 增长视角确认页面应该回答哪些问题、展示哪些价值、覆盖哪些搜索需求。

强制顺序：

1. 先确认用户意图、输入、输出、搜索需求和用户疑虑，并在对话框返回需求摘要。
2. 再做关键词假设，输出候选关键词小表。
3. 先查 `Tomako/docs/seo-keyword-briefs/{slug}.md` 或 `.json` 是否已有可复用 Keyword Evidence Brief。
4. 若没有 brief 且 DataForSEO 可用、上下文足够，在 `Tomako/` 使用本地 CLI 查询高置信关键词：`pnpm seo:keyword-brief -- --slug <tool-slug> --keyword "primary keyword"`。查询数量按实际场景决定，受 CLI 单次上限保护；不要跨到 `lark-product-monitor` 执行查询，后者只作为历史参考。
5. 基于 Copy Brief 和 Keyword Evidence Brief 编写页面文案与信息模块清单；内容页还要明确内容类型、集群角色、唯一信息增益和内链计划。
6. 如果是已有页面文案校准，先对照当前页面找出关键词缺口、用户价值缺口、疑问覆盖缺口和不应保留的模块，再修改文案和模块。
7. 再决定哪些信息放首屏、工作台附近、结果区、说明区、FAQ 或 CTA。
8. 最后才进入 UI、布局、视觉物料和组件实现。

禁止先套两栏、卡片、Hero、FAQ 或视觉模板，再倒推文案。UI 的职责是把已经确认的信息更清晰、更有吸引力地呈现出来；如果信息模块不清楚，必须回到 `p0-content-gates.md` 补齐，而不是继续调样式。

## 复用优先，但不绑死模板

Tomako SEO 页面开发要优先复用当前源码里的页面外壳、共享组件、section presets、MDX components 和脚手架能力，但复用不是强制套模板。模板库是为了提升下限和效率，不是限制页面上限。

执行规则：

1. 先完成 Copy Brief 和信息模块清单，再决定 UI 和代码结构。
2. 对每个页面模块判断：直接复用、轻量组合、扩展共享组件，还是自定义开发。
3. 如果共享模块能不损失信息质量、视觉上限和交互体验，就优先复用。
4. 如果共享模块会导致信息重复、模块关系不清、视觉变差、表单复杂、结果区受限或无法体现当前工具价值，就不要硬套模板。
5. 自定义开发可以先放在当前 container/widget 内；如果同类结构在两个以上页面重复出现，再考虑沉淀为共享组件。
6. 交付前说明本次用了哪些共享模块，哪些地方选择了自定义，以及自定义的原因。

判断标准只有一个：是否更好地表达用户价值、解决用户疑问，并降低实现和维护成本。不能为了“看起来统一”牺牲当前页面的最佳解。

## Tool 页面总体判断

默认判断：大多数 Tomako Tool 页面需要后端、云端 Agent、LLM Task、URL/文档抓取、分析、生成或结构化写回。纯前端只适合明确低风险、确定性、自包含的计算器、转换器、格式化器或清楚标注的本地 demo。

当前代码优先级最高。若文档和代码冲突，以 `Tomako`、`Tomako-portal`、`Skills-OL` 当前源码为准，并在答复中说明冲突。

## 内容页总体判断

内容页不是“没有交互的低配工具页”。它的核心任务是承接搜索需求、建立主题权威、解释用户问题、引导用户进入工具或模板，并通过可抓取正文形成长期流量。

默认判断：

- 内容页必须先有搜索意图和用户问题，再决定页面类型。
- 每篇内容都要有独立信息增益，不能只是换关键词、换标题或换地区变量。
- MDX 负责内容，不负责完整页面体验；内容页必须由共享 Content Shell / MDX 组件承接 Hero、CTA、阅读布局和产品化视觉。
- 内容页必须服务 Tomako 产品或工具链路：解释问题、建立信任、给出模板/清单/判断标准，或把用户导向相关 Tool / Template /下一步。
- 批量内容优先做主题集群和内链，不要一次生成大量孤立文章。
- 对比、法律、财务、安全、医疗或竞品评价等内容必须有更严格来源、边界和免责声明，不能编造事实。

## 交付前答复要求

最终答复必须简短说明：

- 读取了哪些 Gate 文件。
- 改了哪些文件或做了哪些诊断。
- 跑了哪些验证。
- 远端部署状态：已部署并验证、无需部署，或明确阻塞。
- 哪些生产风险仍未验证，例如后端、cc-connect、Skills-OL 部署、sitemap、真实 Agent 返回。

不要因为 UI 看起来完成、请求返回 200、schema 能 parse、mock 能渲染，就宣称页面完成。必须按照对应 Gate 验收真实用户价值。

Agent-backed 工具还必须完成远端运行时闭环：如果改了前端 LLM task service、后端、Skills-OL、cc-connect、schema、resultType 或环境变量，就要确认目标环境已部署/重启并跑 live QA；如果无法部署，必须把它作为 blocker 明说，不能把页面说成可测试或完成。

尤其注意：改了 `Skills-OL/` 中的 Agent Skill 或脚本后，必须自动进入 `$deploy-skills-ol` 部署闭环；不能只提醒“需要部署”，也不能继续拿云端旧 Agent 结果判断新逻辑是否生效。

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
