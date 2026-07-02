#!/usr/bin/env node
/**
 * Batch-translate i18n message modules from source locale folders.
 *
 * Usage:
 *   pnpm i18n:translate              # all pending locales
 *   pnpm i18n:translate --locale es  # single locale
 *   pnpm i18n:translate -- --provider=openai
 *   pnpm i18n:translate --force      # overwrite existing
 */
import { createHash } from "node:crypto";
import { access, mkdir, readFile, readdir, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BATCH_SEPARATOR = "\n<|TOMako_SPLIT|>\n";
const OPENAI_TRANSLATION_MODEL =
  process.env.OPENAI_TRANSLATION_MODEL ?? "gpt-4o-mini";

/** @type {Record<string, { source: string; googleCode?: string; method?: 'opencc' }>} */
const LOCALE_CONFIG = {
  "zh-Hant": { source: "zh", method: "opencc" },
  es: { source: "en", googleCode: "es" },
  pt: { source: "en", googleCode: "pt" },
  it: { source: "en", googleCode: "it" },
  ru: { source: "en", googleCode: "ru" },
  fr: { source: "en", googleCode: "fr" },
  ko: { source: "en", googleCode: "ko" },
};

const SKIP_PATTERN =
  /^(https?:\/\/|mailto:|\/|\{[a-zA-Z]+\}|#[\w-]+|[a-z0-9-]+(?:\/[a-z0-9-]+)*$|[A-Z_]+$)/;

let openccConverter = null;
/** @type {Record<string, string>} */
let cache = {};
let ROOT = process.cwd();
let MESSAGES_DIR = path.join(ROOT, "src/i18n/messages");
let CACHE_PATH = path.join(ROOT, ".i18n/translation-cache.json");

function configureProjectRoot(projectRoot) {
  ROOT = path.resolve(projectRoot);
  MESSAGES_DIR = path.join(ROOT, "src/i18n/messages");
  CACHE_PATH = path.join(ROOT, ".i18n/translation-cache.json");
}

async function loadCache() {
  try {
    cache = JSON.parse(await readFile(CACHE_PATH, "utf8"));
  } catch {
    cache = {};
  }
}

async function saveCache() {
  await mkdir(path.dirname(CACHE_PATH), { recursive: true });
  await writeFile(CACHE_PATH, JSON.stringify(cache, null, 2), "utf8");
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function cacheKey(text, target) {
  return createHash("sha256").update(`${target}\0${text}`).digest("hex");
}

function getArgValue(args, name) {
  return (
    args.find((a) => a.startsWith(`--${name}=`))?.split("=")[1] ??
    (args.includes(`--${name}`) ? args[args.indexOf(`--${name}`) + 1] : null)
  );
}

function resolveProvider(providerArg) {
  const provider = providerArg ?? process.env.I18N_TRANSLATION_PROVIDER ?? "auto";
  if (provider === "auto") {
    return process.env.OPENAI_API_KEY ? "openai" : "google";
  }
  if (provider !== "google" && provider !== "openai") {
    throw new Error(`Unknown provider: ${provider}. Expected google, openai, or auto.`);
  }
  return provider;
}

function shouldSkip(text) {
  if (!text || typeof text !== "string") return true;
  if (text.length <= 1) return true;
  if (/^[\d\s.,:;!?%+\-()[\]{}'"`]+$/.test(text)) return true;
  if (SKIP_PATTERN.test(text.trim())) return true;
  return false;
}

async function getOpenCC() {
  if (!openccConverter) {
    const { Converter } = await import("opencc-js");
    openccConverter = Converter({ from: "cn", to: "tw" });
  }
  return openccConverter;
}

async function withRetry(fn, retries = 6) {
  let lastError;
  for (let attempt = 0; attempt < retries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      const wait = 1500 * 2 ** attempt;
      console.warn(`  retry ${attempt + 1}/${retries} in ${wait}ms…`);
      await sleep(wait);
    }
  }
  throw lastError;
}

async function translateBatchGoogle(strings, targetLang) {
  const uncached = strings.filter((text) => !cache[cacheKey(text, targetLang)]);
  if (uncached.length === 0) return;

  const { translate } = await import("@vitalets/google-translate-api");
  const joined = uncached.join(BATCH_SEPARATOR);

  await sleep(400);
  const result = await withRetry(() =>
    translate(joined, { from: "en", to: targetLang }),
  );

  const parts = result.text.split(BATCH_SEPARATOR);
  if (parts.length !== uncached.length) {
    throw new Error(
      `Batch split mismatch: sent ${uncached.length}, got ${parts.length}`,
    );
  }

  uncached.forEach((text, index) => {
    cache[cacheKey(text, targetLang)] = parts[index];
  });
}

function getLocaleLabel(locale) {
  const labels = {
    es: "Spanish",
    pt: "Brazilian Portuguese",
    it: "Italian",
    ru: "Russian",
    fr: "French",
    ko: "Korean",
  };
  return labels[locale] ?? locale;
}

function extractJsonObject(text) {
  try {
    return JSON.parse(text);
  } catch {
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");
    if (start === -1 || end === -1 || end <= start) {
      throw new Error("OpenAI response did not contain a JSON object.");
    }
    return JSON.parse(text.slice(start, end + 1));
  }
}

async function translateBatchOpenAI(strings, targetLang) {
  const uncached = strings.filter((text) => !cache[cacheKey(text, targetLang)]);
  if (uncached.length === 0) return;
  if (!process.env.OPENAI_API_KEY) {
    throw new Error(
      "OPENAI_API_KEY is required when using --provider=openai.",
    );
  }

  const endpoint = new URL(
    "/v1/chat/completions",
    process.env.OPENAI_BASE_URL ?? "https://api.openai.com",
  );
  const body = {
    model: OPENAI_TRANSLATION_MODEL,
    temperature: 0.2,
    response_format: { type: "json_object" },
    messages: [
      {
        role: "system",
        content:
          "You are a product localization translator for a SaaS web app. Translate UI and marketing copy naturally. Preserve placeholders like {name}, markdown, URLs, product names, code identifiers, emoji, and punctuation structure. Return only JSON.",
      },
      {
        role: "user",
        content: JSON.stringify({
          targetLocale: targetLang,
          targetLanguage: getLocaleLabel(targetLang),
          sourceLanguage: "English",
          instructions:
            "Return {\"translations\":[...]} with exactly one translated string for each input, in the same order.",
          strings: uncached,
        }),
      },
    ],
  };

  const response = await withRetry(async () => {
    const res = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const detail = await res.text();
      throw new Error(`OpenAI translation failed ${res.status}: ${detail}`);
    }
    return res.json();
  });

  const content = response.choices?.[0]?.message?.content;
  if (!content) {
    throw new Error("OpenAI translation response was empty.");
  }

  const parsed = extractJsonObject(content);
  const translations = parsed.translations;
  if (!Array.isArray(translations) || translations.length !== uncached.length) {
    throw new Error(
      `OpenAI translation count mismatch: sent ${uncached.length}, got ${translations?.length ?? "non-array"}`,
    );
  }

  uncached.forEach((text, index) => {
    cache[cacheKey(text, targetLang)] = String(translations[index]);
  });
}

function collectStrings(value, set = new Set()) {
  if (typeof value === "string") {
    if (!shouldSkip(value)) set.add(value);
    return set;
  }
  if (Array.isArray(value)) {
    value.forEach((item) => collectStrings(item, set));
    return set;
  }
  if (value && typeof value === "object") {
    Object.values(value).forEach((item) => collectStrings(item, set));
  }
  return set;
}

function applyTranslations(value, lookup) {
  if (typeof value === "string") {
    return lookup.get(value) ?? value;
  }
  if (Array.isArray(value)) {
    return value.map((item) => applyTranslations(item, lookup));
  }
  if (value && typeof value === "object") {
    /** @type {Record<string, unknown>} */
    const out = {};
    for (const [k, v] of Object.entries(value)) {
      out[k] = applyTranslations(v, lookup);
    }
    return out;
  }
  return value;
}

async function buildLookup(strings, config, provider) {
  /** @type {Map<string, string>} */
  const lookup = new Map();

  if (config.method === "opencc") {
    const converter = await getOpenCC();
    for (const text of strings) {
      lookup.set(text, converter(text));
    }
    return lookup;
  }

  const list = [...strings];
  const batchSize = provider === "openai" ? 40 : 8;
  for (let i = 0; i < list.length; i += batchSize) {
    const batch = list.slice(i, i + batchSize);
    if (provider === "openai") {
      await translateBatchOpenAI(batch, config.googleCode);
    } else {
      await translateBatchGoogle(batch, config.googleCode);
    }
    for (const text of batch) {
      lookup.set(text, cache[cacheKey(text, config.googleCode)]);
    }
    console.log(`    translated ${Math.min(i + batchSize, list.length)}/${list.length} strings`);
  }

  return lookup;
}

function serializeValue(value, indent = 0) {
  const pad = "  ".repeat(indent);
  const padInner = "  ".repeat(indent + 1);

  if (typeof value === "string") {
    return JSON.stringify(value);
  }
  if (typeof value === "number" || typeof value === "boolean") {
    return String(value);
  }
  if (Array.isArray(value)) {
    if (value.length === 0) return "[]";
    const items = value.map(
      (item) => `${padInner}${serializeValue(item, indent + 1)}`,
    );
    return `[\n${items.join(",\n")}\n${pad}]`;
  }
  if (value && typeof value === "object") {
    const entries = Object.entries(value);
    if (entries.length === 0) return "{}";
    const lines = entries.map(
      ([k, v]) =>
        `${padInner}${/^[a-zA-Z_$][\w$]*$/.test(k) ? k : JSON.stringify(k)}: ${serializeValue(v, indent + 1)}`,
    );
    return `{\n${lines.join(",\n")}\n${pad}}`;
  }
  return "null";
}

function inferExportName(filePath) {
  const base = path.basename(filePath, ".ts");
  if (base === "index") return null;
  if (base === "Metadata") return "Metadata";
  return base.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

async function writeMessageModule(filePath, obj) {
  const exportName = inferExportName(filePath);
  const body = serializeValue(obj, exportName ? 1 : 0);
  const content = exportName
    ? `const ${exportName} = ${body} as const;\n\nexport default ${exportName};\n`
    : `const obj = ${body} as const;\n\nexport default obj;\n`;

  await mkdir(path.dirname(filePath), { recursive: true });
  await writeFile(filePath, content, "utf8");
}

async function listTsFiles(dir, base = dir) {
  /** @type {string[]} */
  const files = [];
  for (const entry of await readdir(dir)) {
    const full = path.join(dir, entry);
    const info = await stat(full);
    if (info.isDirectory()) {
      files.push(...(await listTsFiles(full, base)));
    } else if (entry.endsWith(".ts") && entry !== "index.ts") {
      files.push(path.relative(base, full));
    }
  }
  return files.sort();
}

async function fileExists(filePath) {
  try {
    await access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function copyIndexFiles(sourceLocale, targetLocale) {
  const sourceIndex = path.join(MESSAGES_DIR, sourceLocale, "index.ts");
  const targetIndex = path.join(MESSAGES_DIR, targetLocale, "index.ts");
  const content = await readFile(sourceIndex, "utf8");
  await mkdir(path.dirname(targetIndex), { recursive: true });
  await writeFile(targetIndex, content, "utf8");

  for (const sub of ["page", "layout", "tools", "workspace"]) {
    const subIndex = path.join(MESSAGES_DIR, sourceLocale, sub, "index.ts");
    try {
      const subContent = await readFile(subIndex, "utf8");
      const targetSub = path.join(MESSAGES_DIR, targetLocale, sub, "index.ts");
      await mkdir(path.dirname(targetSub), { recursive: true });
      await writeFile(targetSub, subContent, "utf8");
    } catch {
      // optional index
    }
  }
}

async function translateLocale(targetLocale, config, dryRun, force, provider) {
  const sourceLocale = config.source;
  const sourceDir = path.join(MESSAGES_DIR, sourceLocale);
  const targetDir = path.join(MESSAGES_DIR, targetLocale);
  const files = await listTsFiles(sourceDir);

  const providerLabel = config.method === "opencc" ? config.method : provider;
  console.log(`\n→ ${targetLocale} (from ${sourceLocale}) — ${files.length} modules via ${providerLabel}`);

  if (!dryRun) {
    await copyIndexFiles(sourceLocale, targetLocale);
  }

  /** @type {Set<string>} */
  const allStrings = new Set();
  /** @type {Map<string, unknown>} */
  const modules = new Map();

  for (const rel of files) {
    const targetPath = path.join(targetDir, rel);
    if (!force && (await fileExists(targetPath))) {
      console.log(`  ↷ skip ${rel}`);
      continue;
    }

    const sourcePath = path.join(sourceDir, rel);
    const mod = await import(pathToFileURL(sourcePath).href);
    modules.set(rel, mod.default);
    collectStrings(mod.default, allStrings);
  }

  if (allStrings.size === 0) {
    console.log("  (nothing to translate)");
    return;
  }

  console.log(`  collecting ${allStrings.size} unique strings…`);
  const lookup = dryRun ? new Map() : await buildLookup(allStrings, config, provider);

  for (const [rel, sourceObj] of modules) {
    const targetPath = path.join(targetDir, rel);
    const translated = applyTranslations(sourceObj, lookup);

    if (dryRun) {
      console.log(`  [dry-run] ${rel}`);
      continue;
    }

    await writeMessageModule(targetPath, translated);
    console.log(`  ✓ ${rel}`);
  }
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");
  const force = args.includes("--force");
  const localeArg = getArgValue(args, "locale");
  const projectArg = getArgValue(args, "project") ?? getArgValue(args, "cwd");
  const provider = resolveProvider(getArgValue(args, "provider"));

  configureProjectRoot(projectArg ?? process.cwd());
  await loadCache();

  console.log(`Project: ${ROOT}`);

  const targets = localeArg ? { [localeArg]: LOCALE_CONFIG[localeArg] } : LOCALE_CONFIG;

  for (const [locale, config] of Object.entries(targets)) {
    if (!config) {
      console.error(`Unknown locale: ${locale}`);
      process.exitCode = 1;
      continue;
    }
    await translateLocale(locale, config, dryRun, force, provider);
    await saveCache();
  }

  if (!dryRun) {
    console.log("\nDone. Cache saved to .i18n/translation-cache.json");
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
