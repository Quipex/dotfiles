/**
 * Minimal Footer Extension — replaces the built-in footer status bar.
 *
 * Keeps only the context-usage block with icons (plus the cwd/branch line and
 * the model on the right, both toggleable), and drops the token/cost/cache stats.
 *
 * Also renders an "idle since last reply" segment on the context line: how long
 * ago the agent produced its final response and is now waiting for input.
 *   0–4s   → "now"  (green)
 *   5–59s  → "Ns"   (green)
 *   1–59m  → "Nm"   (plain)
 *   1h–23h → "Nh Mm" (plain, two fields always)
 *   ≥24h   → "Nd"   (plain)
 * Hidden while the agent is actively working (its own spinner shows then) and
 * until the first reply in a session. Updates once per second via a render tick.
 *
 * Auto-discovered from ~/.pi/agent/extensions/*.ts — survives `bun update`.
 * Loaded automatically on session start; `/footer` toggles it off/on.
 *
 * Tweak the icons/labels via the CONFIG block below.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { isAbsolute, relative, resolve, sep } from "node:path";
import os from "node:os";

// ─── CONFIG ───────────────────────────────────────────────────────────────
/** Connector between the two context fields. */
const SEPARATOR = " of ";
/** Text appended after the window when auto-compaction is on. Set to "" to hide. */
const AUTO_INDICATOR = "";
/** Show the top line (cwd · git branch · session name)? */
const SHOW_PWD_LINE = true;
/** Show the model (and thinking level) on the right of the stats line? */
const SHOW_MODEL = true;
/** Thinking level → unicode glyph (filling circle). */
const THINKING_GLYPHS: Record<string, string> = {
  off: "○",
  minimal: "◔",
  low: "◑",
  medium: "◕",
  high: "●",
};
/** Seconds to show "now" before switching to "Ns". */
const NOW_THRESHOLD_S = 5;
/** Update interval for the idle-since segment, in milliseconds. */
const IDLE_TICK_MS = 1000;
/** Separator between the context block and the idle-since segment. */
const IDLE_SEP = " \u{00B7} ";
/** Flag glyph prefixing the idle-since segment (U+1F3C1 CHEQUERED FLAG, 1 cell). */
const IDLE_ICON = "\u{1F3C1}";
/** Space between the icon and the idle-since value. */
const IDLE_ICON_GAP = " ";
/** Map raw model id -> short alias shown in the footer. Unmapped ids pass through. */
const MODEL_ALIASES: Record<string, string> = {
};
// ───────────────────────────────────────────────────────────────────────────

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function formatCwdForFooter(cwd: string, home: string): string {
  if (!home) return cwd;
  const resolvedCwd = resolve(cwd);
  const resolvedHome = resolve(home);
  const rel = relative(resolvedHome, resolvedCwd);
  const insideHome =
    rel === "" ||
    (rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel));
  if (!insideHome) return cwd;
  return rel === "" ? "~" : `~${sep}${rel}`;
}

/**
 * Bare (un-styled) idle-since value for the elapsed time since `ts`
 * (ms epoch). Returns `undefined` when there is nothing to show yet.
 *
 * The caller applies color/weight based on freshness; this function only
 * produces the text. `true` is returned alongside the value when the reply
 * is recent (< 1 minute) so the caller can render it bold + green.
 */
function formatIdleSinceValue(
  ts: number | undefined,
): { value: string; recent: boolean } | undefined {
  if (!ts) return undefined;
  const elapsedMs = Date.now() - ts;
  if (elapsedMs < 0) return undefined;
  const totalSec = Math.floor(elapsedMs / 1000);

  if (totalSec < NOW_THRESHOLD_S) return { value: "now", recent: true };
  if (totalSec < 60) return { value: `${totalSec}s`, recent: true };

  const totalMin = Math.floor(totalSec / 60);
  if (totalMin < 60) return { value: `${totalMin}m`, recent: false };

  const totalHours = Math.floor(totalMin / 60);
  if (totalHours < 24) {
    const mins = totalMin % 60;
    return { value: `${totalHours}h ${mins}m`, recent: false };
  }

  const days = Math.floor(totalHours / 24);
  return { value: `${days}d`, recent: false };
}

/** True if the assistant message is a final reply (stopped, no tool calls). */
function isFinalReply(message: AssistantMessage): boolean {
  if (message.stopReason !== "stop") return false;
  return !message.content.some((c) => c.type === "toolCall");
}

export default function (pi: ExtensionAPI) {
  let enabled = true;

  // Idle-since state (session-scoped). Kept in closure, read from render().
  let lastReplyTs: number | undefined;
  let agentActive = false;
  let tuiRef: { requestRender(): void } | undefined;
  let idleTimer: ReturnType<typeof setInterval> | undefined;

  const tick = () => tuiRef?.requestRender();

  const startIdleTimer = () => {
    if (idleTimer !== undefined) return;
    idleTimer = setInterval(tick, IDLE_TICK_MS);
    // Don't keep the event loop alive solely for the footer tick.
    if (idleTimer && typeof idleTimer.unref === "function") idleTimer.unref();
  };

  const stopIdleTimer = () => {
    if (idleTimer !== undefined) {
      clearInterval(idleTimer);
      idleTimer = undefined;
    }
  };

  // ctx is captured via closure; render() reads live state through it.
  const applyFooter = (ctx: any) => {
    ctx.ui.setFooter((tui: any, theme: any, footerData: any) => {
      tuiRef = tui; // keep a handle so the interval can request renders
      const unsubBranch = footerData.onBranchChange?.(() => tui.requestRender());
      return {
        dispose: () => {
          unsubBranch?.();
          tuiRef = undefined;
        },
        invalidate() {},
        render(width: number): string[] {
          const usage = ctx.getContextUsage();
          const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
          const percent = usage?.percent ?? 0; // 0 when tokens unknown
          const percentStr = usage?.percent !== null && usage?.percent !== undefined
            ? percent.toFixed(1)
            : "?";

          // ── Line 1: cwd · branch · session name ──
          const lines: string[] = [];
          if (SHOW_PWD_LINE) {
            let pwd = formatCwdForFooter(ctx.cwd, os.homedir());
            const branch = footerData.getGitBranch?.();
            if (branch) pwd = `${pwd} (${branch})`;
            const sessionName = ctx.sessionManager?.getSessionName?.();
            if (sessionName) pwd = `${pwd} • ${sessionName}`;
            lines.push(truncateToWidth(theme.fg("dim", pwd), width, theme.fg("dim", "...")));
          }

          // ── Line 2: 27.2% of 262k ⏱ 4m   …   model ──
          const contextDisplay =
            contextWindow === 0
              ? `${percentStr}%${SEPARATOR}?${AUTO_INDICATOR}`
              : `${percentStr}%${SEPARATOR}${formatTokens(contextWindow)}${AUTO_INDICATOR}`;

          // Colorize by usage level (matches built-in footer thresholds)
          let contextLeft;
          if (percent > 90) contextLeft = theme.fg("error", contextDisplay);
          else if (percent > 70) contextLeft = theme.fg("warning", contextDisplay);
          else contextLeft = contextDisplay;

          let left = theme.fg("dim", contextLeft);

          // Append the idle-since segment after the context block when the
          // agent is idle and has replied. Rendered compactly (no width
          // padding); the model on the right stays anchored via stretch padding.
          const idle =
            !agentActive && lastReplyTs ? formatIdleSinceValue(lastReplyTs) : undefined;
          if (idle) {
            const styledValue = idle.recent
              ? theme.bold(theme.fg("success", `idle ${idle.value}`))
              : `idle ${idle.value}`;
            const styledIcon = idle.recent
              ? theme.bold(theme.fg("success", IDLE_ICON))
              : IDLE_ICON;
            const idleSegment = `${styledIcon}${IDLE_ICON_GAP}${styledValue}`;
            left = `${left}${theme.fg("dim", IDLE_SEP)}${idleSegment}`;
          }

          let leftWidth = visibleWidth(left);
          if (leftWidth > width) {
            left = truncateToWidth(left, width, "...");
            leftWidth = visibleWidth(left);
          }

          let right = "";
          if (SHOW_MODEL) {
            const rawModelId = ctx.model?.id || "no-model";
            const modelName = MODEL_ALIASES[rawModelId] || rawModelId;
            let rightSide = modelName;
            if (ctx.model?.reasoning) {
              const thinkingLevel = (ctx as any).thinkingLevel || "off";
              const glyph = THINKING_GLYPHS[thinkingLevel] ?? THINKING_GLYPHS.off!;
              rightSide = `${modelName} ${glyph}`;
            }
            right = theme.fg("dim", rightSide);
          }

          const minPadding = 2;
          const rightWidth = visibleWidth(right);
          const totalNeeded = leftWidth + minPadding + rightWidth;
          let line: string;
          if (totalNeeded <= width) {
            line = left + " ".repeat(width - leftWidth - rightWidth) + right;
          } else if (rightWidth > 0 && width - leftWidth - minPadding > 0) {
            const avail = width - leftWidth - minPadding;
            const truncatedRight = truncateToWidth(right, avail, "");
            line = left + " ".repeat(Math.max(0, width - leftWidth - visibleWidth(truncatedRight))) + truncatedRight;
          } else {
            line = left;
          }
          lines.push(line);
          return lines;
        },
      };
    });
  };

  // Track when the agent produces a final reply (stopped, no tool calls).
  pi.on("turn_end", async (event) => {
    const msg = event.message as AssistantMessage;
    if (msg?.role === "assistant" && isFinalReply(msg)) {
      lastReplyTs = msg.timestamp;
      agentActive = false;
      tick();
    }
  });

  // While the agent is working, hide the counter (its own spinner shows then).
  pi.on("agent_start", async () => {
    agentActive = true;
    tick();
  });

  pi.on("session_start", async (_event, ctx) => {
    lastReplyTs = undefined;
    agentActive = false;
    if (enabled) applyFooter(ctx);
    startIdleTimer();
  });

  pi.on("session_shutdown", async () => {
    stopIdleTimer();
    tuiRef = undefined;
    lastReplyTs = undefined;
    agentActive = false;
  });

  pi.registerCommand("footer", {
    description: "Toggle the minimal context-only footer",
    handler: async (_args, ctx) => {
      enabled = !enabled;
      if (enabled) {
        applyFooter(ctx);
        startIdleTimer();
        ctx.ui.notify("Minimal footer enabled", "info");
      } else {
        ctx.ui.setFooter(undefined);
        stopIdleTimer();
        tuiRef = undefined;
        ctx.ui.notify("Default footer restored", "info");
      }
    },
  });
}