// extensions-manager.ts — pi 个人扩展:项目级(本地)插件与插件组管理
//
// 设计文档:docs/design/02-module-design.md
// 机制调研:docs/research/pi-package-management.md、docs/research/pi-extension-api.md
//
// 范围:仅管理声明于 <项目>/.pi/settings.json 的本地插件;用户级插件请用 pi 原生
// `pi install <source>`(不带 -l)与 `pi update`。所有安装/卸载通过 pi 公开的程序化
// API(DefaultPackageManager)完成,不使用子进程。
//
// ── 使用方法 ──
//
// 1. 安装(单文件个人扩展):把本文件拷贝或软链到 ~/.pi/agent/extensions/ 即可,
//    pi 启动时自动经 jiti 直接运行 TS 源码,无需编译;对所有项目生效。
//    开发期可单次加载:pi --extension /path/to/extensions-manager.ts
//
// 2. 命令:/exts <子命令> [目标...] [-y](目标支持 Tab 补全:组名/已配置源)
//      /exts list                       查看项目插件与插件组
//      /exts add npm:pi-lens npm:x@1.2  安装(源语法同 pi install;幂等,已装跳过)
//      /exts remove npm:x               卸载(未安装则跳过)
//      /exts add-group web-dev          安装一个/多个插件组
//      /exts remove-group web-dev       卸载插件组(不删除组定义)
//      /exts clean                      卸载本项目全部插件(默认确认,-y 跳过)
//      /exts help                       完整帮助
//    选项 -y / --yes:免交互确认(项目未受信任时直接写入本地配置,不保存信任决定)。
//
// 3. 插件组定义(JSON;两个位置均可选,同名组项目级整体覆盖全局级):
//      全局 ~/.pi/agent/extension-groups.json
//      项目 <项目>/.pi/extension-groups.json
//    {
//      "web-dev": {
//        "description": "Web 开发套件",
//        "packages": ["npm:pi-lens", "npm:pi-web-access"]
//      }
//    }
//
// 4. 信任与确认:项目未受信任时,写操作先弹确认(或 -y 跳过;无 UI 模式必须 -y),
//    list 始终可用;用内置 /trust 命令可持久授予项目信任。

import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import {
  DefaultPackageManager,
  SettingsManager,
  getAgentDir,
} from "@earendil-works/pi-coding-agent";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ProgressEvent,
} from "@earendil-works/pi-coding-agent";

// ────────────────────────────── §0 常量 ──────────────────────────────

const COMMAND_NAME = "exts";
const GROUPS_FILE = "extension-groups.json";
const PI_SETTINGS_DIR = ".pi";
const STATUS_KEY = "extensions";
const YES_FLAGS = new Set(["-y", "--yes"]);

const SUBCOMMANDS = ["add", "add-group", "remove", "remove-group", "clean", "list", "help"] as const;
type Subcommand = (typeof SUBCOMMANDS)[number];

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
  "用法: /exts <子命令> [目标...] [-y]",
  "子命令:",
  ...SUBCOMMANDS.map((s) => `  ${s.padEnd(14)} ${SUBCOMMAND_DESC[s]}`),
  "说明: add 的源语法同 pi install(npm:x / git:... / 本地路径);remove 未安装则跳过;",
  "  remove-group 只卸载插件,不删除组定义;clean 卸载本项目全部插件(默认确认,-y 跳过)。",
  "选项: -y / --yes  免交互确认(项目未受信任时直接写入本地配置)",
  `组配置: ~/.pi/agent/${GROUPS_FILE} 与 <项目>/.pi/${GROUPS_FILE},同名组项目级覆盖全局级`,
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
// 本节不触碰 ctx / 包管理器 / 文件系统,可独立测试(见 tests 计划)。

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
    else targets.push(token);
  }
  const needsTargets =
    subcommand === "add" ||
    subcommand === "remove" ||
    subcommand === "add-group" ||
    subcommand === "remove-group";
  if (needsTargets && targets.length === 0) {
    throw new CommandUsageError(`"${subcommand}" 需要至少一个目标`);
  }
  return { subcommand, targets, yes };
}

/** npm 源取包名(与 pi parseNpmSpec 正则一致):npm:name@ver → name,@scope/name@ver → @scope/name。 */
export function parseNpmName(spec: string): string {
  const match = spec.match(/^(@?[^@]+(?:\/[^@]+)?)(?:@(.+))?$/);
  return match?.[1] ?? spec;
}

/**
 * git 源归一化(与 pi getPackageIdentity 的 `git:host/path` 对齐的近似实现):
 * 去协议/前缀(git:、github:、https://、ssh://、git@)、scp 冒号转斜杠、去 @ref、去 #ref、去 .git 后缀。
 * #ref 对应 pi 侧 hostedGitInfo 的 committish(dist/utils/git.js);极端 URL 形态可能与 pi
 * 略有出入;组内去重场景下偏差的后果仅是多装/多卸一次,可接受。
 */
export function normalizeGitSource(source: string): string {
  let s = source.trim();
  s = s.replace(/^(git|github):/, "");
  s = s.replace(/^(https?|ssh):\/\//, "");
  s = s.replace(/^git@/, "");
  s = s.replace(/:/, "/"); // scp 风格 git@host:path(若尚有冒号)
  const slash = s.lastIndexOf("/");
  const at = s.lastIndexOf("@");
  if (at > slash) s = s.slice(0, at); // 去 @ref
  s = s.replace(/#.*/, ""); // 去 #ref(committish)
  s = s.replace(/\.git$/, "");
  return s;
}

/** 本地路径解析:~ 展开;相对路径基于项目 .pi 目录(与 pi getBaseDirForScope("project") 一致)。 */
export function resolveLocalPath(input: string, projectCwd: string): string {
  let p = input.trim();
  if (p === "~") return homedir();
  if (p.startsWith("~/")) p = join(homedir(), p.slice(2));
  if (/^file:\/\//.test(p)) {
    try {
      return fileURLToPath(p);
    } catch {
      // 非法 file:// URL,按普通路径处理
    }
  }
  return isAbsolute(p) ? resolve(p) : resolve(projectCwd, PI_SETTINGS_DIR, p);
}

/**
 * 包身份(与 pi getPackageIdentity 对齐的简化版):
 * npm 按包名(去版本)、git 按 host/path(去 ref)、local 按解析后的绝对路径。
 * 来源:dist/core/package-manager.js getPackageIdentity();isLocalPath() 把裸名也视为本地路径,
 * 因此此处除已列前缀外一律按 local 处理。
 */
export function packageIdentity(source: string, projectCwd: string): string {
  const s = source.trim();
  if (s.startsWith("npm:")) return `npm:${parseNpmName(s.slice(4).trim())}`;
  if (/^(git|github):/.test(s) || /^(https?|ssh):\/\//.test(s) || /^git@/.test(s)) {
    return `git:${normalizeGitSource(s)}`;
  }
  if (s.startsWith("builtin:")) return s;
  return `local:${resolveLocalPath(s, projectCwd)}`;
}

/** 解析组配置文件内容;结构问题逐条记入 errors,不抛异常(文件缺失视为空表)。 */
export function parseGroupFileContent(
  raw: string | undefined,
  filePath: string,
): { table: GroupTable; errors: string[] } {
  const table: GroupTable = {};
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
  return { ...globalTable, ...projectTable };
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
    const def = table[name];
    if (!def) {
      unknown.push(name);
      continue;
    }
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

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

// ─────────────────────── §3 包管理器与写权限门 ───────────────────────

/**
 * 创建包管理器。projectTrusted 恒为 true:未信任项目也要能 list 已声明的包
 * (真实 pi 的 listConfiguredPackages 会对 project 包断言信任),而 SettingsManager 的
 * 该选项只影响 assertProjectTrustedForScope 断言与写放行,为内存态、不持久化信任决定。
 * 写安全完全由 resolveWriteGate 独立把关(所有写方法仅在该门通过后才被调用);
 * 经确认/-y 授权后注入等价 CLI --approve 的 projectTrusted:true,时机不变。
 */
function createPackageManager(ctx: ExtensionCommandContext): DefaultPackageManager {
  const agentDir = getAgentDir();
  const settingsManager = SettingsManager.create(ctx.cwd, agentDir, {
    projectTrusted: true,
  });
  const pm = new DefaultPackageManager({ cwd: ctx.cwd, agentDir, settingsManager });
  // TUI 模式下 pi 不接管 stdout(pi dist/main.js 仅对非交互模式 takeOverStdout),而
  // DefaultPackageManager.spawnCommand 以 stdio:"inherit" 启动 npm/git 子进程
  // (pi 1.1.0 dist/core/package-manager.js:2141-2147),输出会直写终端、打穿输入框。
  // 覆写 runCommand 改走其内置的 runCommandCapture(全管道捕获),顺带让失败信息
  // 携带子进程的 stderr;上游若修复交互模式的子进程 stdio,可直接删除本覆写。
  // SAFETY: runCommand/runCommandCapture 在 pi 的 .d.ts 中虽为 private,但编译产物里
  // 二者是 DefaultPackageManager 原型上的普通方法,运行时必然存在;npm/git 路径
  // 仅经 this.runCommand 调用 spawnCommand。此处只在实例上覆盖为实例属性
  // (不改原型、不影响 core 自建的包管理器),签名按二者实际实现书写。
  const spawnPatchable = pm as unknown as {
    runCommand: (
      command: string,
      args: string[],
      options?: { cwd?: string; timeoutMs?: number },
    ) => Promise<void>;
    runCommandCapture: (
      command: string,
      args: string[],
      options?: { cwd?: string; timeoutMs?: number },
    ) => Promise<string>;
  };
  spawnPatchable.runCommand = (command, args, options) =>
    spawnPatchable.runCommandCapture(command, args, options).then(() => undefined);
  if (ctx.hasUI) {
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

/** 与 pi ConfiguredPackage 结构一致(pi 未从包根导出该类型,此处本地声明)。 */
interface ConfiguredPackageRef {
  source: string;
  scope: "user" | "project";
  filtered: boolean;
  installedPath?: string;
}

/** 提取某个作用域的包身份集合(单次遍历)。 */
function identitySet(
  configured: ConfiguredPackageRef[],
  scope: "user" | "project",
  projectCwd: string,
): Set<string> {
  const ids = new Set<string>();
  for (const pkg of configured) {
    if (pkg.scope === scope) ids.add(packageIdentity(pkg.source, projectCwd));
  }
  return ids;
}

/** add:已配置(项目级,任意版本)→ 跳过;否则安装。单个失败不中断。 */
async function cmdAdd(
  ctx: ExtensionCommandContext,
  pm: DefaultPackageManager,
  sources: string[],
): Promise<OpResult[]> {
  const configured = pm.listConfiguredPackages();
  const projectIds = identitySet(configured, "project", ctx.cwd);
  const userIds = identitySet(configured, "user", ctx.cwd);
  const results: OpResult[] = [];
  for (const source of sources) {
    const id = packageIdentity(source, ctx.cwd);
    if (projectIds.has(id)) {
      results.push({ target: source, status: "skipped", detail: "已安装(升级: pi update)" });
      continue;
    }
    try {
      await pm.installAndPersist(source, { local: true });
      projectIds.add(id); // 防同批重复
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

/** remove:removeAndPersist 返回 false = 无匹配声明 → 视为"未安装,跳过"(幂等)。 */
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
          : { target: source, status: "skipped", detail: "未安装" },
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
  }
  return { results, notes };
}

/** clean:卸载全部项目级插件(永不触碰用户级)。 */
async function cmdClean(
  ctx: ExtensionCommandContext,
  pm: DefaultPackageManager,
  yes: boolean,
): Promise<{ results: OpResult[]; aborted: boolean }> {
  const projectPkgs = pm.listConfiguredPackages().filter((p) => p.scope === "project");
  if (projectPkgs.length === 0) {
    output(ctx, "项目未配置任何插件,无事发生。", "info");
    return { results: [], aborted: true };
  }
  if (!yes) {
    if (!ctx.hasUI) {
      output(
        ctx,
        `检测到 ${projectPkgs.length} 个项目级插件。非交互模式执行 clean 需要加 -y 跳过确认,本次已中止。`,
        "warning",
      );
      return { results: [], aborted: true };
    }
    const listText = projectPkgs.map((p) => `  - ${p.source}`).join("\n");
    const confirmed = await ctx.ui.confirm(
      "clean 确认",
      `将卸载以下 ${projectPkgs.length} 个项目级插件:\n${listText}`,
    );
    if (!confirmed) {
      output(ctx, "已取消。", "warning");
      return { results: [], aborted: true };
    }
  }
  const results: OpResult[] = [];
  for (const pkg of projectPkgs) {
    try {
      const removed = await pm.removeAndPersist(pkg.source, { local: true });
      results.push(
        removed
          ? { target: pkg.source, status: "ok" }
          : { target: pkg.source, status: "skipped", detail: "未安装" },
      );
    } catch (error) {
      results.push({ target: pkg.source, status: "failed", detail: errorMessage(error) });
    }
  }
  return { results, aborted: false };
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
      tables.errors.length > 0 ? undefined : groupOf.get(packageIdentity(pkg.source, ctx.cwd));
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

/** 输出:TUI/RPC 用 notify,print/json 等无 UI 模式回退 console.log。 */
function output(
  ctx: ExtensionCommandContext,
  message: string,
  level: "info" | "warning" | "error" = "info",
): void {
  if (ctx.hasUI) {
    ctx.ui.notify(message, level);
  } else {
    // print/json 模式无 ctx.ui,stdout 是唯一输出通道(设计文档 §5)。
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

  switch (subcommand) {
    case "add": {
      await finish(ctx, await cmdAdd(ctx, pm, targets));
      return;
    }
    case "remove": {
      await finish(ctx, await cmdRemove(pm, targets));
      return;
    }
    case "add-group":
    case "remove-group": {
      const { results, notes, notesLevel } = await cmdGroups(ctx, pm, subcommand, targets);
      await finish(ctx, results, notes, notesLevel);
      return;
    }
    case "clean": {
      const { results, aborted } = await cmdClean(ctx, pm, yes);
      if (!aborted) await finish(ctx, results);
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
 * 参数补全。projectCwd 仅用于读取项目级配置(补全发生在按键时刻,拿不到 ctx);
 * 真实 pi 会话中 process.cwd() 即项目目录,测试可注入夹具路径。
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
    const candidates = extractPackageSources(raw).filter(
      (s) => !typedSources.has(s.toLowerCase()) && s.toLowerCase().startsWith(lowerCurrent),
    );
    if (candidates.length === 0) return null;
    return candidates.map((s) => ({
      value: `${base} ${s} `,
      label: s,
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
