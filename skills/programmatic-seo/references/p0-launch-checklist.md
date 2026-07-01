# P0 上线验收清单

## 使用时机

准备交付、发布、标记 `published`、加入 sitemap、结束修复、汇报完成或做上线前 QA 时，必须读取本文件。

## 完成定义

一个 Tomako Tool/SEO 页面完成，必须同时满足：

- 解决目标用户任务。
- 输入输出和搜索意图清楚。
- 运行时选择正确。
- 页面可抓取、可索引条件明确、metadata 对齐。
- UI 表单简洁可用，结果区有足够空间。
- 视觉物料符合场景且不喧宾夺主。
- 页面讲清为什么选 Tomako，而不是只解释流程。
- Agent-backed 结果只来自结构化 Skill Result。
- 核心输出已用真实当前输入验证。
- 桌面和移动端通过。
- 发布风险记录清楚。

内容型 SEO 页面还必须满足：

- 页面类型、关键词、搜索意图、读者阶段和内容集群关系明确。
- 正文有独立信息增益，不是关键词替换或通用 AI 泛文。
- MDX frontmatter、双语 slug、图片、内链和 CTA 符合当前 Tomako 内容架构。
- sitemap、canonical、hreflang 和索引状态已确认。

## 阅读补齐 Gate

交付前检查阅读状态表：

- 新建或重做页面：必须补读 `SKILL.md` 中列出的所有必读 MD。
- 局部修复：必须补读相关 Gate，并说明未做完整页面验收。
- 发布/上线：必须补读所有 Gate。
- 复盘：必须读 `tool-retro-template.md`。

最终答复要说明“已读 Gate”和“未验证风险”。

## 基础命令

按变更范围运行：

```bash
pnpm lint
pnpm build
pnpm tools:generate-mcp
```

后端变更按需运行：

```bash
./mvnw test
./mvnw clean package -Dmaven.test.skip=true
```

Skills-OL 变更按脚本提供的 dry-run 或真实写回路径验证。

## 路由与索引

检查：

- `/zh/tools/{slug}` 可访问。
- `/en/tools/{slug}` 可访问。
- slug 是用户自然会访问的 URL。
- 改名时有 alias 或 redirect。
- review/draft 页面本地或 review 环境可访问。
- review/draft/deprecated/mock-only 页面 `noindex, nofollow`。
- review/draft 页面不进 sitemap，不进公开 tools index。
- published 页面是否应该进 sitemap 已明确。
- `generateStaticParams` 能看到目标 slug。

不要为了本地可访问而把未验证工具设成 `published`。

## SEO 上线检查

- [ ] title、description 本地化且准确。
- [ ] canonical 和 hreflang 正确。
- [ ] Open Graph 与真实页面一致。
- [ ] robots/index 决策正确。
- [ ] sitemap 行为符合状态。
- [ ] 页面关键内容不是纯客户端隐藏内容。
- [ ] 有 Copy Brief。
- [ ] 已在对话框输出需求摘要、关键词候选小表和最终 Keyword Evidence Brief。
- [ ] 若使用 DataForSEO，查询词数量符合低成本规则，并记录查询轮次、查询词和证据来源；若未使用，已说明原因。
- [ ] 若存在 `docs/seo-keyword-briefs/{slug}.md/.json`，已优先复用；若刷新，已说明刷新原因。
- [ ] 没有把无密钥 scaffold brief 当作正式关键词证据或最终 Keyword Evidence Brief。
- [ ] 如果是已有页面文案校准，已列出并修正关键词缺口、用户价值缺口、疑问覆盖缺口和无效模块。
- [ ] H1、intro、widget、metadata 任务一致。
- [ ] FAQ、related tools、更新时间或状态按需出现。
- [ ] 没有 doorway/thin page。
- [ ] 没有关键词堆叠。
- [ ] 页面自然覆盖核心任务词、同义变体、输入/输出词、失败排查词、边界词、结果使用词和下一步词。
- [ ] 页面有“你可以得到什么 / 用户价值”模块，列出具体结果项和对应价值。
- [ ] 没有用阅读时间、工具分类、更新时间、关键词标签、输入 / 输出 / 边界三标签或泛泛 metadata 替代用户价值模块。
- [ ] 公开页面没有把内部 Agent/LLM/实现方案评估当作主要内容。
- [ ] 下载、抓取、转换、第三方平台类页面已说明支持范围、失败边界、隐私/版权/平台限制。
- [ ] 支持范围、不支持范围、失败排查、结果使用指导和相关工具内链已按工具类型覆盖。
- [ ] 除工具交互和基础使用说明外，页面主体同时展示产品价值并解决用户疑问。
- [ ] 每个主要模块都能说明它是在体现价值、消除疑虑，还是帮助用户完成操作。
- [ ] 页面主体明确回答“为什么选我们”，并说明相比手工、模板、脚本、插件、普通文章或竞品的优势。
- [ ] 页面定义了“好工具标准”，并把 Tomako 能力放进这个标准中。
- [ ] 好工具标准优先从用户决策标准出发，例如稳定、速度、质量、成本、易用、兼容、可信；没有把流程透明当成核心标准。
- [ ] 没有用“它是怎么工作的”、内部技术流程或 Agent/LLM 方案替代产品价值。
- [ ] 没有编造不可验证事实，例如官方合作、最快、100% 成功、真实客户、认证、平台背书或具体性能数字。
- [ ] 已先完成 Copy Brief 和信息模块清单，再进入 UI/视觉呈现；不是先套版式再补文案。
- [ ] 每个主要 UI section 都能追溯到一个用户问题、SEO 搜索意图、产品价值或疑问消除目标。
- [ ] 页面诊断或优化先评估“信息是否完整、价值是否讲清、疑问是否解决”，再评估布局、组件、图片和视觉节奏。

## 内容页专项检查

适用于 Blog / Template / MCP 等 MDX 内容页：

- [ ] 已读取 `p0-content-page-brief.md`、`p0-content-page-structure-gates.md`、`p0-content-page-writing-gates.md` 和 `content-page-implementation.md`。
- [ ] 页面类型与搜索意图匹配，例如教程、模板、对比、清单、解释、排查、hub 或 cluster。
- [ ] 已在对话框输出内容页 Brief：目标读者、读者阶段、页面承诺、独立信息增益、集群关系、内链计划和 CTA。
- [ ] 页面不是薄内容、重复内容、关键词替换页或孤立文章。
- [ ] H1、title、description、intro、第一屏直接回答同一个搜索问题。
- [ ] 前 20% 内容给出答案、路线或可用材料，不把核心答案藏到最后。
- [ ] 每个 H2 对应真实问题、判断、步骤、标准、误区、示例或下一步。
- [ ] 正文包含具体示例、模板、清单、步骤、判断标准、排查路径或产品化下一步。
- [ ] 已说明事实来源；数据、竞品、法律/隐私/平台规则等高风险事实没有编造。
- [ ] 内容说明了 Tomako 的相关工具、模板或工作流价值，而不是只做普通百科文章。
- [ ] MDX frontmatter 必填字段齐全：`title`、`description`、`category`、`keywords`、`updatedAt`、`readingTime`。
- [ ] `keywords` 是数组，`updatedAt` 是 `YYYY-MM-DD`。
- [ ] zh/en slug 默认一致；缺某语言时已记录风险和补齐计划。
- [ ] 正文不使用 `#`，只使用 `##` / `###`。
- [ ] 站内链接不带 `/{locale}/` 前缀，锚文本描述目标页价值。
- [ ] 每篇内容页有合理上游/下游内链和一个明确 Tomako CTA。
- [ ] 图片放在 `public/` 并能访问；alt 文案自然，不堆关键词。
- [ ] MDX 中没有 `fetch`、密钥、环境变量、服务端逻辑或复杂交互。
- [ ] `/blog/generate` 或内部草稿能力保持 noindex，不被当成公开页面。
- [ ] `pnpm build` 能通过内容加载和 frontmatter 校验。
- [ ] sitemap、canonical、hreflang、robots/index 是否覆盖该栏目已验证；未覆盖时明确为上线风险。

## UI 与视觉检查

- [ ] 表单简洁，不像文档或设置面板。
- [ ] 表单通过 3 秒行动测试：用户不读长说明，也知道输入什么、点哪里、等待什么结果。
- [ ] 表单内没有段落式功能介绍、大块说明卡、密集 helper 或过量小字。
- [ ] 工具栏、表单控制区和工作台左侧输入面板默认白底，没有用大面积 tinted 底色承载整块输入区。
- [ ] Button / CTA 使用黑色或近黑背景，次要按钮使用中性样式；没有默认绿色、青色、荧光色或渐变按钮。
- [ ] 工具 UI 主题为中性灰黑体系，绿色/青色没有作为表单、按钮、选中态、边框或 hover 的默认主题色。
- [ ] Tool/SEO 页顶部导航复用了本地当前官网 Hero 导航和 `@/components/ui/navigation-menu`，没有使用旧线上页面、旧 `MarketingHeader` 或单独“返回工具”导航。
- [ ] Tool/SEO 页顶部导航有独立背景层，在 Hero 背景图或页面图像上清晰可读；官网首页 Hero 导航没有因 Tool 页修正被同步改成 solid 背景。
- [ ] Tool 页 logo 点击跳到当前 locale 官网首页，产品/定价等主导航跳到官网首页对应锚点，且没有为具体工具页额外加 active 选中态。
- [ ] MCP badge、阅读时间、更新时间、关键词、工具分类、输入 / 输出 / 边界三标签没有被塞进顶部导航栏。
- [ ] 支持范围、失败边界、隐私/版权、平台限制等解释已放到页面说明模块、FAQ、结果指导或轻量 tooltip/popover。
- [ ] 工作台标题区只保留真实任务动作或状态，没有无关 badge、chip、SEO 标签或装饰按钮。
- [ ] 控件来自 `@/components/ui`。
- [ ] 没有 raw default `<select>` 等控件。
- [ ] 已评估共享 section / 页面模板库：适合的模块已复用，不适合的模块已自定义，并能说明原因。
- [ ] 外露配置项不超过 5 个，只保留核心必填或关键字段；其余已折叠或分步。
- [ ] 复杂表单左侧约束，右侧使用工作台生图物料，下方结果。
- [ ] 输入框、textarea、select、风格/Type 选择器、横向卡片轨道、右侧视觉和结果区没有越过父容器、压住相邻列或遮挡后续字段。
- [ ] 页面没有意外横向滚动；如果存在横向选择器，滚动只发生在内部轨道，不能撑破页面。
- [ ] 大型风格/模板/Type 选择器没有直接铺成超宽卡片墙；超过 3 到 4 个大卡选项时已改成下拉、popover、dialog、折叠或分步。
- [ ] 页面主体没有被全局窄 `max-width` 收在中间；只有表单、长文本列等必要对象单独限宽。
- [ ] 结果区、图文模块、视觉 band 和 CTA 使用页面可用宽度，没有跟随表单宽度被压窄。
- [ ] “你可以得到什么 / 用户价值”模块没有和 Hero 大标题左右对排。
- [ ] Hero 右侧没有用大面积卡片展示阅读时间、工具分类、更新时间或关键词标签等弱信息。
- [ ] Hero 下方或右侧没有默认展示输入 / 输出 / 边界三标签；这些信息如有必要，已转成工作台帮助、结果指导、能力边界或 FAQ。
- [ ] “好标准 / 为什么选我们 / 用户价值”模块没有使用左编号清单 + 右长段落的重复排版。
- [ ] 生成按钮满宽、纯文字，且使用黑色或近黑背景。
- [ ] 点击生成滚动到结果锚点中心。
- [ ] 初始态没有无意义大空结果区。
- [ ] 结果区支持真实输出长度。
- [ ] tab/chip/option 选中态没有大面积纯黑。
- [ ] tab/chip/option/结果卡选中态一眼可见，不只靠轻微底色或 1px 浅边框；选中、hover、focus、普通态明显区分。
- [ ] option card / chip / 结果卡 active 态只有一个外轮廓；没有 border + ring 双描边。
- [ ] option card / chip 选中态没有额外凸起色块、顶部标签条或悬浮装饰块。
- [ ] 选项没有过度 icon/check。
- [ ] 图片主体撑满，无大背景底、外层卡片、blob、宽留白。
- [ ] 图片能体现当前工具的真实输入输出，不是通用步骤图或抽象占位。
- [ ] 配图明确服务产品价值或用户疑问，不是装饰性填充。
- [ ] serious public Tool 页面至少有 5 张生图视觉物料：1 张 Hero 背景图 + 1 张工作台右侧图 + 3 张正文配图。
- [ ] Hero 配图是透明背景 PNG，没有自带背景色、背景板、整张色块或右侧独立色块。
- [ ] Hero 区域背景色为 `#F7F6F2`，透明 PNG 直接透出页面底色。
- [ ] Hero 配图在 1200px 容器范围内居右，使用 `object-contain object-right`，没有被 `object-cover` 放大或裁切。
- [ ] Hero 配图支持 H1 / intro 作为 HTML 文本覆盖。
- [ ] Hero 图本身能点题，让用户一眼识别功能和价值；不是抽象装饰。
- [ ] 工作台右侧图能让用户感到简单输入即可得到精美结果，不是前端代码画的结构图或流程图。
- [ ] 3 张正文配图分别服务具体段落或模块，构图和表达目标不重复。
- [ ] 核心配图来自生图模型生成的 bitmap 图片，不是前端代码、SVG、CSS 卡片或 `ToolGuideVisual`。
- [ ] 图片内部如有文字，全部是英文短标签；没有中文、乱码、大段文字或拼写错误。
- [ ] 核心配图以视觉表达为主，不是纯 UI 截图、dashboard、表单、icon 堆或步骤说明图。
- [ ] 核心配图有场景化、实物化、人物使用场景、before/after 或明确价值隐喻。
- [ ] 图片主体铺满，没有自带额外背景底、背景板、外层卡片或大留白。
- [ ] 配图没有用 1、2、3、4 流程列表复读旁边正文。
- [ ] 配图能传递专业感、结果质量、前后差异或选择理由。
- [ ] 结果区状态和当前任务匹配，成功态有真实操作动作。
- [ ] 桌面、平板、移动端布局可用。

## Agent/运行时检查

- [ ] 高上下文工具没有被降级为前端模板。
- [ ] 结果只从 `/api/skill-results/{taskId}` 渲染。
- [ ] 没有本地预览、模板 fallback、raw `llmOutput` final render。
- [ ] Skill Result 的 `resultType` 和 schema 正确。
- [ ] 两个不同有效输入产生合理不同输出。
- [ ] placeholder/demo 输入提交前被拦截。
- [ ] `AWAITING_INPUT`、短暂 404、SSE error 不会直接失败。
- [ ] 错误区分 submit、proxy/upstream、task failed、timeout、schema、writeback。
- [ ] proxy target 已确认。
- [ ] Skills-OL 写回地址是规范 HTTPS 地址，没有 `http://` IP、旧域名或依赖 301/302 跳转。
- [ ] 真实 live QA 已跑通 submit -> writeback -> fetch -> render；不能只用 lint、build、dry-run、schema、mock 或旧 task 代替。
- [ ] 如果本轮修改了 `Skills-OL/` 中对应功能的 Agent Skill、脚本、prompt、resultType 或 schema，已自动执行 `$deploy-skills-ol` 部署到 cc-connect；不能自动部署时已主动询问用户或标为 blocker。
- [ ] 长报告或多模块 Agent Tool 已记录至少一次真实 partial 序列，覆盖 submit -> partial writeback -> UI partial render -> final writeback -> UI final render。
- [ ] 有 partial 时已验证 final 延迟、读取超时或 SSE 抖动不会清空已完成内容，也不会展示整页失败。
- [ ] partial/final 的 raw Skill Result 已检查，模块顺序、累计快照、`reportStatus` 和 schema 符合契约。
- [ ] 新增或改名 LLM task service 已检查 `src/services/llm-task/index.ts` barrel export，并运行 `pnpm exec tsc --noEmit --pretty false`。
- [ ] 若本次改动涉及前端、后端、Skills-OL、cc-connect、schema、resultType 或环境变量，已完成远端部署/重启，或明确证明无需部署。
- [ ] 如果需要部署但当前无法执行，已标为 blocker，写清缺少的权限/服务器/密钥/发布窗口/负责人和下一步命令；不能宣称页面完成、可测试或可上线。
- [ ] 后端、gateway、cc-connect、Skills-OL 的目标版本、部署时间、重启状态和验证 taskId 已记录。

## 浏览器 QA

UI-heavy 页面建议用浏览器或 Playwright 看：

- 桌面约 1440px。
- 平板约 768px。
- 移动约 390px。

检查状态：

- 初始态。
- 表单校验错误。
- submitting/loading。
- awaiting result。
- 成功结果。
- recoverable error。
- retry/revision。
- 最长真实结果。

检查内容：

- 无横向滚动。
- `document.documentElement.scrollWidth` 不大于 `document.documentElement.clientWidth`，除非是明确设计的内部滚动容器。
- 横向选择器、图片、右侧视觉和表单控件的 bounding box 没有越过父容器或遮挡后续字段。
- 长中文和英文不溢出。
- 按钮可点击，焦点可见。
- 图片不裁坏。
- 结果区不挤压。
- console 没有 hydration 或无效 HTML 错误。

## 发布风险记录

以下变化必须更新 release/handoff 记录：

- 新公开路由。
- SEO metadata。
- sitemap 行为。
- mock、fake delay、sample data。
- LLM Task/API 集成。
- 用户提交 URL、文本、文件。
- 鉴权、测试用户、rate limit、隐私面。
- 生成内容可能被误解为生产结果。
- schema 或后端接口。
- slug alias / redirect。
- review/noindex 逻辑。
- SSE、轮询、Skill Result 时序。
- 渐进式 Skill Result 契约，包括 partial/final schema、模块顺序、累计快照和降级状态。
- 生产 upstream、cc-connect、Skills-OL 版本或重启要求。
- 本轮是否修改 `Skills-OL/` Agent Skill 或脚本；若修改，必须记录 `$deploy-skills-ol` 部署结果，未部署则记录 blocker。
- Skills-OL 写回地址、协议或部署环境变量，例如 `SKILL_RESULT_API_URL`。
- 远端部署动作、部署目标、版本/commit、重启结果和 live QA taskId。

建议格式：

```text
### YYYY-MM-DD {tool-slug}

- 范围：
- 文件：
- 运行时：
- 结果来源：
- mock/demo 边界：
- slug/alias：
- review/noindex：
- 生产 LLM/Skills-OL 状态：
- 远端部署状态：
- live QA taskId：
- 待上线要求：
- 验证：
```

## 不可宣称完成的情况

以下情况只能说“UI 已完成”或“局部修复已完成”，不能说页面完成：

- 只验证了 mock。
- 只验证了 schema。
- 只验证了旧 task。
- 只验证了 dry-run，但没有真实写回 `/api/skill-results`。
- 写回链路依赖 http 到 https 跳转，或未确认最终 POST 没有被改写。
- 后端或 Skills-OL 未部署。
- 需要远端部署或 cc-connect 重启，但只改了本地代码或只推了 Git，没有确认目标环境已更新。
- 无法部署却没有标为 blocker，也没有写清下一步命令和负责人。
- 结果来自 fallback。
- 还没跑不同输入变化验收。
- 还没检查移动端。
- review 页面能看但不确定 noindex/sitemap。
- 文案和 runtime 能力不一致。
