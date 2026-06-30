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

- 已在 `src/features/tools/registry.ts` 注册 `{ spec, Container }`；有 widget 时也已注册 `src/components/tools/registry.ts`。
- `status: "published"` 时，`/zh/tools` 与 `/en/tools` 列表页能看到该工具。
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
- [ ] H1、intro、widget、metadata 任务一致。
- [ ] FAQ、related tools、更新时间或状态按需出现。
- [ ] 没有 doorway/thin page。
- [ ] 没有关键词堆叠。
- [ ] 页面自然覆盖核心任务词、同义变体、输入/输出词、失败排查词、边界词、结果使用词和下一步词。
- [ ] 页面有“你可以得到什么 / 用户价值”模块，列出具体结果项和对应价值。
- [ ] 没有用阅读时间、工具分类、更新时间、关键词标签或泛泛 metadata 替代用户价值模块。
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

## UI 与视觉检查

- [ ] 表单简洁，不像文档或设置面板。
- [ ] 表单通过 3 秒行动测试：用户不读长说明，也知道输入什么、点哪里、等待什么结果。
- [ ] 表单内没有段落式功能介绍、大块说明卡、密集 helper 或过量小字。
- [ ] 支持范围、失败边界、隐私/版权、平台限制等解释已放到页面说明模块、FAQ、结果指导或轻量 tooltip/popover。
- [ ] 工作台标题区只保留真实任务动作或状态，没有无关 badge、chip、SEO 标签或装饰按钮。
- [ ] 控件来自 `@/components/ui`。
- [ ] 没有 raw default `<select>` 等控件。
- [ ] 复杂表单左侧约束，右侧 before/after 图，下方结果。
- [ ] 页面主体没有被全局窄 `max-width` 收在中间；只有表单、长文本列等必要对象单独限宽。
- [ ] 结果区、图文模块、视觉 band 和 CTA 使用页面可用宽度，没有跟随表单宽度被压窄。
- [ ] “你可以得到什么 / 用户价值”模块没有和 Hero 大标题左右对排。
- [ ] Hero 右侧没有用大面积卡片展示阅读时间、工具分类、更新时间或关键词标签等弱信息。
- [ ] “好标准 / 为什么选我们 / 用户价值”模块没有使用左编号清单 + 右长段落的重复排版。
- [ ] 生成按钮满宽、纯文字。
- [ ] 点击生成滚动到结果锚点中心。
- [ ] 初始态没有无意义大空结果区。
- [ ] 结果区支持真实输出长度。
- [ ] tab/chip/option 选中态没有大面积纯黑。
- [ ] 选项没有过度 icon/check。
- [ ] 图片主体撑满，无大背景底、外层卡片、blob、宽留白。
- [ ] 图片能体现当前工具的真实输入输出，不是通用步骤图或抽象占位。
- [ ] 配图明确服务产品价值或用户疑问，不是装饰性填充。
- [ ] serious public Tool 页面至少有 4 张生图视觉物料：1 张 Hero 背景图 + 3 张正文配图。
- [ ] Hero 背景图铺满 Hero 区或首屏大区域，H1 / intro 作为 HTML 文本覆盖在图上。
- [ ] Hero 图本身能点题，让用户一眼识别功能和价值；不是抽象装饰。
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
- [ ] 如果需要部署或重启 cc-connect / Skills-OL，已读取项目部署说明并记录具体操作与负责人；`programmatic-seo` 不默认负责部署，但必须发现并标记这个门槛。
- [ ] 后端、gateway、cc-connect、Skills-OL 部署状态已确认或记录风险。

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
- 生产 upstream、cc-connect、Skills-OL 版本或重启要求。
- Skills-OL 写回地址、协议或部署环境变量，例如 `SKILL_RESULT_API_URL`。

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
- 结果来自 fallback。
- 还没跑不同输入变化验收。
- 还没检查移动端。
- review 页面能看但不确定 noindex/sitemap。
- 文案和 runtime 能力不一致。
