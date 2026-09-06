/**
 * Bell Extension — rings the terminal bell only when the agent truly finishes
 * and is waiting for input (not on every retry / compaction / tool-loop turn).
 *
 * Strategy: on `agent_end` start a short debounce timer. If a new `agent_start`
 * arrives within the window, the agent re-entered its loop (retry after error,
 * auto-compaction, queued follow-up, …) — cancel the timer. If no new
 * `agent_start` arrives, the agent is idle and waiting for input → ring the
 * bell once.
 *
 * tmux picks this up via `monitor-bell on` and flags the window in the status
 * line (window-status-bell-style), so you notice when pi is ready on an
 * unfocused window/pane.
 *
 * Auto-discovered from ~/.pi/agent/extensions/*.ts.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Grace window after agent_end before we decide the agent is truly idle. */
const IDLE_DEBOUNCE_MS = 1000;

export default function (pi: ExtensionAPI) {
	let timer: ReturnType<typeof setTimeout> | undefined;

	const ring = () => {
		timer = undefined;
		process.stdout.write("\x07");
	};

	pi.on("agent_end", async () => {
		// Clear any pending timer (shouldn't normally happen, but be safe).
		if (timer !== undefined) clearTimeout(timer);
		// Assume this is the final agent_end unless a new agent_start says otherwise.
		timer = setTimeout(ring, IDLE_DEBOUNCE_MS);
	});

	pi.on("agent_start", async () => {
		// Agent re-entered its loop — the previous agent_end was not final.
		if (timer !== undefined) {
			clearTimeout(timer);
			timer = undefined;
		}
	});
}