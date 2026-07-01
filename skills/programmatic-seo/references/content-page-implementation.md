# 内容页工程落地规范

## 使用时机

当任务涉及 Tomako 内容型 SEO 页面落地、修改、检查或发布时读取本文件。内容页当前主要使用 MDX，不走 ToolSpec；工具页仍走 `tool-page-implementation.md`。

## 当前代码事实

Tomako 内容页主要落点：

| 栏目 | URL | 内容目录 | 详情路由 |
| --- | --- | --- | --- |
| Blog | `/{locale}/blog/{slug}` | `content/blog/{locale}/` | `src/app/[locale]/blog/[slug]/page.tsx` |
| Template | `/{locale}/template/{slug}` | `content/template/{locale}/` | `src/app/[locale]/template/[slug]/page.tsx` |
| MCP | `/{locale}/mcp/{slug}` | `content/mcp/{locale}/` | `src/app/[locale]/mcp/[slug]/page.tsx` |
| Tools | `/{locale}/tools/{slug}` | `src/features/tools/` | `src/app/[locale]/tools/[slug]/page.tsx` |

Tools 是 code-first，不使用 MDX。不要为了新增内容页去创建 per-page `page.tsx`，除非用户明确要求新增栏目或当前架构无法支持。

内容页是 content-first，但不能是裸 MDX。MDX 负责正文和 frontmatter，页面体验必须由共享 Content Shell、MDX components 和 CTA 组件承接。

当前内容页工程原则：

- 不为每篇 blog/template/mcp 新建独立 route。
- 不让 AI 每次生成整页 HTML 或一套全新 React layout。
- 优先补强共享 shell 和 MDX 组件，再让每篇 MDX 填内容。
- Blog 详情页应使用 `ContentPageShell` 或等价产品化外壳。
- `ContentExploreCta` 承接 `conversionTarget`、`parentToolSlug` 和下一步动作。
- `src/lib/content/mdx-components.tsx` 负责正文里的 H2/H3、段落、表格、图片、引用和链接样式。
- 如果页面看起来像普通 Markdown 文档，先修共享 shell / MDX components，不要只在单篇 MDX 里堆 HTML。

## 必读本地文档

做内容页工程落地时，同时读取：

- `Tomako/docs/modules/marketing-content-mdx.md`
- `Tomako/docs/modules/blog-generate.md`（如果涉及内部生成器或内容生产流程）
- `Tomako/src/lib/content/loader.ts`
- `Tomako/src/lib/content/mdx-components.tsx`
- `Tomako/src/components/content/content-page-shell.tsx`（如存在）
- `Tomako/src/components/content/content-explore-cta.tsx`
- 对应路由文件：`src/app/[locale]/blog/[slug]/page.tsx`、`template/[slug]/page.tsx` 或 `mcp/[slug]/page.tsx`
- `Tomako/src/app/sitemap.ts`（发布前确认 sitemap 行为）

当前源码永远优先于文档；如冲突，以源码为准并在答复里说明。

## 文件创建规则

新增内容页通常只新增或修改 MDX：

```text
content/blog/zh/{slug}.mdx
content/blog/en/{slug}.mdx

content/template/zh/{slug}.mdx
content/template/en/{slug}.mdx

content/mcp/zh/{slug}.mdx
content/mcp/en/{slug}.mdx
```

要求：

- slug 使用小写英文、数字和短横线。
- zh/en 默认同 slug。
- 可以阶段性只上一种语言，但必须说明缺另一语言的 SEO 风险和补齐计划。
- 不把营销长文放入 `src/constants/`。
- 不把公开工具页写进 `content/tools/`；历史文件只能作为迁移前参考。

## Frontmatter

当前 loader 要求必填：

```yaml
---
title: "页面标题"
description: "页面描述"
category: "分类"
keywords: ["关键词 A", "关键词 B"]
updatedAt: "2026-06-30"
readingTime: "6 min"
---
```

可选：

```yaml
intro: "详情页导语"
publishedAt: "2026-06-30"
featured: true
image: "/content/blog/example.png"
```

注意：

- `keywords` 必须是数组。
- `updatedAt` 使用 `YYYY-MM-DD`。
- description 要承接搜索意图和用户价值，不只复述 title。
- `image` 指向 `public/` 下可访问路径或可靠 https URL。

## MDX 正文规则

允许：

- `##` / `###` 标题。不要在正文使用 `#`，页面已有 H1。
- 段落、列表、引用、粗体、代码、GFM 表格。
- 站内链接和站外链接。
- 原生 Markdown 图片。
- 经过 loader 注入的共享 MDX 组件。

禁止：

- 在 MDX 里写 React 数据请求、`fetch`、服务端逻辑、环境变量或密钥。
- 把动态交互、复杂工具或 Agent 结果写成静态 MDX。
- 把演示数据写成真实客户案例。
- 复制大段第三方内容。
- 为 SEO 创建高度重复的近似页面。
- 在每篇 MDX 里复制整套 HTML 页面结构、Hero、侧栏和 CTA 样式。
- 用 MDX 内联 HTML 代替应该沉淀到共享 Content Shell / MDX components 的 UI。

## 图片落地

图片文件放到 `public/`，推荐：

```text
public/content/blog/{slug}-hero.png
public/content/blog/{slug}-example.png
public/content/template/{slug}-preview.png
public/content/mcp/{slug}-workflow.png
```

MDX 写法：

```mdx
![图片说明](/content/blog/{slug}-example.png)
```

要求：

- alt 文案写给用户和搜索引擎，不堆关键词。
- 图片必须服务某个段落、例子、模板预览或判断标准。
- 需要原创视觉时遵循 `p0-asset-gates.md`。
- 不把图片只放在 `content/` 目录下。

## 内链规则

站内链接不要带 `/{locale}/` 前缀：

```mdx
查看 [Twitter GIF 下载器](/tools/twitter-gif-downloader)。
复制 [GTM 上线简报模板](/template/gtm-launch-brief)。
继续阅读 [站点结构 SEO](/blog/site-structure-seo)。
```

每篇内容页应自然包含：

- 1 个上游 hub 或栏目入口。
- 2 到 5 个相关内容、工具或模板链接。
- 1 个主要 CTA 链接到 Tomako 能承接的下一步。

不要为了数量硬加内链。内链锚文本必须描述目标页价值。

## 内容生成器边界

`/blog/generate` 是内部内容生成辅助页，必须保持 noindex。它可以帮助产出 spec 或草稿，但最终公开内容仍由工程写入 `content/{kind}/{locale}/{slug}.mdx`。

不要把内部生成器当作公开 SEO 页面，也不要把内部 prompt、草稿状态或 localStorage 逻辑暴露给用户。

## 上线验证

按变更范围执行：

```bash
pnpm lint
pnpm build
```

内容页发布前必须验证：

- `/zh/{kind}/{slug}` 和 `/en/{kind}/{slug}` 路由行为。
- 缺语言版本时的 404/noindex/发布风险。
- frontmatter 必填字段。
- 页面使用共享 Content Shell 或等价产品化外壳，不是裸 MDX 文档。
- 图片 URL 可访问。
- 站内链接无坏链，且不带 locale 前缀。
- sitemap、canonical、hreflang、robots/index 决策已确认。
- 页面正文关键内容是可抓取 HTML，不只在图片里。

若 sitemap 尚未收录该栏目或行为未确认，不能宣称 SEO-ready；必须写入风险和下一步。

## 交付说明

最终答复中说明：

- 新增/修改了哪些 MDX 和图片。
- 主关键词、页面类型和内容集群关系。
- 主要内链和 CTA。
- 验证命令。
- sitemap/index/hreflang 是否已确认。
- 是否还有双语、图片、来源或事实验证风险。
