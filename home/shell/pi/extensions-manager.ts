// extensions-manager.ts — pi 个人扩展:项目级(本地)插件与插件组管理
//
// 契约锚点(按本机 pi 1.1.0 逐条核对;升级 pi 后按下列名称复核,不要只对照 dist 行号):
//   A 级——官方 prose/示例明确背书:pi.registerCommand/getArgumentCompletions(docs/extensions.md、
//     examples/extensions/commands.ts);ctx.cwd/mode/hasUI/reload(docs/extensions.md、
//     docs/rpc-extension-ui.md,类型为包根导出的 ExtensionCommandContext);
//     ctx.ui.notify/confirm/custom/setStatus(docs/tui.md、examples/extensions/*);
//     CONFIG_DIR_NAME/getAgentDir/PI_CODING_AGENT_DIR、pi install 的源语法与身份语义
//     (docs/configuration.md、docs/environment-variables.md、docs/packages.md);
//     jiti 直跑 TS 与用户扩展目录(docs/extensions.md);--approve(docs/cli.md)。
//   B 级——仅包根导出面(含类型注释),无 prose 文档:DefaultPackageManager/PackageManager/
//     ProgressEvent/SettingsManager、SettingsManagerCreateOptions.projectTrusted、
//     RegisteredCommand/AutocompleteItem、ctx.isProjectTrusted()。
//   C 级——依赖 dist 内部行为或本文件近似实现,风险集中在 §2 的身份/路径近似与 §3 的子进程 stdio/TUI 暂停。
//
// 范围:仅管理声明于 <项目>/<CONFIG_DIR_NAME>(默认 .pi)/settings.json 的本地插件;用户级插件请用 pi 原生
// `pi install <source>`(不带 -l)与 pi update。扩展自身不直接启动子进程,安装/卸载
// 由 pi 的 DefaultPackageManager(程序化 API)完成。
//
// ── 使用方法 ──
//
// 1. 安装(单文件个人扩展):把本文件拷贝或软链到 pi agent 目录下的 extensions/(默认
//    ~/.pi/agent/extensions/,agent 目录可用 PI_CODING_AGENT_DIR 覆盖)即可,
//    pi 启动时自动经 jiti 直接运行 TS 源码,无需编译;对所有项目生效。
//    开发期可单次加载:pi --extension /path/to/extensions-manager.ts
//
// 2. 命令:/exts <子命令> [目标...] [-y](目标支持 Tab 补全:组名/已配置源;
//    clean/list/help 不接受目标)
//      /exts list                       查看项目插件与插件组
//      /exts add npm:pi-lens npm:x@1.2  安装(源语法同 pi install;按身份跳过,不改版本)
//      /exts remove npm:x               卸载(未声明则不改配置)
//      /exts add-group init             安装一个/多个插件组
//      /exts remove-group init          卸载插件组(不删除组定义)
//      /exts clean                      卸载本项目全部插件(默认确认,-y 跳过)
//      /exts help                       完整帮助
//    选项 -y / --yes:免交互确认(项目未受信任时直接写入本地配置,不保存信任决定)。
//
// 3. 插件组定义(JSON;两个位置均可选,同名组项目级整体覆盖全局级):
//      全局 pi agent 目录下的 extension-groups.json(默认 ~/.pi/agent/extension-groups.json)
//      项目 <项目>/<CONFIG_DIR_NAME>(默认 .pi)/extension-groups.json
//    {
//      "coding": {
//        "description": "编码集合",
//        "packages": ["npm:pi-lens"]
//      }
//    }
//    packages 内的相对本地路径按项目根解析(与 pi install 输入语义一致;settings.json
//    里 pi 写回的相对路径则以项目的 <CONFIG_DIR_NAME>(默认 .pi)为基准)。
//
// 4. 信任与确认:项目未受信任时,写操作先弹确认(或 -y 跳过;无 UI 模式必须 -y),
//    list 始终可用;用内置 /trust 命令可持久授予项目信任。

import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  CONFIG_DIR_NAME,
  DefaultPackageManager,
  SettingsManager,
  getAgentDir,
} from "@earendil-works/pi-coding-agent";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  PackageManager,
  ProgressEvent,
} from "@earendil-works/pi-coding-agent";

// ────────────────────────────── §0 常量 ──────────────────────────────

const COMMAND_NAME = "exts";
const GROUPS_FILE = "extension-groups.json";
/** 项目配置目录名,跟随 pi 的 piConfig.configDir(默认 .pi)。 */
const PI_SETTINGS_DIR = CONFIG_DIR_NAME;
const STATUS_KEY = "extensions";
const YES_FLAGS = new Set(["-y", "--yes"]);

const SUBCOMMANDS = ["add", "add-group", "remove", "remove-group", "clean", "list", "help"] as const;
type Subcommand = (typeof SUBCOMMANDS)[number];
/** 接受目标参数的子命令;其余(clean/list/help)只接受 -y。 */
const TARGET_SUBCOMMANDS = [
  "add",
  "remove",
  "add-group",
  "remove-group",
] as const satisfies readonly Subcommand[];

// 短描述只留动宾短语(补全菜单与 help 列表用);边界语义收进 HELP_TEXT 说明行
const SUBCOMMAND_DESC = {
  add: "安装插件",
  "add-group": "安装插件组",
  remove: "卸载插件",
  "remove-group": "卸载插件组",
  clean: "卸载全部插件",
  list: "查看插件",
  help: "帮助",
} satisfies Record<Subcommand, string>;

const HELP_TEXT = [
  "/exts — 管理项目插件与插件组",
  "用法: /exts <子命令> [目标...] [-y](clean/list/help 不接受目标)",
  "子命令:",
  ...SUBCOMMANDS.map((s) => `  ${s.padEnd(14)} ${SUBCOMMAND_DESC[s]}`),
  "说明: add 的源语法同 pi install(npm:x / git:... / 本地路径);已按身份配置的包跳过、",
  "  不改已声明版本(变更请先 remove);remove 已声明即卸载实体并移除声明,",
  "  未声明则不改配置(pi 仍会尝试卸载实体);remove-group 只卸载插件,不删除组定义;",
  "  clean 卸载本项目全部插件(默认确认,-y 跳过)。",
  "选项: -y / --yes  免交互确认(项目未受信任时直接写入本地配置)",
  `组配置: pi agent 目录(默认 ~/${CONFIG_DIR_NAME}/agent,可被 PI_CODING_AGENT_DIR 覆盖)下的`,
  `  ${GROUPS_FILE} 与 <项目>/${CONFIG_DIR_NAME}/${GROUPS_FILE},同名组项目级覆盖全局级`,
  "注意: 仅管理项目级插件;用户级插件请使用 pi install(不带 -l)与 pi update。",
].join("\n");

// ────────────────────────────── §1 类型 ──────────────────────────────

/** 组定义;packages 元素沿用 pi install 源语法(npm:x / git:... / 本地路径)。 */
export interface GroupDef {
  description?: string;
  packages: string[];
}

export type GroupTable = Record<string, GroupDef>;

export interface GroupTables {
  global: GroupTable;
  project: GroupTable;
  /** 加载/解析过程中发现的问题(文件级),按行聚合。 */
  errors: string[];
  globalPath: string;
  projectPath: string;
}

export interface OpResult {
  /** 源串或组名 */
  target: string;
  status: "ok" | "skipped" | "failed";
  detail?: string;
}

/** 用法错误:消息面向用户,附带完整帮助。 */
class CommandUsageError extends Error {}

/** 与 CompletionItem(pi-tui AutocompleteItem)结构兼容,避免额外 import。 */
interface CompletionItem {
  value: string;
  label: string;
  description?: string;
}

// ──────────────────────────── §2 纯函数 ────────────────────────────
// 本节不触碰 ctx / 包管理器 / 文件系统,可独立测试。

/** 参数串切词:空白分隔,支持成对单/双引号(用于含空格的本地路径)。引号未闭合抛错。 */
export function tokenizeArgs(input: string): string[] {
  const tokens: string[] = [];
  let current = "";
  let quote: '"' | "'" | undefined;
  let pending = false; // 已出现引号但内容为空,也视为一个 token(如 "")
  for (const ch of input) {
    if (quote) {
      if (ch === quote) {
        quote = undefined;
      } else {
        current += ch;
      }
      continue;
    }
    if (ch === '"' || ch === "'") {
      quote = ch;
      pending = true;
      continue;
    }
    if (/\s/.test(ch)) {
      if (current !== "" || pending) {
        tokens.push(current);
        current = "";
        pending = false;
      }
      continue;
    }
    current += ch;
  }
  if (quote) throw new CommandUsageError("引号未闭合");
  if (current !== "" || pending) tokens.push(current);
  return tokens;
}

/** 解析子命令与目标;flag 位置不限。用法错误抛 CommandUsageError。 */
export function parseInvocation(tokens: string[]): {
  subcommand: Subcommand;
  targets: string[];
  yes: boolean;
} {
  if (tokens.length === 0) throw new CommandUsageError("缺少子命令");
  const [first, ...rest] = tokens;
  if (!(SUBCOMMANDS as readonly string[]).includes(first)) {
    throw new CommandUsageError(`未知子命令 "${first}"`);
  }
  const subcommand = first as Subcommand;
  const targets: string[] = [];
  let yes = false;
  for (const token of rest) {
    if (YES_FLAGS.has(token)) yes = true;
    else if (token.trim() === "") throw new CommandUsageError("目标不能为空");
    else targets.push(token);
  }
  const acceptsTargets = (TARGET_SUBCOMMANDS as readonly string[]).includes(subcommand);
  if (!acceptsTargets) {
    // clean/list/help 带目标时报错,避免静默忽略目标却执行全量操作
    if (targets.length > 0) throw new CommandUsageError(`"${subcommand}" 不接受目标参数`);
    return { subcommand, targets, yes };
  }
  if (targets.length === 0) {
    throw new CommandUsageError(`"${subcommand}" 需要至少一个目标`);
  }
  return { subcommand, targets, yes };
}

/**
 * npm 源取包名(与 pi 私有方法 DefaultPackageManager.parseNpmSpec 的正则逐字一致,
 * 见 dist/core/package-manager.d.ts;B 级:无常量/文档背书,已用探针逐条比对)
 * npm:name@ver → name,@scope/name@ver → @scope/name。
 */
export function parseNpmName(spec: string): string {
  const match = spec.match(/^(@?[^@]+(?:\/[^@]+)?)(?:@(.+))?$/);
  return match?.[1] ?? spec;
}

/**
 * git 源归一化(C 级:pi 用 hosted-git-info 取 host/path,本文件不复刻该第三方库):
 * 只处理 pi 认可的两种写法(见 nonLocalIdentity)——带 `git:` 前缀的简写,或无前缀的协议 URL。
 * 协议 URL 分支对齐 pi 的 new URL() 解析:身份只取 hostname + pathname(丢端口与凭据);
 * scp 风格(git:git@host:path)按首个冒号转斜杠;两者都要再去 @ref、#ref(.git 后缀)。
 * 已用探针逐条比对 1.1.0:docs/packages.md 列出的形态(npm: / git:host/path@ref / https:// / 本地路径)
 * 全部与 pi 一致;残留偏差只出现在 hosted-git-info 与 URL 都不认识的极端形态,后果仅是多装/多卸一次。
 * 升级复核:dist/utils/git.js 的 parseGitUrl/splitRef、dist/core/package-manager.js 的 getPackageIdentity。
 */
export function normalizeGitSource(source: string): string {
  let s = source.trim().replace(/^git:/, "");
  if (/^(https?|ssh|git):\/\//i.test(s)) {
    // 协议 URL:对齐 pi 的 new URL(url) 分支 —— host 取 hostname(去 scheme、凭据、端口)
    s = s
      .replace(/^[a-z][a-z0-9+.-]*:\/\//i, "")
      .replace(/^[^/@]*@/, "")
      .replace(/^([^/:]+):\d+/, "$1");
  } else {
    // scp 风格 git@host:path(或 git:host/path):首个冒号即 host/path 分隔符
    s = s.replace(/^git@/, "").replace(/:/, "/");
  }
  const slash = s.lastIndexOf("/");
  const at = s.lastIndexOf("@");
  if (at > slash) s = s.slice(0, at); // 去 @ref
  s = s.replace(/#.*/, ""); // 去 #ref(committish)
  s = s.replace(/\.git$/, "");
  return s;
}

/**
 * ~ 与 file:// 的展开;不属这两种形态时返回 undefined(调用方再按基准拼相对路径)。
 * 非法 file:// URL 回退为按普通路径处理。
 */
function expandShorthandPath(input: string): string | undefined {
  const p = input.trim();
  if (p === "~") return homedir();
  if (p.startsWith("~/")) return join(homedir(), p.slice(2));
  if (/^file:\/\//.test(p)) {
    try {
      return fileURLToPath(p);
    } catch {
      // 非法 file:// URL,按普通路径处理
    }
  }
  return undefined;
}

/**
 * 本地路径解析(输入语义):相对路径基于项目根 cwd,对齐 pi install 对用户输入的解析
 * (C 级:DefaultPackageManager.resolvePath() 基于 this.cwd,getSourceMatchKeyForInput 同;
 * ~ 展开与 file:// 展开在 dist/utils/paths.js 的 normalizePath())。
 */
export function resolveLocalPath(input: string, projectCwd: string): string {
  const expanded = expandShorthandPath(input);
  if (expanded !== undefined) return expanded;
  const p = input.trim();
  return isAbsolute(p) ? resolve(p) : resolve(projectCwd, p);
}

/**
 * 本地路径解析(声明语义):相对路径基于该作用域的配置目录 —— project 为
 * <cwd>/<CONFIG_DIR_NAME>(默认 .pi),user 为 pi agent 目录(getAgentDir(),默认
 * ~/.pi/agent、可被 PI_CODING_AGENT_DIR 覆盖),对齐 pi getBaseDirForScope() 对已存储声明的解析。
 * 该"声明以 settings 文件所在目录为基准"的行为有官方 prose 背书
 * (docs/packages.md:"Relative local paths resolve from the settings file that contains them");
 * 与输入语义不同(项目根),所以同一相对路径两侧解析结果不同。
 */
export function resolveStoredLocalPath(
  input: string,
  scope: "user" | "project",
  projectCwd: string,
): string {
  const expanded = expandShorthandPath(input);
  if (expanded !== undefined) return expanded;
  const p = input.trim();
  if (isAbsolute(p)) return resolve(p);
  const baseDir = scope === "user" ? getAgentDir() : join(projectCwd, PI_SETTINGS_DIR);
  return resolve(baseDir, p);
}

/**
 * 非本地源的包身份;本地源返回 undefined,由调用方按语义解析路径。
 * 分类对齐 pi 的 parseSource/isLocalPath(dist/utils/paths.js、dist/utils/git.js):
 * 只有 `npm:`(按原文前缀判断,pi 不 trim)与 `git:`/协议 URL 是非本地,
 * 其余形式(裸名、builtin:、github:user/repo、裸 git@host:path)pi 都回退成本地路径,这里同样返回 undefined
 * —— 否则会出现与 pi 不同的身份,进而错误跳过或重复安装。
 * 残留(C 级):`git:` 前缀之后 hosted-git-info 与 URL 都解析不了的形态(如 git:github:user/repo),
 * pi 仍会回退成本地路径,这里仍按 git 处理。
 */
function nonLocalIdentity(source: string): string | undefined {
  if (source.startsWith("npm:")) return `npm:${parseNpmName(source.slice(4).trim())}`;
  if (source.startsWith("git:") || /^(https?|ssh|git):\/\//i.test(source)) {
    return `git:${normalizeGitSource(source)}`;
  }
  return undefined;
}

/**
 * 包身份(对齐 pi getPackageIdentity 的简化版):
 * npm 按包名(去版本)、git 按 host/path(去 ref)、local 按解析后的绝对路径。
 * 身份语义有官方 prose 背书(docs/packages.md:"Pi identifies npm packages by package name,
 * git packages by repository URL without the ref, and local packages by resolved absolute path");
 * 具体算法只在 dist 内部(B/C 级),升级复核 dist/core/package-manager.js 的 getPackageIdentity。
 * 这是"输入语义":local 相对路径基于项目根 cwd,用于用户键入的源与组定义。
 * 已存储声明的 local 身份请用 storedPackageIdentity()(基目录随作用域不同)。
 */
export function packageIdentity(source: string, projectCwd: string): string {
  return nonLocalIdentity(source) ?? `local:${resolveLocalPath(source, projectCwd)}`;
}

/**
 * 已存储声明的包身份(对齐 pi getPackageIdentity(source, scope) 的 local 分支):
 * local 相对路径按作用域基目录解析(见 resolveStoredLocalPath),其余与 packageIdentity 相同。
 */
export function storedPackageIdentity(
  source: string,
  scope: "user" | "project",
  projectCwd: string,
): string {
  return nonLocalIdentity(source) ?? `local:${resolveStoredLocalPath(source, scope, projectCwd)}`;
}

/**
 * 把已存储的声明源转换为 pi 输入侧等价的写法。
 * pi 对 local 源有两套解析基准:声明按 scope 基目录(getSourceMatchKeyForSettings),
 * 输入按项目根(getSourceMatchKeyForInput);同一相对路径在两侧结果不同,所以把声明
 * 原文当输入回传(如 removeAndPersist)会匹配失败。绝对路径在两侧同值,故 local 声明
 * 统一转绝对路径;npm/git 的身份与基目录无关,原样返回。
 */
export function storedSourceAsInput(
  source: string,
  scope: "user" | "project",
  projectCwd: string,
): string {
  if (nonLocalIdentity(source) !== undefined) return source;
  return resolveStoredLocalPath(source, scope, projectCwd);
}

/** 解析组配置文件内容;结构问题逐条记入 errors,不抛异常(文件缺失视为空表)。 */
export function parseGroupFileContent(
  raw: string | undefined,
  filePath: string,
): { table: GroupTable; errors: string[] } {
  // null 原型:组名与 Object.prototype 成员同名(如 "toString")时不命中原型属性
  const table: GroupTable = Object.create(null) as GroupTable;
  const errors: string[] = [];
  if (raw === undefined) return { table, errors };
  let data: unknown;
  try {
    data = JSON.parse(raw);
  } catch (error) {
    return { table, errors: [`${filePath}: JSON 解析失败(${errorMessage(error)})`] };
  }
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return { table, errors: [`${filePath}: 顶层应为对象(组名 → {description?, packages[]})`] };
  }
  for (const [name, value] of Object.entries(data as Record<string, unknown>)) {
    if (typeof value !== "object" || value === null) {
      errors.push(`${filePath}: 组 "${name}" 应为对象`);
      continue;
    }
    const rawPackages = (value as { packages?: unknown }).packages;
    if (
      !Array.isArray(rawPackages) ||
      rawPackages.some((p) => typeof p !== "string" || p.trim() === "")
    ) {
      errors.push(`${filePath}: 组 "${name}" 的 packages 必须是非空字符串数组`);
      continue;
    }
    const description = (value as { description?: unknown }).description;
    table[name] = {
      description: typeof description === "string" ? description : undefined,
      packages: rawPackages.map((p) => (p as string).trim()),
    };
  }
  return { table, errors };
}

/** 合并全局与项目组表;同名组项目级整体覆盖(不深度合并 packages)。 */
export function mergeGroupTables(globalTable: GroupTable, projectTable: GroupTable): GroupTable {
  // null 原型:避免组名与 Object.prototype 成员同名时命中原型属性
  return Object.assign(Object.create(null) as GroupTable, globalTable, projectTable);
}

/**
 * 展开一个或多个组:收集 packages,按包身份去重,保留首次出现顺序(不排序)。
 * 未知组名记入 unknown(其余组照常处理);同身份不同写法保留首个并记入 conflicts。
 */
export function expandGroups(
  names: string[],
  table: GroupTable,
  projectCwd: string,
): { sources: string[]; unknown: string[]; conflicts: string[] } {
  const sources: string[] = [];
  const seen = new Map<string, number>();
  const unknown: string[] = [];
  const conflicts: string[] = [];
  for (const name of names) {
    // 用自有属性判定:否则 "constructor"/"toString" 等会被当成存在的组而崩溃
    if (!Object.hasOwn(table, name)) {
      unknown.push(name);
      continue;
    }
    const def = table[name];
    for (const source of def.packages) {
      const id = packageIdentity(source, projectCwd);
      const existingIndex = seen.get(id);
      if (existingIndex !== undefined) {
        if (sources[existingIndex] !== source) {
          conflicts.push(`"${source}" 与 "${sources[existingIndex]}" 为同一包(保留首个)`);
        }
        continue;
      }
      seen.set(id, sources.length);
      sources.push(source);
    }
  }
  return { sources, unknown, conflicts };
}

/** 批量结果格式化(含汇总行)。 */
export function formatResults(results: OpResult[]): string {
  const marks = { ok: "✓", skipped: "–", failed: "✗" } satisfies Record<OpResult["status"], string>;
  const labels = { ok: "成功", skipped: "跳过", failed: "失败" } satisfies Record<OpResult["status"], string>;
  const lines = results.map((r) => {
    const mark = marks[r.status];
    return `${mark} [${labels[r.status]}] ${r.target}${r.detail ? ` — ${r.detail}` : ""}`;
  });
  const ok = results.filter((r) => r.status === "ok").length;
  const skipped = results.filter((r) => r.status === "skipped").length;
  const failed = results.filter((r) => r.status === "failed").length;
  lines.push(`完成:${ok} 成功 / ${skipped} 跳过 / ${failed} 失败`);
  return lines.join("\n");
}

/** 汇总消息的通知级别:有失败 → error;仅跳过 → warning;否则 info。 */
export function reportLevel(results: OpResult[]): "info" | "warning" | "error" {
  if (results.some((r) => r.status === "failed")) return "error";
  if (results.some((r) => r.status === "skipped")) return "warning";
  return "info";
}

/** 明细长度上限:子进程失败文案可能带 stderr 尾部,直接进通知会刷屏。 */
const MAX_DETAIL_CHARS = 2000;

function errorMessage(error: unknown): string {
  const text = error instanceof Error ? error.message : String(error);
  if (text.length <= MAX_DETAIL_CHARS) return text;
  // 保留尾部:关键错误行通常在子进程输出末尾
  return `…(已截断 ${text.length - MAX_DETAIL_CHARS} 字符)\n${text.slice(-MAX_DETAIL_CHARS)}`;
}

// ─────────────────────── §3 包管理器与写权限门 ───────────────────────

/**
 * 创建包管理器。projectTrusted 恒为 true:
 * - 读声明需要它:list/clean 走 listConfiguredPackages(),后者对 project 包经 getInstalledPath()
 *   → getBaseDirForScope("project") → assertProjectTrustedForScope() 断言信任;
 * - 该选项是内存态(B 级导出类型 SettingsManagerCreateOptions.projectTrusted,
 *   dist/core/settings-manager.d.ts):它还决定是否加载项目 settings 与是否放行项目写
 *   (assertProjectTrustedForWrite),但"不"写入任何信任记录、不改变 pi 会话自身的信任状态,
 *   语义等价于 CLI 的 --approve(docs/cli.md;dist/main.js 就是把它传给这个选项)。
 *   升级复核:settings-manager.js 的 fromStorageWithPaths/assertProjectTrustedForWrite。
 * 写安全完全由 resolveWriteGate 独立把关(所有写方法仅在该门通过后才被调用)。
 */
function createPackageManager(ctx: ExtensionCommandContext): DefaultPackageManager {
  const agentDir = getAgentDir();
  const settingsManager = SettingsManager.create(ctx.cwd, agentDir, {
    projectTrusted: true,
  });
  const pm = new DefaultPackageManager({ cwd: ctx.cwd, agentDir, settingsManager });
  // 子进程输出(C 级:B 级导出面未定义此项行为,以下均按 1.1.0 dist 实现):
  // pi 只在非交互模式调 takeOverStdout(dist/main.js + dist/core/output-guard.js;
  // 语义见 docs/json.md:"Stdout is reserved for JSONL"),而 DefaultPackageManager.spawnCommand 的
  // stdio 选择是 isStdoutTakenOver() ? ["ignore", 2, 2] : "inherit"
  // (dist/core/package-manager.js;1.1.0 为第 2145 行)。因此 TUI 模式下 npm/git 子进程
  // 继承终端、输出会直写终端打穿输入框。
  // 处理方式:写操作统一包在 withSuspendedTui 里,先把界面让给子进程(见该函数说明);
  // 这里不覆写任何私有方法,也不再捕获子进程输出 —— npm/git 日志直落暂停后的终端。
  if (ctx.mode === "tui") {
    // 暂停期间 TUI 不渲染,状态行(setStatus)看不到;直接打印到终端,与 pi CLI 一致
    pm.setProgressCallback((event: ProgressEvent) => {
      if (event.type === "start") {
        process.stdout.write(`  ${event.action} ${event.source}…\n`);
      } else if (event.type === "progress" && event.message) {
        process.stdout.write(`  ${event.action} ${event.source}: ${event.message}\n`);
      }
    });
  } else if (ctx.hasUI) {
    pm.setProgressCallback((event: ProgressEvent) => {
      if (event.type === "start") {
        ctx.ui.setStatus(STATUS_KEY, `${event.action} ${event.source}…`);
      } else if (event.type === "progress" && event.message) {
        // 真实 pi 的 withProgress 目前只发射 start/complete/error;
        // progress 分支为 ProgressEvent 契约预留,不依赖宿主是否实际触发。
        ctx.ui.setStatus(STATUS_KEY, `${event.action} ${event.source}: ${event.message}`);
      } else {
        // complete / error(以及无 message 的 progress):清除状态行
        ctx.ui.setStatus(STATUS_KEY, undefined);
      }
    });
  }
  return pm;
}

/**
 * 在 TUI 模式下暂停界面执行 run,把终端让给 npm/git 子进程;其余模式直接执行。
 *
 * 依据(公开接口/官方示例;括号内为 1.1.0 实现细节,升级复核):
 * - 取 TUI 引用走 ctx.ui.custom() 的工厂参数:docs/tui.md 定义的公开入口,
 *   官方示例 examples/extensions/interactive-shell.ts 就用它在扩展里跑交互式命令。
 *   工厂必须返回一个组件(render/invalidate 即可),并通过 done() 结束交互;
 *   done() 幂等,这里放在 finally 里,保证 ctx.ui.custom() 的 promise 一定会 resolve。
 * - tui.stop()/start()/requestRender() 是 @earendil-works/pi-tui 导出的 TUI 接口方法
 *   (TuiStopOptions.preserveScreen 同在该包类型里);pi 自身的挂起、外部编辑器与全屏切换走同一套 API:
 *   外部编辑器是 stop() → start() + requestRender(true)(interactive-mode.js handleOpenExternalEditor),
 *   preserveScreen 照抄 pi 的 stopInteractiveTui()(1.1.0 第 603 行:mode === "fullscreen"),
 *   handleCtrlZ 与外部编辑器只调 stop() 不传参,不要引用它们作为 preserveScreen 的依据。
 * - 判 ctx.mode === "tui" 而非 ctx.hasUI:custom() 需要真实终端
 *   (docs/rpc-extension-ui.md;rpc 模式 hasUI 也为 true)。
 * - 非 TUI(print/json/rpc)不需要暂停:这些模式已 takeOverStdout,子进程 stdout 被忽略、
 *   stderr 走 fd 2,不会污染 JSON/RPC 协议流(docs/json.md)。
 *
 * 行为:start() 自带一次非强制重绘(pi-tui tui.js:570),暂停后仍需 requestRender(true) 强制
 * 全量重绘,清掉残留的帧状态(与 pi 自身 handleCtrlZ 的恢复写法一致)。暂停窗口内子进程以
 * stdio:"inherit" 继承终端,故 npm/git 日志直接可见(不再被捕获,失败通知里也就没有 stderr
 * 明细),私有 git 仓库可以现场输入凭据。暂停期间界面不渲染、对话不响应,不要调用 ctx.ui;
 * 需要给用户提示就直接写 stdout。
 *
 * run 抛错时先恢复界面再重新抛出;恢复失败不覆盖 run 的原始错误。
 */
async function withSuspendedTui<T>(
  ctx: ExtensionCommandContext,
  run: () => Promise<T>,
): Promise<T> {
  if (ctx.mode !== "tui") return run();
  // 成功写 value、失败写 error;每条路径都会赋值,末尾兜底"工厂结束但流程未走完"(理论上不可达)。
  let outcome: { value: T } | { error: unknown } | undefined;
  await ctx.ui.custom<void>(async (tui, _theme, _keybindings, done) => {
    tui.stop({ preserveScreen: tui.mode === "fullscreen" });
    // 暂停窗口内屏蔽 SIGINT:raw 模式已退出,Ctrl+C 会变成发给整个前台进程组的信号,
    // 默认动作会连 pi 一起杀掉(pi 在 handleCtrlZ 里对同一窗口做了同样处理)。屏蔽后
    // npm/git 仍会收到信号自行中止,pi 存活并恢复界面。
    const ignoreSigint = () => {};
    process.on("SIGINT", ignoreSigint);
    try {
      process.stdout.write("extensions-manager: 正在执行 npm/git,界面已暂停,完成后自动恢复…\n");
      outcome = { value: await run() };
    } catch (error) {
      outcome = { error };
    } finally {
      process.removeListener("SIGINT", ignoreSigint);
      // 恢复界面:即使 start() 失败也必须调用 done(),否则 ctx.ui.custom() 的 promise 不 resolve,
      // 命令会永久挂起;恢复失败本身不覆盖 run() 的原始错误。
      try {
        tui.start();
        tui.requestRender(true);
      } catch (restoreError) {
        if (outcome === undefined || "value" in outcome) outcome = { error: restoreError };
      } finally {
        done();
      }
    }
    return { render: () => [], invalidate: () => {} };
  });
  if (outcome === undefined) throw new Error("extensions-manager: 界面暂停流程未完成");
  if ("error" in outcome) throw outcome.error;
  return outcome.value;
}

/**
 * 写权限门:所有写操作(add、add-group、remove、remove-group、clean)的前置。
 * - 已受信任 → 放行;
 * - -y → 放行(免确认,不保存信任决定);
 * - 有 UI → 交互确认;
 * - 无 UI → 拒绝并提示。
 */
async function resolveWriteGate(ctx: ExtensionCommandContext, yes: boolean): Promise<boolean> {
  if (ctx.isProjectTrusted()) return true;
  if (yes) return true;
  if (!ctx.hasUI) {
    output(ctx, "项目未受信任且当前无交互界面:请加 -y 跳过确认,或先用 /trust 授予信任。", "warning");
    return false;
  }
  return ctx.ui.confirm(
    "项目尚未受信任",
    `允许向 ${join(ctx.cwd, PI_SETTINGS_DIR)} 写入包配置并执行安装/卸载吗?`,
  );
}

/** 读取全局与项目组配置文件;读文件本身的 I/O 错误也归入 errors。 */
function loadGroupTables(cwd: string): GroupTables {
  const globalPath = join(getAgentDir(), GROUPS_FILE);
  const projectPath = join(cwd, PI_SETTINGS_DIR, GROUPS_FILE);
  const readSafe = (path: string): { raw?: string; error?: string } => {
    if (!existsSync(path)) return {};
    try {
      return { raw: readFileSync(path, "utf8") };
    } catch (error) {
      return { error: `${path}: 读取失败(${errorMessage(error)})` };
    }
  };
  const g = readSafe(globalPath);
  const p = readSafe(projectPath);
  const parsedGlobal = parseGroupFileContent(g.raw, globalPath);
  const parsedProject = parseGroupFileContent(p.raw, projectPath);
  const errors = [g.error, ...parsedGlobal.errors, p.error, ...parsedProject.errors].filter(
    (e): e is string => e !== undefined,
  );
  return {
    global: parsedGlobal.table,
    project: parsedProject.table,
    errors,
    globalPath,
    projectPath,
  };
}

// ────────────────────────── §4 子命令处理器 ──────────────────────────

/**
 * 与 pi ConfiguredPackage 结构一致。该类型未从包根导出,但可从导出的 PackageManager 接口
 * 推导:pi 改动其形状时这里会直接编译失败,而不是静默失配。
 */
type ConfiguredPackageRef = ReturnType<PackageManager["listConfiguredPackages"]>[number];

/**
 * 提取某个作用域下已存储声明的身份 → 源串(单次遍历)。
 * 用 storedPackageIdentity:声明里的相对路径以该作用域的配置目录为基准。
 */
function identitySourceMap(
  configured: ConfiguredPackageRef[],
  scope: "user" | "project",
  projectCwd: string,
): Map<string, string> {
  const map = new Map<string, string>();
  for (const pkg of configured) {
    if (pkg.scope === scope) {
      map.set(storedPackageIdentity(pkg.source, scope, projectCwd), pkg.source);
    }
  }
  return map;
}

/**
 * add 已配置时跳过的明细。
 * local 源由 pi 规范化写回(如 ./pkg → ../pkg),文本比较无意义,统一说明已声明;
 * 非 local 源文本不同(版本/ref 不同)时,pi update 只会重装已声明版本,不能宣称可升级。
 */
function addSkipDetail(source: string, declared: string): string {
  if (nonLocalIdentity(source) === undefined) return `已安装(已声明为 ${declared})`;
  if (declared.trim() === source.trim()) return "已安装(升级: pi update)";
  return `已配置为 ${declared}(变更请先 remove)`;
}

/** add:已按身份配置(项目级)→ 跳过;否则安装。单个失败不中断。 */
async function cmdAdd(
  ctx: ExtensionCommandContext,
  pm: DefaultPackageManager,
  sources: string[],
): Promise<OpResult[]> {
  const configured = pm.listConfiguredPackages();
  const projectIds = identitySourceMap(configured, "project", ctx.cwd);
  const userIds = identitySourceMap(configured, "user", ctx.cwd);
  const results: OpResult[] = [];
  for (const source of sources) {
    const id = packageIdentity(source, ctx.cwd);
    const declared = projectIds.get(id);
    if (declared !== undefined) {
      results.push({ target: source, status: "skipped", detail: addSkipDetail(source, declared) });
      continue;
    }
    try {
      await pm.installAndPersist(source, { local: true });
      projectIds.set(id, source); // 防同批重复
      const inUser = userIds.has(id);
      results.push({
        target: source,
        status: "ok",
        detail: inUser ? "用户级已配置,项目级优先" : undefined,
      });
    } catch (error) {
      results.push({ target: source, status: "failed", detail: errorMessage(error) });
    }
  }
  return results;
}

/** remove/clean 未匹配到声明时的明细:pi 的 remove() 已先跑过卸载,故不只报"未声明"。 */
const REMOVE_SKIPPED_DETAIL = "未声明(实体卸载仍已尝试)";

/**
 * remove:removeAndPersist 返回 false = 无匹配声明 → 视为"未声明,跳过"(幂等)。
 * 注意 pi 先执行 remove() 再看声明是否匹配,声明缺失时实体仍可能已被卸载。
 */
async function cmdRemove(
  pm: DefaultPackageManager,
  sources: string[],
): Promise<OpResult[]> {
  const results: OpResult[] = [];
  for (const source of sources) {
    try {
      const removed = await pm.removeAndPersist(source, { local: true });
      results.push(
        removed
          ? { target: source, status: "ok" }
          : { target: source, status: "skipped", detail: REMOVE_SKIPPED_DETAIL },
      );
    } catch (error) {
      results.push({ target: source, status: "failed", detail: errorMessage(error) });
    }
  }
  return results;
}

/** add-group / remove-group 共用的组展开入口。 */
async function cmdGroups(
  ctx: ExtensionCommandContext,
  pm: DefaultPackageManager,
  subcommand: "add-group" | "remove-group",
  names: string[],
): Promise<{ results: OpResult[]; notes: string[]; notesLevel?: "info" | "warning" | "error" }> {
  const tables = loadGroupTables(ctx.cwd);
  if (tables.errors.length > 0) {
    // 组表损坏时中止:静默跳过可能卸错/装错
    return {
      results: [],
      notes: [tables.errors.join("\n"), "组配置存在问题,已中止本次组操作。"],
      notesLevel: "error" as const,
    };
  }
  const merged = mergeGroupTables(tables.global, tables.project);
  const expanded = expandGroups(names, merged, ctx.cwd);
  const notes: string[] = [...expanded.conflicts];
  // 未知组报错附可用组名;组表为空时无可用名可列,保持简短提示
  const availableNames = Object.keys(merged).join(", ");
  const results: OpResult[] = expanded.unknown.map((name) => ({
    target: name,
    status: "failed",
    detail: availableNames.length > 0 ? `组不存在(可用: ${availableNames})` : "组不存在",
  }));
  if (expanded.sources.length > 0) {
    const batchResults =
      subcommand === "add-group"
        ? await cmdAdd(ctx, pm, expanded.sources)
        : await cmdRemove(pm, expanded.sources);
    results.push(...batchResults);
  } else if (results.length === 0 && notes.length === 0) {
    // 组存在但 packages 为空:补说明,避免 finish 输出空通知
    notes.push("目标组未定义任何插件,无事发生。");
  }
  return { results, notes };
}

/**
 * clean 第一阶段:取项目级插件列表并(必要时)向用户确认。
 * 确认对话必须在暂停界面之前完成,故与卸载动作拆开。
 */
async function planClean(
  ctx: ExtensionCommandContext,
  pm: DefaultPackageManager,
  yes: boolean,
): Promise<{ aborted: true } | { aborted: false; packages: ConfiguredPackageRef[] }> {
  const projectPkgs = pm.listConfiguredPackages().filter((p) => p.scope === "project");
  if (projectPkgs.length === 0) {
    output(ctx, "项目未配置任何插件,无事发生。", "info");
    return { aborted: true };
  }
  if (!yes) {
    if (!ctx.hasUI) {
      output(
        ctx,
        `检测到 ${projectPkgs.length} 个项目级插件。非交互模式执行 clean 需要加 -y 跳过确认,本次已中止。`,
        "warning",
      );
      return { aborted: true };
    }
    const listText = projectPkgs.map((p) => `  - ${p.source}`).join("\n");
    const confirmed = await ctx.ui.confirm(
      "clean 确认",
      `将卸载以下 ${projectPkgs.length} 个项目级插件:\n${listText}`,
    );
    if (!confirmed) {
      output(ctx, "已取消。", "warning");
      return { aborted: true };
    }
  }
  return { aborted: false, packages: projectPkgs };
}

/** clean 第二阶段:卸载全部给定声明(永不触碰用户级);调用方负责暂停界面。 */
async function cmdClean(
  ctx: ExtensionCommandContext,
  pm: DefaultPackageManager,
  packages: ConfiguredPackageRef[],
): Promise<OpResult[]> {
  const results: OpResult[] = [];
  for (const pkg of packages) {
    try {
      // 声明原文的相对本地路径按 <CONFIG_DIR_NAME> 解析,pi 的输入侧按项目根解析;转绝对路径才能匹配
      const input = storedSourceAsInput(pkg.source, pkg.scope, ctx.cwd);
      const removed = await pm.removeAndPersist(input, { local: true });
      results.push(
        removed
          ? { target: pkg.source, status: "ok" }
          : { target: pkg.source, status: "skipped", detail: REMOVE_SKIPPED_DETAIL },
      );
    } catch (error) {
      results.push({ target: pkg.source, status: "failed", detail: errorMessage(error) });
    }
  }
  return results;
}

/** list:项目级插件(标注所属组)+ 用户级计数 + 组定义分区展示。 */
function cmdList(ctx: ExtensionCommandContext, pm: DefaultPackageManager): string {
  const tables = loadGroupTables(ctx.cwd);
  const configured = pm.listConfiguredPackages();
  const project = configured.filter((p) => p.scope === "project");
  const user = configured.filter((p) => p.scope === "user");
  const merged = mergeGroupTables(tables.global, tables.project);

  // 身份 → 组名(一个包可属多个组)
  const groupOf = new Map<string, string[]>();
  for (const [name, def] of Object.entries(merged)) {
    for (const source of def.packages) {
      const id = packageIdentity(source, ctx.cwd);
      const list = groupOf.get(id) ?? [];
      list.push(name);
      groupOf.set(id, list);
    }
  }

  const lines: string[] = [];
  lines.push(`项目级插件(${project.length}):`);
  for (const pkg of project) {
    // 组配置损坏时不做组名标注:不渲染部分解析出的组(与下方组区中止的意图一致)
    const groups =
      tables.errors.length > 0
        ? undefined
        : groupOf.get(storedPackageIdentity(pkg.source, pkg.scope, ctx.cwd));
    const groupNote = groups && groups.length > 0 ? ` — 组: ${groups.join(", ")}` : "";
    const pathNote = pkg.installedPath ? ` — ${pkg.installedPath}` : " — 未安装实体";
    lines.push(`  ${pkg.source}${groupNote}${pathNote}`);
  }
  if (project.length === 0) lines.push("  (无)");
  lines.push(`用户级插件:${user.length} 个(不在本命令管理范围)`);

  lines.push("插件组:");
  if (tables.errors.length > 0) {
    // 组配置损坏:不渲染部分解析出的组(避免呈现残缺组表),仅提示错误详情
    lines.push("  组配置存在错误,已跳过组区");
    lines.push(...tables.errors.map((e) => `  ⚠ ${e}`));
    return lines.join("\n");
  }
  const globalNames = new Set(Object.keys(tables.global));
  const projectNames = new Set(Object.keys(tables.project));
  const allNames = [...new Set([...globalNames, ...projectNames])];
  if (allNames.length === 0) {
    lines.push(`  (未定义任何组;可在 ${tables.globalPath} 或 ${tables.projectPath} 中定义)`);
  }
  for (const name of allNames) {
    const inProject = projectNames.has(name);
    const def = merged[name];
    let origin: string;
    if (inProject && globalNames.has(name)) origin = "[项目覆盖]";
    else if (inProject) origin = "[项目]";
    else origin = "[全局]";
    const desc = def.description ? ` — ${def.description}` : "";
    lines.push(`  ${origin} ${name}${desc}(${def.packages.length} 个插件)`);
  }
  return lines.join("\n");
}

// ─────────────────────────── §5 输出辅助 ───────────────────────────

/**
 * 输出:TUI/RPC 用 notify;print/json 等无 UI 模式回退 console.log。
 * 注意 pi 在非交互模式会 takeOverStdout,把 stdout 重定向到 stderr
 * (docs/json.md: "Stdout is reserved for JSONL"),所以 console.log 仍可达用户,
 * 且不会污染 JSON 协议流。
 */
function output(
  ctx: ExtensionCommandContext,
  message: string,
  level: "info" | "warning" | "error" = "info",
): void {
  if (ctx.hasUI) {
    ctx.ui.notify(message, level);
  } else {
    // 无 ctx.ui(print/json):stdout 已被 pi 重定向到 stderr。
    // ast-grep-ignore: no-console-except-error
    console.log(message);
  }
}

/** 批量操作收尾:汇报结果;有实际变更则在最后一步 reload(reload 后不得再使用旧运行时状态)。 */
async function finish(
  ctx: ExtensionCommandContext,
  results: OpResult[],
  notes: string[] = [],
  notesLevel: "info" | "warning" | "error" = "info",
): Promise<void> {
  // results 为空(中止/仅备注)时不追加汇总行,避免误导读者为执行过空批
  const parts = results.length > 0 ? [...notes, formatResults(results)] : [...notes];
  const text = parts.filter((part) => part.length > 0).join("\n");
  const level = results.length > 0 ? reportLevel(results) : notesLevel;
  output(ctx, text, level);
  if (results.some((r) => r.status === "ok")) {
    await ctx.reload();
    return; // reload 之后只允许 return
  }
}

// ─────────────────────── §6 命令入口与补全 ───────────────────────

async function runCommand(rawArgs: string, ctx: ExtensionCommandContext): Promise<void> {
  const tokens = tokenizeArgs(rawArgs);
  const { subcommand, targets, yes } = parseInvocation(tokens);

  if (subcommand === "help") {
    output(ctx, HELP_TEXT, "info");
    return;
  }

  const isWrite = subcommand !== "list";
  if (isWrite && !(await resolveWriteGate(ctx, yes))) return;
  const pm = createPackageManager(ctx);

  // 写操作(可能启动 npm/git 子进程)统一在暂停界面后执行;确认、通知与 reload 留在
  // 暂停之外:暂停期间界面不渲染、对话不响应(见 withSuspendedTui)。
  switch (subcommand) {
    case "add": {
      await finish(ctx, await withSuspendedTui(ctx, () => cmdAdd(ctx, pm, targets)));
      return;
    }
    case "remove": {
      await finish(ctx, await withSuspendedTui(ctx, () => cmdRemove(pm, targets)));
      return;
    }
    case "add-group":
    case "remove-group": {
      const { results, notes, notesLevel } = await withSuspendedTui(ctx, () =>
        cmdGroups(ctx, pm, subcommand, targets),
      );
      await finish(ctx, results, notes, notesLevel);
      return;
    }
    case "clean": {
      const plan = await planClean(ctx, pm, yes);
      if (plan.aborted) return;
      await finish(ctx, await withSuspendedTui(ctx, () => cmdClean(ctx, pm, plan.packages)));
      return;
    }
    case "list": {
      output(ctx, cmdList(ctx, pm), "info");
      return;
    }
    default: {
      throw new Error(`未实现的子命令: ${String(subcommand)}`);
    }
  }
}

/** 从 settings.json 文本提取包源声明(补全用,容错)。 */
function packageSourceOf(entry: unknown): string {
  if (typeof entry === "string") return entry;
  if (typeof entry === "object" && entry !== null) {
    const source = (entry as { source?: unknown }).source;
    if (typeof source === "string") return source;
  }
  return "";
}

function extractPackageSources(raw: string | undefined): string[] {
  if (!raw) return [];
  try {
    const data: unknown = JSON.parse(raw);
    if (typeof data !== "object" || data === null) return [];
    const packages = (data as { packages?: unknown }).packages;
    if (!Array.isArray(packages)) return [];
    const sources: string[] = [];
    for (const entry of packages) {
      const source = packageSourceOf(entry);
      if (source !== "") sources.push(source);
    }
    return sources;
  } catch {
    return [];
  }
}

/**
 * 本地声明的"项目内相对写法"(如 ./pkg),用于补全前缀过滤。
 * pi 写回的声明以 <CONFIG_DIR_NAME>(默认 .pi)为基准(如 ../pkg),与用户按项目根键入的习惯写法不同,
 * 多给一种写法便于 Tab 命中;非本地声明或已是绝对路径时无额外写法。
 */
function localRelativeKeys(stored: string, input: string, projectCwd: string): string[] {
  if (input === stored) return [];
  const rel = relative(projectCwd, input);
  if (rel === "" || rel.startsWith("..")) return [];
  return [`./${rel}`];
}

/**
 * 参数补全。锚点(dist 导出的 RegisteredCommand.getArgumentCompletions 类型 + pi-tui 的
 * AutocompleteProvider):prefix 只是 /exts 之后的参数串,返回项的 value 会整段替换这些参数,
 * 所以每项的 value 都拼回完整的"子命令 + 已键入目标"前缀。
 * projectCwd 仅用于读取项目级配置(补全在按键时刻拿不到 ctx);默认 process.cwd(),
 * 而会话 cwd 与进程 cwd 可能不同(会话目录丢失后选择回退目录时 pi 不 chdir),
 * 这种情形下补全会读错项目——命令执行路径始终用 ctx.cwd。测试可注入夹具路径。
 * 已知限制:这里按空白切词,不识别引号,含空格的引号路径在补全时会被重新拼接。
 */
export function getCompletions(
  prefix: string,
  projectCwd: string = process.cwd(),
): CompletionItem[] | null {
  const endsWithSpace = /\s$/.test(prefix);
  const trimmed = prefix.trimStart();
  // 尾随空格会产生空串 token,过滤之;是否正在输入新词由 endsWithSpace 判断
  const tokens = trimmed === "" ? [] : trimmed.split(/\s+/).filter((t) => t !== "");

  // 第一个词:补全子命令
  if (tokens.length === 0 || (tokens.length === 1 && !endsWithSpace)) {
    const typed = tokens[0] ?? "";
    return SUBCOMMANDS.flatMap((s) =>
      s.startsWith(typed)
        ? [{ value: `${s} `, label: s, description: SUBCOMMAND_DESC[s] }]
        : [],
    );
  }

  const sub = tokens[0] as Subcommand;
  const rest = tokens.slice(1);
  const current = endsWithSpace ? "" : (rest.at(-1) ?? "");
  const beforeCurrent = endsWithSpace ? rest : rest.slice(0, -1);
  const base = beforeCurrent.length > 0 ? `${sub} ${beforeCurrent.join(" ")}` : sub;
  const lowerCurrent = current.toLowerCase();

  if (sub === "add-group" || sub === "remove-group") {
    const tables = loadGroupTables(projectCwd);
    const merged = mergeGroupTables(tables.global, tables.project);
    const typedNames = new Set(beforeCurrent.map((t) => t.toLowerCase()));
    const candidates = Object.keys(merged).filter(
      (name) => !typedNames.has(name.toLowerCase()) && name.toLowerCase().startsWith(lowerCurrent),
    );
    if (candidates.length === 0) return null;
    return candidates.map((name) => ({
      value: `${base} ${name} `,
      label: name,
      description: merged[name].description,
    }));
  }

  if (sub === "add" || sub === "remove") {
    const settingsPath = join(projectCwd, PI_SETTINGS_DIR, "settings.json");
    let raw: string | undefined;
    try {
      raw = existsSync(settingsPath) ? readFileSync(settingsPath, "utf8") : undefined;
    } catch {
      return null;
    }
    const typedSources = new Set(beforeCurrent.map((t) => t.toLowerCase()));
    // 声明原文的相对本地路径按 <CONFIG_DIR_NAME> 解析,回填给命令时会按项目根解析而失配,故 value 用
    // 绝对路径(两侧同值);过滤另接受声明原文与项目相对写法,便于按习惯键入。
    const candidates = extractPackageSources(raw)
      .map((stored) => {
        const input = storedSourceAsInput(stored, "project", projectCwd);
        return { input, keys: [stored, ...localRelativeKeys(stored, input, projectCwd)] };
      })
      .filter(({ input, keys }) => {
        const lowers = [input.toLowerCase(), ...keys.map((k) => k.toLowerCase())];
        if (lowers.some((k) => typedSources.has(k))) return false;
        return lowers.some((k) => k.startsWith(lowerCurrent));
      });
    if (candidates.length === 0) return null;
    return candidates.map(({ input }) => ({
      value: `${base} ${input} `,
      label: input,
      description: sub === "add" ? "项目已配置" : "项目已配置(可移除)",
    }));
  }

  return null;
}

// ────────────────────────── 默认导出 factory ──────────────────────────

export default function (pi: ExtensionAPI): void {
  pi.registerCommand(COMMAND_NAME, {
    description: "管理项目插件与插件组",
    getArgumentCompletions: (prefix) => getCompletions(prefix),
    handler: async (args, ctx) => {
      try {
        await runCommand(args, ctx);
      } catch (error) {
        if (error instanceof CommandUsageError) {
          output(ctx, `${error.message}\n\n${HELP_TEXT}`, "warning");
          return;
        }
        output(ctx, `/exts 发生意外错误:${errorMessage(error)}`, "error");
      }
    },
  });
}
