# P0 运行时门槛

## 使用时机

涉及后端、云端 Agent、LLM Task、Skills-OL、MCP、异步状态、Skill Result、生成结果不对、重复失败、生产链路或 fallback 时，必须读取本文件。

## 默认运行时判断

Tomako Tool 页面默认假设需要云端 Agent/LLM Task/Skills-OL，除非能明确证明它是低风险、确定性、自包含的浏览器逻辑。

必须走云端 Agent/LLM Task/Skills-OL 的常见情况：

- 用户提供产品 URL、官网、App 链接、品牌或业务上下文。
- 需要抓取、读取、总结、分析、生成、推荐、评分或长文档。
- 输出是协议、政策、报告、策略、候选方案、创意建议、合规草案或风险判断。
- 结果依赖用户当前输入，而不是固定模板。
- 需要把结构化结果写回前端。

上下文驱动的生图工具也属于 Agent-backed 工具。只要生图 Prompt 需要产品 URL、品牌上下文、用户表单选项、视觉风格、卖点提炼、套图规划或多资产编排，就必须把 Prompt 构造、资产计划和 `/api/image/generate` 调用放到 Skills-OL Skill/script 中。前端只能提交 `/api/llm/tasks`、读取 `/api/skill-results/{taskId}`、轮询公开图片状态并渲染结果；不得在浏览器组件里直接拼最终生图 Prompt 或批量编排 `/api/image/generate` 作为最终结果链路。

可以纯前端的情况：

- 计算、转换、格式化、静态检查、简单清单等确定性逻辑。
- 浏览器内可以可靠完成。
- 不涉及法律、隐私、财务、安全、专业判断或用户业务上下文。
- 明确标注为本地 demo 或模板工具，不冒充真实 AI/Agent 能力。

## 高风险工具

法律、隐私、合规、财务、安全、政策类生成器，不能做成浏览器模板拼接。

必须具备：

- 云端 Agent/LLM 分析。
- Skills-OL 结构化写回。
- 风险提示。
- 缺失信息。
- 人工或专业复核清单。
- 明确免责声明。

输出只能定位为草案、辅助分析、复核材料或起点，不能宣称最终法律、财务、安全或合规意见。

## Agent-backed 结果源

Agent-backed 工具的最终用户结果只能来自：

```text
GET /api/skill-results/{taskId}
```

且必须满足：

- envelope 有效。
- `resultType` 符合预期。
- `resultJson` schema 有效。
- 内容明显来自当前用户输入。

禁止把以下内容作为最终结果：

- 前端模板。
- 本地预览。
- raw `llmOutput`。
- Agent stdout。
- demo/sample/fallback 数据。
- 脚本内固定候选、固定报告、固定草案。
- 旧 task 的结果。

如果结构化结果缺失，应继续等待、显示可恢复状态或展示分类错误，不得伪造结果。

## 交互式生图工具

产品海报、品牌物料、社媒宣传图、广告图、Product Hunt launch 图、OG 图、App 上架图等交互式生图工具，默认必须走云端 Agent + Skills-OL + Skill Result。

标准链路：

```text
前端 POST /api/llm/tasks
  -> Agent 读取 Skills-OL 对应 Skill
  -> Skills-OL 脚本调用 /api/image/generate
  -> 脚本 POST /api/skill-results
  -> 前端 GET /api/skill-results/{taskId}
  -> 前端展示 resultJson 中的 imageUrl / imageTaskId
```

禁止把以下链路作为最终公开工具实现：

- 前端直接把表单拼成 prompt 后调用 `/api/image/generate`。
- 前端生成 SVG、HTML、CSS、canvas 或模板海报后冒充“AI 生图”。
- Agent 未写回 `skill-results` 时，用本地 fallback 图片、旧 task 图片或 demo 图当作成功结果。

例外只适用于明确标注的内部 demo、低风险测试页或用户明确要求的本地模板工具。即使例外成立，也必须在页面和交付说明中写清楚不是 Agent-backed 生产链路。

调试生图质量时，优先修改 Skills-OL 对应 Skill、脚本和 prompt strategy；前端只负责提交结构化 brief、展示异步状态、校验 `resultType/schema` 和渲染写回结果。

## 长报告渐进式 Skill Result

当 Agent-backed Tool 会输出长报告、多个可见分析模块、分阶段清单或较长策略文档时，必须评估是否采用渐进式 Skill Result，而不是让用户一直等待 final result。

适用判断：

- 结果天然由多个用户可见模块组成，例如摘要、证据、机会、建议、风险、来源、下一步。
- 单次生成时间较长，用户在 10 到 20 秒内看不到任何真实内容会明显降低信任。
- 模块之间有稳定阅读顺序，前几个模块可以先给用户带来价值。

P0 规则：

- `resultJson` 应能显式区分 `partial` 和 `final`，例如 `reportStatus: "partial" | "final"`。
- partial result 使用累计快照，不使用需要前端复杂合并的 delta patch。
- partial schema 应允许未完成模块缺省；final schema 再要求完整字段。
- 前端在 task 运行中必须继续轮询 `GET /api/skill-results/{taskId}`，不能只等 SSE final 信号。
- 一旦看到有效 partial，前端必须保留已完成内容；final 暂时未到、读取超时或 SSE 抖动不能把页面切成整页失败。
- `completedSections`、`inProgressSection` 或等价字段应反映用户可见模块，不是后端内部 JSON 字段。
- Agent prompt 不是唯一约束。Skills-OL 脚本应尽量校验 partial 的模块顺序、一次新增粒度和 schema；违反渐进契约时 fail fast。
- 可见模块的发布顺序应尽量和前端展示顺序一致；内部可以并发分析，但写回层要按用户能理解的顺序发布。

如果不采用渐进式输出，必须能说明原因，例如结果很短、生成很快、模块不可独立展示，或当前后端/Skill Result 能力确实不支持。

## 核心输出验收

请求成功、task 创建成功、schema 能 parse、卡片能渲染，都不等于工具可用。

Agent 生成类工具必须验证：

1. 提交两个差异明显的有效输入。
2. 检查输出、理由、标签、警告、文档结构是否随输入合理变化。
3. 直接查看 raw Skill Result，不只看 UI 卡片。
4. 排除固定 fallback、sample 数据或脚本自造结果。
5. 测一个明显 placeholder 输入，确认会在提交前被阻止。

如果两次生成仍失败、重复、无关或明显没有使用当前输入，停止 UI 打磨，进入完整调试协议。

## 当前 LLM Task 流程

标准链路：

```text
前端 POST /api/llm/tasks
  -> 后端创建 llm task 和 turn
  -> 后端注入 [LLM_TASK_ID=...]
  -> cc-connect 把 prompt 发给 Agent
  -> Agent 使用 Skills-OL Skill 和脚本
  -> 脚本 POST /api/skill-results
  -> 前端通过 SSE 或轮询感知 skill_result
  -> 前端 GET /api/skill-results/{taskId}
  -> 前端渲染结构化结果
```

常见接口：

- `POST /api/llm/tasks`
- `GET /api/llm/tasks/{taskId}`
- `GET /api/llm/tasks/{taskId}/turns`
- `GET /api/llm/tasks/{taskId}/events`
- `POST /api/llm/tasks/{taskId}/messages`
- `POST /api/llm/tasks/{taskId}/confirm`
- `POST /api/skill-results`
- `GET /api/skill-results/{taskId}`

`scene` 当前主要是 metadata，不是严格路由器。真正路由依赖 prompt、Skill 和脚本。

## 生产部署闭环

Agent-backed 工具不是“代码写完即可测试”。只要变更涉及前端 LLM task service、后端接口/状态机、Skills-OL Skill、Skills-OL 脚本、resultType、schema、cc-connect 运行目录或环境变量，就必须判断远端部署状态。

### Skills-OL 修改后强制部署

这是超强 P0 规则：修改 Agent Skill 后不部署，就等于没有修改云端 Agent。

触发条件：

- 修改 `Skills-OL/skills/**/SKILL.md`。
- 修改 `Skills-OL/*.mjs` 或任何被在线 Agent 调用的脚本。
- 修改 prompt strategy、参数、依赖、result writer、resultType、schema、写回字段或图片生成编排。
- 修改某个 Tool 对应的在线 Skill 说明、候选生成、筛选、校验、写回或 dry-run 逻辑。

强制动作：

- 修改完成后，默认立即进入 `$deploy-skills-ol` / `deploy-skills-ol` 流程，把变更部署到 cc-connect 运行环境。
- 如果部署脚本要求先 push 到 Git，必须确认 Skills-OL 变更已 push；未 push 时不能认为远端会生效。
- 部署必须记录本地 commit、远端 commit、是否执行 npm install、是否重启 cc-connect、服务状态和部署报告。
- 部署后至少跑一次真实链路 QA：前端提交 -> 云端 Agent 使用新 Skill -> Skill Result 写回 -> 前端读取并渲染。

不能自动部署时：

- 如果缺 SSH key、部署权限、Git push 权限、发布窗口、服务器信息或存在生产风险，必须主动询问用户是否需要部署或是否授权继续。
- 如果用户暂不部署，必须把“Skills-OL 未部署，云端 Agent 仍可能运行旧版本”写成 blocker。
- 未完成部署闭环时，禁止继续用云端测试结果判断新 Skill 是否生效，禁止宣称 Agent 效果已修复、页面可测试或功能完成。

P0 规则：

- 如果用户目标是“能测试”“上线”“发布”“review 环境可用”或“直接实现并验证”，AI 必须把远端部署纳入任务闭环。
- 有明确部署文档、权限和环境时，必须按项目部署说明执行远端部署或重启，并记录部署目标、命令、commit/版本、时间和结果。
- 没有权限、服务器信息、密钥或部署窗口时，必须把它标为 blocker，说明缺什么、谁需要处理、应该执行哪些命令；不能把页面说成“已完成”或“可测试”。
- 本地 `pnpm build`、dry-run、schema 校验、mock、旧 task、脚本本地执行都不能替代远端部署后的 live QA。
- 本地前端代理到生产时，尤其要确认生产后端、cc-connect 和 Skills-OL 已经更新；否则本地页面会调用旧生产链路。
- 改了 Skills-OL 文件后，必须确认 cc-connect 运行目录已拉取新代码并重启；只把代码推到 Git 远端不等于 Agent runtime 已更新。
- 改了 Tomako-portal 后端后，必须确认目标后端环境已部署或明确记录未部署；只改本地 Java 代码不能证明线上 API 可用。
- 改了 Tomako 前端后，必须确认目标前端环境已部署或明确记录未部署；本地页面可见不等于线上页面可测。

完成条件三选一：

1. **已部署并已验证**：远端前端/后端/Skills-OL/cc-connect 都在目标版本，且完成生产或目标环境 live QA。
2. **无需部署**：本次没有改变任何远端运行时依赖，且使用当前生产版本即可完成 live QA。
3. **明确阻塞**：缺少部署权限、服务器信息、密钥、CI/CD、发布窗口或负责人，已写清阻塞原因和下一步命令。

禁止用“需要部署”一句话草草带过。交付时必须明确当前属于以上哪一种。

## 异步状态

任务状态：

```text
PENDING -> STREAMING -> AWAITING_INPUT -> SUCCEEDED
                         \-> messages -> STREAMING
any -> FAILED
```

P0 规则：

- `AWAITING_INPUT` 不等于失败。
- `SUCCEEDED` 不等于 Skill Result 一定存在。
- 初期 `/skill-results/{taskId}` 404 可能是正常写回时序。
- SSE `error` 可能是传输抖动，不能覆盖后来的有效结果。
- `skill_result` 事件后仍要容忍短暂读取延迟。

只有以下情况才进入最终失败：

- 提交失败且没有 taskId。
- task 明确 `FAILED`。
- 有界宽限轮询后仍无结构化结果。
- `resultType` 错误。
- schema 无效。
- 日志证据显示 Skills-OL 没有写回。

## 前端状态机

建议状态：

```text
idle
submitting
streaming / waiting
partial
awaiting_result
awaiting_final
done
failed
```

失败类别建议：

- `submit_failed`
- `upstream_unavailable`
- `task_failed`
- `result_timeout`
- `result_schema_invalid`
- `agent_writeback_failed`
- `content_not_input_derived`
- `partial_degraded`

用户文案可以简化，但开发诊断必须区分层级。

## Proxy 诊断

本地浏览器看到 `localhost:3000/api/...` 不代表后端是本机。

先检查：

- `NEXT_PUBLIC_API_BASE_URL`
- `NEXT_PUBLIC_MOCK_API`
- `API_PROXY_TARGET`
- `src/app/api/[...path]/route.ts`
- API wrapper。
- Network 里的真实状态码和响应体。
- 上游地址是否是生产，例如 `https://tomako.ai/api/...`。

不要在没确认代理目标前告诉用户“本地后端没启动”。

## 重复失败调试协议

以下情况必须立即使用本协议：

- 核心生成失败两次。
- 不同输入返回相同或可疑输出。
- 用户说“还是不工作”。
- 结果看起来像 demo/fallback。

先停止：

- 不要继续点生成。
- 不要改文案或 UI 掩盖问题。
- 不要用旧 task 或 mock 证明修复。

收集：

- 用户原始输入和前端 payload。
- `POST /api/llm/tasks` URL、proxy target、状态码、响应体。
- taskId、status、turns、events。
- raw `/api/skill-results/{taskId}` envelope 和 `resultJson`。
- 前端 normalizer 后的结果。
- prompt payload 和要求 Agent 执行的脚本命令。
- Skills-OL 实际写回 URL、协议、域名、HTTP 状态码、是否发生 301/302 跳转、最终方法是否仍是 POST、响应体摘要。
- Skills-OL Skill/script 路径、本地版本、部署版本、cc-connect 是否重启。
- 所有 sample、fixture、fallback、demo 数据入口。

分类：

- 表单误拦截。
- 提交失败。
- upstream 5xx。
- Agent 没按契约给候选/证据/理由。
- 脚本契约有漏洞，接受缺失输入并自造结果。
- 脚本没有写回。
- 写回地址错误：使用 http、旧 IP、旧域名、错误 path 或发生 301/302 导致 POST/body 丢失。
- schema 前后端不一致。
- 内容不是当前输入派生。
- 部署版本不一致。

退出条件：

- 有效输入得到结构化结果。
- 不同输入产生合理不同输出。
- placeholder 输入提交前被拦截。
- 缺失 Agent 核心产物时失败而不是 fallback。
- 远端部署/restart 状态已闭环：已部署并验证、无需部署，或明确阻塞。

## Skills-OL 写回要求

在线 Skill/script 必须：

- 支持 `--task-id` 和 `--api-url`。
- 可从 `LLM_TASK_ID`、`SKILL_RESULT_API_URL` 读取 fallback。
- POST `/api/skill-results`。
- 使用生产可用的规范 HTTPS 写回地址。Tomako 生产写回默认应使用 `https://tomako.ai` 或团队确认的 HTTPS API 域名；不要在 Agent prompt、脚本默认值、systemd 环境或示例命令里硬编码 `http://` IP 地址。
- 写回地址不得依赖 301/302 跳转。POST 到 http 或旧域名后被跳转，可能被运行时、fetch、curl、代理或网关改写方法、丢 body，导致写回失败但脚本误以为请求已发出。
- 脚本必须把最终写回 URL、HTTP 状态码和非 2xx 响应摘要暴露到日志或错误中；出现 3xx、4xx、5xx 都应视为写回失败，而不是继续返回成功。
- 写入 `taskId`、`skillName`、`resultType`、`sourceUrl?`、`resultJson`、`summary?`。
- `resultJson` 使用 camelCase。
- 失败时抛错或非 0 退出。
- Agent 最终回复简短，不粘贴完整 JSON。
- 创意、建议、判断类工具必须保留 Agent 给出的候选、证据、理由；脚本只筛选、校验、格式化和写回。

## 多轮修改

文档、报告、协议、计划类结果如果支持修改，应使用：

```text
POST /api/llm/tasks/{taskId}/messages
```

规则：

- 只有已有有效结构化结果后才启用修改。
- 修改仍由 Agent 产出新的结构化 Skill Result。
- 前端不能直接 patch 最终文档冒充 Agent 修改。
- 修改时保留上一版有效结果。

## 运行时验收

- [ ] 已证明运行时选择正确，不是把高上下文工具降级成前端模板。
- [ ] Agent-backed 结果只来自结构化 Skill Result。
- [ ] 没有本地预览、模板 fallback、raw `llmOutput` final render。
- [ ] 两个不同有效输入通过变化验收。
- [ ] placeholder 输入在提交前被拦截。
- [ ] 异步状态容忍 `AWAITING_INPUT`、短暂 404 和 SSE error。
- [ ] 长报告或多模块工具已评估 progressive partial result；若采用，partial/final schema、累计快照、模块顺序和前端保留 partial 均已验证。
- [ ] 错误按层分类。
- [ ] 代理目标已确认。
- [ ] Skills-OL 写回脚本已验证。
- [ ] 写回地址使用 HTTPS 规范域名，没有 http IP、301/302 跳转、方法改写或 body 丢失风险。
- [ ] 如本轮修改了 `Skills-OL/` Agent Skill 或脚本，已自动执行 `$deploy-skills-ol` 部署闭环；若无法部署，已主动询问用户或标为 blocker。
- [ ] 已完成一次真实 live QA：submit -> Agent/Skills-OL writeback -> fetch `/api/skill-results/{taskId}` -> 前端渲染。lint、build、dry-run、schema 校验不能替代这一步。
- [ ] 远端部署闭环已完成：前端、后端、Skills-OL、cc-connect 的目标版本和重启状态已确认；若未完成，已标为 blocker，不能宣称可测试或完成。
