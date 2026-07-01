# Community Pain Point Extractor 复盘：流式模块输出与 Agent-backed Tool 体验

复盘日期：2026-07-01

面向读者：后续迭代 `programmatic-seo` Skill 的 Agent。

适用范围：Tomako 程序化 SEO Tool Page，尤其是需要云端 Agent / Skills-OL / Skill Result 生成长报告的工具。

## 结论摘要

这次需求的最大通用价值不是某一个页面样式，而是发现了一个高频 P0 体验问题：长报告型 Agent 工具如果等所有内容生成完再一次性展示，用户会经历很长的空白等待；但如果只是前端做假进度，也无法真正改善等待感。更稳定的方案是把报告拆成可见模块，Agent / Skills-OL 按模块逐步写入累计 partial result，前端轮询并增量渲染，UI 在下一模块位置提前显示占位和 loading。

这套方案应该被评估是否沉淀进 `programmatic-seo` 的运行时和 UI Gate，作为长报告型 Tool Page 的默认要求。

本次也暴露了几个流程问题：Hero 图规则没有在首次实现时被严格执行；本地前端可见不代表 Skills-OL runtime 已部署；SSE 的 `skill_result` 事件和真实 final result 之间存在状态误判；只靠 prompt 要求逐步输出不够，需要脚本层 guard；部署工具在远端仓库和本地仓库不一致时容易给出错误安全感。

## 背景

用户最初给出的需求是做一个「Reddit / X / Hacker News 用户痛点抓取器」：

- 用户输入一个方向，例如 `AI customer support tool for Shopify sellers`。
- 工具自动输出相关社区、高频抱怨、用户原话、出现频率、付费意图判断、可切入的小功能点、对应 landing page 角度。
- 输出不能是泛泛一句“用户需要更好的客服自动化”，而要转成可落地的机会表达，例如“Shopify 卖家经常抱怨客户问订单状态太多，可以做一个只回答订单状态 / 物流问题的 AI widget”。
- 目标用户是做 SaaS、AI tool、插件、Chrome extension 的个人开发者，痛点是不会做早期用户调研，也懒得翻社区。

用户同时提醒：项目里已有另一个旧版程序化 SEO Skill / 旧版工具也在生成需求，不要互相冲突。实际执行中因此需要保持新工具 `community-pain-point-extractor` 和旧工具 `reddit-pain-point-finder` 代码路径独立。

## 实际实现范围

前端侧主要涉及：

- `Tomako/src/components/tools/community-pain-point-extractor.tsx`
- `Tomako/src/services/llm-task/community-pain-point-extractor.ts`
- `Tomako/src/services/llm-task/index.ts`
- `Tomako/src/lib/tools/community-pain-point-extractor-schema.ts`
- `Tomako/src/i18n/messages/zh/tools/community-pain-point-extractor.ts`
- `Tomako/src/i18n/messages/en/tools/community-pain-point-extractor.ts`
- 工具 container、registry、共享 tool page shell 等页面接入文件。

Skills-OL 侧主要涉及：

- `Skills-OL/community-pain-point-extractor.mjs`
- `Skills-OL/skills/community-pain-point-extractor/SKILL.md`

旧工具路径保持独立：

- `reddit-pain-point-finder` 相关脚本、Skill、前端组件和 service 没有被合并进新工具。
- 只在 `Tomako/src/services/llm-task/index.ts` 补了旧工具缺失的 barrel export，避免构建失败；没有改旧工具业务逻辑。

## 需求和实现的关键转折

### 1. Hero 和首屏布局问题

用户截图指出首屏 Hero 图不应放在标题右侧，而应按 Skill 文档里对 landing hero 的要求作为背景 / 沉浸式首屏信号。首次实现没有足够早地把 `p0-ui-gates` 和资产规则落实到视觉结构里，导致 Hero 像普通插图，破坏了用户对 SEO 页面首屏质量的预期。

后续修复方向：

- Hero 改成首屏背景式视觉，不作为标题右侧的普通图片。
- 工具本体不做营销落地页式的大卡片堆叠，而是更像工作台。
- 结果区布局从过窄、过长、模块挤压的形式，调整为更可读的报告卡片和分区。

适合沉淀的规则：

- 对 Tool Page，视觉资产的位置必须服务首屏信息架构。Hero 图片不能只是“有一张图”，必须符合 Skill 中对背景式 / 首屏信号的约束。
- 用户指出 UI 观感问题时，不能只调 CSS，应回到信息模块、首屏任务和工具工作台结构重新判断。

### 2. 分析速度问题

用户反馈分析抓取最终效果需要很久，希望保持效果不变差但提升速度。这里的核心不是单纯减少 LLM token，而是把公开信息抓取和生成分层。

采取的方向：

- 在 Skills-OL 脚本里加入 bounded evidence collector。
- 对 Reddit / HN / web search 做有限查询、并发控制和缓存。
- HN 优先使用 Algolia API。
- 对搜索和页面读取设置 timeout，避免单一来源拖慢全局。
- 先生成 evidence pack，再由 Agent / LLM 做结构化综合。

经验：

- 长报告质量依赖证据，不能为了速度直接删掉证据收集。
- 可优化的是查询数量、并发、缓存、来源优先级和失败降级。
- Jina / DuckDuckGo 类来源容易遇到 451、429 或并发不稳定，应限制查询数量和并发。

适合沉淀的规则：

- 社区调研类 Tool 应优先做确定性、可缓存、有限并发的 evidence collector，再做 LLM synthesis。
- 运行时 Gate 应要求记录每类来源的 timeout、最大查询数、最大并发和缓存策略。

### 3. “不改后端”的渐进式输出方案

用户提出：报告有多个模块，例如相关社区、总报告、相关机构、高频痛点；希望分析完成一个模块就让前端看到一个模块，而不是等待全部完成。

在不改后端的前提下，本次采用的是 cumulative partial Skill Result：

1. Skills-OL / Agent 生成第一个可见模块。
2. 脚本把当前已完成模块写入 `/api/skill-results`，`reportStatus` 标记为 `partial`。
3. 前端在 task 运行中轮询 `GET /api/skill-results/{taskId}`。
4. 前端拿到 partial 后立即渲染已完成模块。
5. 后续模块继续追加到同一个结构里，再次写入 partial。
6. 全部完成后写入 `reportStatus: "final"`。

这不需要改 Tomako-portal 后端，因为 Skill Result 本身已经是按 `taskId` 可覆盖 / 可读取的结构化结果。真正需要改的是：

- 前端状态机要允许 partial。
- schema 要能区分 partial 和 final。
- Skills-OL 脚本要按模块写回。
- prompt 要要求 Agent 按模块调用脚本。

### 4. 只靠前端和 Agent 不够

用户问过“当前方案和后端参与改造相比有什么差异”。本次实践结论：

- 纯前端 loading / mock partial 只能改善表面等待感，不能让真实结果提前出现。
- Agent prompt 要求逐步输出有帮助，但不稳定，Agent 仍可能一次性生成多个模块。
- Skills-OL 脚本参与后，可以在 `--partial-file` 入口做结构校验和顺序限制，显著提升稳定性。
- 后端若参与，能做更强的事件流、进度记录、module status、取消重试和持久化审计；但本次不改后端也可以做到可用的渐进式体验。

推荐沉淀的判断：

- 不改后端方案适合快速上线和验证体验。
- 如果同类长报告工具会越来越多，应评估后端提供通用 module-progress / partial-result 事件模型。

## 流式模块输出方案细节

### 数据契约

建议长报告工具统一包含以下字段：

```ts
type ReportStatus = "partial" | "final";

type ProgressiveReport = {
  reportStatus: ReportStatus;
  completedSections: string[];
  inProgressSection?: string;
  summary?: SummaryBlock;
  communities?: CommunityBlock[];
  paidIntent?: PaidIntentBlock[];
  entryFeatures?: EntryFeatureBlock[];
  painClusters?: PainClusterBlock[];
  landing?: LandingBlock[];
  experiments?: ExperimentBlock[];
  sources?: SourceBlock[];
};
```

关键点：

- partial result 是累计结构，不是 delta patch。前端每次拿到的是当前完整快照。
- `completedSections` 用于判断哪些模块可以稳定展示。
- `inProgressSection` 用于展示下一块占位和 loading。
- final result 必须显式标记 `reportStatus: "final"`。
- partial schema 应比 final schema 更宽容，避免一个未完成模块导致整个结果被判 invalid。

### 可见模块顺序

本次用户明确希望按前端看到的小方块顺序逐个出现，而不是后台随意拆：

1. 第一个淡蓝色总报告模块，例如「AI 香水气味分析与配方制作」。
2. 相关社区。
3. 付费意愿。
4. 接入功能。
5. 高频痛点 cluster，一个 cluster 也可以视为一个独立可见模块逐个追加。
6. Landing page 角度。
7. 验证实验。
8. 公开来源。

沉淀规则：

- 后端 / Agent 的分析顺序应尽量和用户在前端看到的模块顺序一致。
- 如果算法内部必须穿插处理，也应在写回层按可见模块顺序发布。
- “一个模块”应该以用户能看到的独立 UI 方块为单位，而不是以后端内部大段 JSON 字段为单位。

### 脚本层 guard

本次最关键的稳定性修复之一：仅靠 prompt 要求 Agent “一次只输出一个模块”不够。脚本需要检查 partial 是否符合顺序和粒度。

采用的 guard 思路：

- `visualProgressUnits` 定义用户可见模块顺序。
- `fetchPreviousResult(taskId)` 读取上一版 Skill Result。
- `assertProgressiveOrder(current, previous)` 检查是否跳过顺序。
- `assertSingleModuleAdvance(current, previous)` 检查一次 partial 是否新增太多可见模块。
- 如果 Agent 一次提交了 summary + communities 以外的大批模块，脚本拒绝写入，要求重新按粒度输出。

该 guard 是值得沉淀的通用规则：

- 长报告渐进输出不能只靠自然语言 prompt。
- Skill script 应在可行时校验 partial 的模块顺序和新增粒度。
- 违反渐进契约时，脚本应 fail fast，而不是把批量结果写给前端。

### 前端状态机

本次踩坑：前端最初拿到 partial 后，仍可能在 final result 等待超时后进入失败页，导致用户只看到两个模块，然后出现“研究超时”。

修复原则：

- 一旦看到有效 partial，前端不能因为 final result 暂时未到就清空结果或进入最终失败。
- 有 partial 时应继续 polling，保留已生成内容。
- 超时文案应变成“继续等待 / 公开信息较难获取 / 已保留当前结果”，而不是整页失败。
- SSE `skill_result` 不应被当成 final-only 信号。当前链路里 partial 写回也可能触发 result-ready 感知，前端仍要读取 raw result 并看 `reportStatus`。

建议状态：

```text
idle
submitting
streaming
partial
awaiting_final
done
failed
```

失败应区分：

- 提交失败且没有 taskId。
- task 明确 FAILED。
- 从未见过 partial，且有界等待后仍没有结构化结果。
- 已有 partial，但 final 长时间未到：这是 degraded / still working，不应按同样方式展示为全失败。

### 前端 loading UX

用户进一步要求：

- 每个模块生成后，下一个模块占位符要提前显示。
- loading 就在占位区域里，避免用户滑到下面看到空白。
- 文案要说明当前处理哪个模块、该模块总共有多少步、目前完成度。
- 总部 / 顶部 overall loading 继续保留，不能因为新模块 loading 出现就去掉。
- 总进度条可以保留。
- 时间估计不能突然往前跳，例如 loading 20 秒后又变成 40 多秒。

最终 UX 原则：

- 顶部 overall progress card 保留，用于全局状态和整体进度。
- 报告流中在下一模块位置显示 inline module loading card。
- 进度条按模块完成数推进。
- 模块 loading 展示当前模块名、step X/N、已用时间和预计剩余。
- 预计剩余时间必须单调递减，到 0 后显示“仍在处理”，不要循环重置。
- 不要用通用大 loading 覆盖已完成内容。

建议沉淀到 UI Gate：

- 长报告 Tool Page 必须支持“顺着往下看”的加载体验。
- 下一个结果块的位置必须有占位和状态，不能让用户滑到空白。
- 顶部总进度和局部模块进度可以同时存在，职责不同。
- 时间估计不能使用 modulo / cycle 逻辑，避免倒计时跳回更长时间。

## 线上部署和运行时坑

### Skills-OL 未部署导致本地改动无效

用户最初测试渐进输出无效，原因不是前端逻辑完全错，而是 Skills-OL 没有部署到线上 runtime。用户本地 3000 前端实际调用的是生产后端 / cc-connect / Skills-OL 链路，前端本地改动不能让远端 Agent 使用新的 Skill 脚本。

通用规则：

- Agent-backed Tool 只要改了 Skills-OL 脚本、Skill.md、resultType、schema 或 task prompt，就必须确认远端 runtime 是否部署。
- 本地 mock、schema parse、前端页面 200 都不能证明真实 Agent 链路已更新。
- 本地 3000 前端连接生产 API 时，尤其要验证生产 cc-connect 和 Skills-OL。

### 部署方式的风险

本次标准 `deploy-skills-ol` 路线不适合直接使用，因为：

- 本地 `Skills-OL` 仓库有 dirty / unmerged 状态，例如 `UU CONTRIBUTING.md`。
- 新工具文件处于 untracked 状态。
- 远端服务器 `/home/ubuntu/Skills-OL` 在 `main...origin/main`，但有大量历史未跟踪工具文件。
- 本地 `git ls-remote origin refs/heads/main` 和远端服务器 git@ origin 的 commit 视图不一致。

最终采取了手动热部署：

- 用 SSH key `/Users/ereneren/.ssh/id_ed2551` 连接 `root@8.210.246.124`。
- 上传：
  - `community-pain-point-extractor.mjs`
  - `skills/community-pain-point-extractor/SKILL.md`
- 安装到 `/home/ubuntu/Skills-OL` 并设置 owner。
- 重启 `cc-connect`。
- 校验 `systemctl is-active cc-connect` 为 active。
- 校验远端 `sha256sum` 与本地一致。

这不是理想长期方案，只是当前仓库状态下的最小风险热修。

建议给 `deploy-skills-ol` Skill / 脚本增加：

- 远端仓库 dirty / untracked 检测。
- 本地 origin 和远端 origin commit 不一致提示。
- “手动上传 hotfix” fallback 的显式流程和风险声明。
- 部署后必须记录远端路径、文件 hash、重启状态。

### 部署脚本 report bug

`deploy-skills-ol.sh report` 曾因为 cache path 未初始化失败，并把失败状态写入缓存。后续通过 `status --json` 恢复状态缓存。

这属于部署工具 bug，不应写成 programmatic SEO 的 P0 规则，但应反馈给 `deploy-skills-ol` Skill / 脚本维护。

## 构建和导出坑

用户最后截图显示 Next.js dev overlay：

```text
Export fetchCommunityPainPointExtractorResult doesn't exist in target module
```

原因：UI 从 `@/services/llm-task` barrel import 新 service 函数，但 `src/services/llm-task/index.ts` 没有导出新工具函数。`tsc` 还发现旧 `reddit-pain-point-finder` 也存在类似 barrel export 缺口。

修复：

- 在 `Tomako/src/services/llm-task/index.ts` 导出 `community-pain-point-extractor` service 函数和类型。
- 同时补齐旧 `reddit-pain-point-finder` 的 barrel exports。
- 不改旧工具业务逻辑，避免和旧需求冲突。

验证：

- `pnpm exec tsc --noEmit --pretty false` 通过。
- 相关 eslint 通过。
- dev server 重新启动，`/zh/tools/community-pain-point-extractor` 返回 200。

通用规则：

- 新增 LLM task service 后，如果 UI 使用 `@/services/llm-task` barrel import，必须同步更新 `index.ts`。
- Tool Page 完成前必须跑 `tsc --noEmit`，不能只依赖浏览器热更新或局部 lint。

## 本次验证情况

已做过的验证包括：

- 前端 TypeScript：`pnpm exec tsc --noEmit --pretty false`。
- 前端 lint：针对相关文件运行 eslint。
- 前端 build：`pnpm build` 通过，但存在既有 Turbopack NFT warning，与本次工具无直接关系。
- Skills-OL 脚本语法：`node --check Skills-OL/community-pain-point-extractor.mjs`。
- partial guard 本地 dry run：
  - summary-only partial 可通过。
  - summary + communities 等批量 partial 会被拒绝并提示 too many visible modules。
- 远端部署：
  - 上传脚本和 Skill.md。
  - `cc-connect` restart 后 active。
  - 远端文件 hash 与本地一致。
- 本地 dev server：
  - `http://localhost:3000/zh/tools/community-pain-point-extractor` 返回 200。

仍需谨慎说明的验证缺口：

- 没有在复盘时附上一个完整 live taskId，证明从提交到每个模块逐步出现再到 final 的全链路录屏 / raw Skill Result 轨迹。
- 部署采用手动 hotfix，不是干净 git deploy。
- 远端 Skills-OL 仓库状态不干净，后续 git pull / 部署可能覆盖或遗漏未跟踪文件。

## 建议写入 programmatic-seo Skill 的通用规则

### 运行时 Gate 建议

建议在 `p0-runtime-gates.md` 中新增“渐进式 Skill Result / 长报告输出”小节：

- 长报告型 Agent Tool 默认应评估 progressive partial result。
- 如果用户可见结果包含多个独立模块，Skill Result 应支持 `reportStatus: "partial" | "final"`。
- partial result 应为累计快照，不建议前端维护复杂 delta merge。
- 前端必须轮询 raw `/api/skill-results/{taskId}`，不能只等 SSE final。
- 一旦看到有效 partial，不得因为 final 暂未到达而清空结果或进入最终失败。
- Agent prompt 不能作为唯一约束；Skills-OL script 应尽量校验 partial 顺序、粒度和 schema。
- 改了 Skills-OL 后必须部署并重启 cc-connect，本地前端不代表 runtime 已更新。

### UI Gate 建议

建议在 `p0-ui-gates.md` 中新增“长报告加载体验”小节：

- 已完成模块应立即稳定展示。
- 下一个模块的占位应提前显示在内容流中的真实位置。
- 局部 loading 文案要说明当前处理模块和 step X/N。
- 顶部 overall progress 与局部 module loading 可以同时存在，不应互相替代。
- 时间估计必须单调，不得跳回更长剩余时间；过期后显示仍在处理。
- 不要让用户滑到空白区域后不知道是否还会继续生成内容。

### Tool Page Implementation 建议

建议在 `tool-page-implementation.md` 中新增 checklist：

- 新增 LLM task service 后检查 barrel export。
- schema 区分 partial 和 final。
- UI normalizer 能接受 partial 的缺省字段。
- 结果组件支持 `completedSections` 和 `inProgressSection`。
- 不与旧工具复用 resultType / slug / scene / Skill script，除非明确迁移。

### Launch Checklist 建议

建议在 `p0-launch-checklist.md` 或运行时 Gate 中强化 live QA：

- 对 Agent-backed Tool，必须提交至少两个差异明显输入并检查输出随输入变化。
- 对 progressive Tool，必须记录至少一次 raw Skill Result 的 partial 序列。
- 验证维度应包括：提交、task、partial writeback、UI partial render、final writeback、UI final render。
- 如果无法部署或无法做 live QA，最终交付必须明确写 blocker，不能说“已完成可测”。

### Deploy Skills-OL 建议

这部分更适合迭代 `deploy-skills-ol` Skill，而不一定写入 `programmatic-seo`：

- 部署前检查本地和远端 branch / commit / origin 是否一致。
- 检查远端 untracked runtime 文件。
- 修复 `report` 缓存路径初始化问题。
- 提供 hotfix 上传模式，并强制输出 hash、owner、restart、active 状态。

## 不建议直接写入通用规则的内容

以下内容应保留为项目事故记录，不建议直接升成 P0：

- 某一次服务器 IP、SSH key 路径、具体 scp 命令。
- `CONTRIBUTING.md` 的具体冲突状态。
- 某个截图里的具体页面模块名称，例如“AI 香水气味分析与配方制作”。可以抽象成“用户可见模块”，不要写死工具内容。
- 某次 Turbopack NFT warning，除非后续证明会影响 SEO 页面构建。
- `deploy-skills-ol.sh report` 的具体缓存错误日志，适合放到部署 Skill 的 issue 或复盘，不适合污染 SEO Skill。

## 推荐给下一个 SEO Skill 迭代 Agent 的处理顺序

1. 先评估是否新增一个独立 reference：`references/progressive-agent-report-gates.md`。如果新增，再从 `SKILL.md` 的 Tool 页面运行时路线链接过去。
2. 如果不新增独立文件，则分别补到：
   - `p0-runtime-gates.md`
   - `p0-ui-gates.md`
   - `tool-page-implementation.md`
   - `p0-launch-checklist.md`
3. 把本次规则抽象成“长报告型 Agent Tool”的通用要求，不要把 `community-pain-point-extractor` 的具体字段照搬成唯一模板。
4. 增加一个小型验收清单：创建 progressive Tool 时必须能回答“模块顺序是什么、partial 契约是什么、前端如何处理 partial、远端是否部署”。
5. 如果有时间，同步迭代 `deploy-skills-ol` Skill，解决 report bug 和远端仓库状态检测问题。

## 可直接抽象的规则草案

可以考虑写入 Skill 的草案如下：

```text
长报告型 Agent Tool 不应默认一次性等待 final result。若结果包含多个用户可见模块，必须评估 progressive partial Skill Result：

- resultJson 必须能标记 partial/final。
- partial result 必须是累计快照。
- 前端必须在 task 运行中轮询 skill result 并渲染 partial。
- 有 partial 后不得把 final timeout 展示为整页失败。
- 下一模块应在内容流中提前显示占位和 loading。
- prompt 之外，Skill script 应尽量校验模块顺序和一次新增粒度。
- 交付前必须验证远端 Skills-OL / cc-connect 已部署，且至少有一次 raw partial 序列可查。
```

## 最后判断

这次需求值得推动 Skill 迭代。原因是它触及的是一类工具的共同问题：Agent 生成报告越来越长，真实等待不可避免；如果没有 progressive result contract，页面会在体验上显得慢、假、不可控。相比继续打磨 loading 文案，模块级 partial writeback 更接近问题根源。

建议把“流式流转块输出”升为长报告 Tool Page 的 P0 候选规则，并把部署闭环、partial 状态机、模块占位 loading 一起纳入验收。
