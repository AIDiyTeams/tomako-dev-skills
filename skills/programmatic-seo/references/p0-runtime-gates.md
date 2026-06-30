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
awaiting_result
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
- 发布记录说明是否需要部署/restart Skills-OL 或 cc-connect。

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
- [ ] 错误按层分类。
- [ ] 代理目标已确认。
- [ ] Skills-OL 写回脚本已验证。
- [ ] 写回地址使用 HTTPS 规范域名，没有 http IP、301/302 跳转、方法改写或 body 丢失风险。
- [ ] 已完成一次真实 live QA：submit -> Agent/Skills-OL writeback -> fetch `/api/skill-results/{taskId}` -> 前端渲染。lint、build、dry-run、schema 校验不能替代这一步。
- [ ] 生产部署、cc-connect、Skills-OL 版本和重启要求已记录。
