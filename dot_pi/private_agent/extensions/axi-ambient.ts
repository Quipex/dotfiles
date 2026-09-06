import { spawn } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const TIMEOUT_MS = 10_000;
const CODEX_HOOKS_PATH = join(homedir(), ".codex", "hooks.json");

function runCommand(command: string, cwd: string): Promise<string> {
  return new Promise((resolve) => {
    const child = spawn(command, {
      cwd,
      shell: true,
      stdio: ["ignore", "pipe", "pipe"],
      env: process.env,
    });

    let stdout = "";
    const timer = setTimeout(() => {
      child.kill("SIGTERM");
      resolve("");
    }, TIMEOUT_MS);

    child.stdout.on("data", (chunk: Buffer | string) => {
      stdout += chunk;
    });

    child.on("close", (code) => {
      clearTimeout(timer);
      resolve(code === 0 ? stdout.trim() : "");
    });

    child.on("error", () => {
      clearTimeout(timer);
      resolve("");
    });
  });
}

function getRegisteredCommands(): string[] {
  if (!existsSync(CODEX_HOOKS_PATH)) {
    return ["gh-axi", "chrome-devtools-axi", "lavish-axi", "tasks-axi"];
  }
  try {
    const data = JSON.parse(readFileSync(CODEX_HOOKS_PATH, "utf-8"));
    const groups = data.hooks?.SessionStart ?? [];
    const commands: string[] = [];
    for (const group of groups) {
      for (const h of group.hooks ?? []) {
        if (h.command && !h.command.includes("herdr")) {
          commands.push(h.command);
        }
      }
    }
    return commands.length > 0 ? commands : ["gh-axi", "chrome-devtools-axi"];
  } catch {
    return ["gh-axi", "chrome-devtools-axi"];
  }
}

export default function axiAmbientExtension(pi: ExtensionAPI) {
  let cachedContext: string | null = null;
  let lastCwd: string = "";

  pi.on("session_start", () => {
    cachedContext = null;
  });

  pi.on("before_agent_start", async (event, ctx) => {
    if (cachedContext === null || lastCwd !== ctx.cwd) {
      lastCwd = ctx.cwd;
      const commands = getRegisteredCommands();
      const results = await Promise.all(
        commands.map(async (cmd) => {
          const out = await runCommand(cmd, ctx.cwd);
          if (!out) return null;
          return `## AXI ambient context: ${cmd}\n${out}`;
        })
      );
      cachedContext = results.filter(Boolean).join("\n\n");
    }

    if (!cachedContext) return;

    return {
      systemPrompt: event.systemPrompt + "\n\n" + cachedContext,
    };
  });
}
