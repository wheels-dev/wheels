import type Anthropic from "@anthropic-ai/sdk";

type AnyEvent = { id: string; type: string; [k: string]: unknown };

export interface RunTurnResult {
  finalText: string;
  events: AnyEvent[];
  status: "idle" | "terminated";
  stopReason?: string;
}

/**
 * Run one turn of a session: send a user message, drain the SSE stream until
 * the agent goes idle with a terminal stop_reason or terminates. Reuses the
 * same session across calls — each call is one user/assistant exchange.
 *
 * Stream-first: opens the SSE stream before sending the user message so we
 * don't miss the early events. (See managed-agents-events.md → Stream-first.)
 *
 * Idle gate: breaks on session.status_terminated, or on session.status_idle
 * unless stop_reason.type === "requires_action" (transient; agent is waiting
 * on a client-side response).
 */
export async function runTurn(
  client: Anthropic,
  sessionId: string,
  message: string,
  options: {
    onText?: (delta: string) => void;
    onEvent?: (event: AnyEvent) => void;
  } = {},
): Promise<RunTurnResult> {
  const events: AnyEvent[] = [];

  // Stream-first ordering — open before send.
  const stream = await client.beta.sessions.events.stream(sessionId);

  await client.beta.sessions.events.send(sessionId, {
    events: [
      {
        type: "user.message",
        content: [{ type: "text", text: message }],
      },
    ],
  });

  let status: "idle" | "terminated" = "idle";
  let stopReason: string | undefined;
  const turnTextParts: string[] = [];

  for await (const event of stream as unknown as AsyncIterable<AnyEvent>) {
    events.push(event);
    options.onEvent?.(event);

    if (event.type === "agent.message") {
      const blocks = (event as { content?: { type: string; text?: string }[] })
        .content;
      if (blocks) {
        for (const b of blocks) {
          if (b.type === "text" && b.text) {
            turnTextParts.push(b.text);
            options.onText?.(b.text);
          }
        }
      }
    }

    if (event.type === "session.status_terminated") {
      status = "terminated";
      break;
    }
    if (event.type === "session.status_idle") {
      const sr = (event as { stop_reason?: { type?: string } }).stop_reason;
      const reason = sr?.type;
      if (reason !== "requires_action") {
        status = "idle";
        stopReason = reason;
        break;
      }
      // requires_action — agent is waiting on a client-side response
      // (tool confirmation or custom tool result). We don't wire those up,
      // so this is a configuration bug; surface it.
      throw new Error(
        `Session ${sessionId} idle with requires_action — neither tool confirmations nor custom tools are wired up in this orchestrator.`,
      );
    }
  }

  return {
    finalText: turnTextParts.join(""),
    events,
    status,
    stopReason,
  };
}

/**
 * Wait for a session's queryable status to settle. The SSE stream emits
 * status_idle slightly before sessions.retrieve() reflects it, so calls that
 * mutate the session (delete/archive) can race. Returns the final status.
 */
export async function waitForSessionToSettle(
  client: Anthropic,
  sessionId: string,
  maxWaitMs = 5000,
): Promise<string> {
  const deadline = Date.now() + maxWaitMs;
  let status = "running";
  while (Date.now() < deadline) {
    const s = await client.beta.sessions.retrieve(sessionId);
    status = s.status;
    if (status !== "running") return status;
    await new Promise((r) => setTimeout(r, 200));
  }
  return status;
}
