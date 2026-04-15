---
title: AI Agent Frameworks Comparison
---

# AI Agent Frameworks Comparison

A factual comparison of six frameworks for building Claude-based or general-purpose
AI agents in production. Focus: tool-usage control, deployment, and what each gives
you out of the box.

---

## The Six Options

| # | Name | One-line description |
|---|---|---|
| 1 | **Claude Code CLI** | Anthropic's terminal binary. `claude -p` runs headlessly. |
| 2 | **Claude Agent SDK** | Same engine as Claude Code, exposed as a Python or TypeScript library. |
| 3 | **Claude Managed Agents** | Anthropic-hosted agent harness. You call an API; they run the container. |
| 4 | **Deep Agents** | LangChain/LangGraph harness. Python and JS. Provider-agnostic. |
| 5 | **OpenCode** | Open-source Go binary. 75+ LLM providers. Client/server architecture. |
| 6 | **Messages API** | Raw API. You write the agent loop yourself. |

---

## Master Comparison

### Runtime & deployment

| | CLI | Agent SDK | Managed | Deep Agents | OpenCode | Messages API |
|---|---|---|---|---|---|---|
| **Language** | Node binary | Python / TS | Any (HTTP) | Python / JS | Go binary | Any |
| **Where it runs** | Self-hosted | Self-hosted | Anthropic cloud | Self-hosted | Self-hosted | Self-hosted |
| **Headless server use** | OK (forks per call) | First-class | First-class | First-class | First-class | First-class |
| **Container size** | ~500 MB | ~300 MB | N/A | ~200 MB | ~50 MB | depends |
| **Per-request startup cost** | 1–2 s (subprocess) | None (in-process) | None | None | None | None |
| **License** | Commercial ToS | Commercial ToS | Commercial ToS | MIT | Apache-2.0 | Commercial ToS (API) |

### Models & providers

| | CLI | Agent SDK | Managed | Deep Agents | OpenCode | Messages API |
|---|---|---|---|---|---|---|
| **Anthropic API** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Bedrock / Vertex / Foundry** | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ |
| **Custom proxy (e.g. LiteLLM)** | ✅ via env var | ✅ via env var | ❌ | ✅ | ✅ | ✅ |
| **OpenAI / other vendors** | ❌ | ❌ | ❌ | ✅ | ✅ (75+) | API-specific |
| **Local models (Ollama, etc.)** | ❌ | ❌ | ❌ | ✅ | ✅ | API-specific |

### Built-in tools

| | CLI | Agent SDK | Managed | Deep Agents | OpenCode | Messages API |
|---|---|---|---|---|---|---|
| **File read / write / edit** | ✅ | ✅ | ✅ | ✅ (virtual FS) | ✅ | ❌ |
| **Shell / Bash** | ✅ | ✅ | ✅ | ✅ (sandbox backends) | ✅ | ❌ |
| **Web search** | ✅ | ✅ | ✅ | via tools | ✅ | ❌ |
| **Web fetch** | ✅ | ✅ | ✅ | via tools | ✅ | ❌ |
| **Glob / Grep** | ✅ | ✅ | ✅ | via tools | ✅ | ❌ |
| **Planning / todos** | ✅ (TodoWrite) | ✅ | ✅ | ✅ (`write_todos`) | ✅ | ❌ |
| **Subagents** | ✅ | ✅ | ✅ (preview) | ✅ (`task` tool) | ✅ | ❌ |
| **Custom tools** | via MCP only | code or MCP | via MCP | code or MCP | plugin system | code |

### Sessions & state

| | CLI | Agent SDK | Managed | Deep Agents | OpenCode | Messages API |
|---|---|---|---|---|---|---|
| **Multi-turn** | `--resume` | `resume:` option | sessions API | LangGraph threads | built-in | DIY |
| **Where state lives** | local JSONL files | local JSONL files | Anthropic cloud | LangGraph store | local files | DIY |
| **Cross-session memory** | CLAUDE.md + memory dir | same | server-side | LangGraph Memory Store | similar | DIY |
| **Forking sessions** | ✅ | ✅ | ✅ | ✅ | ✅ | DIY |

---

## Tool-Usage Control

This is the dimension worth examining closely. "Which tools exist?" is easy —
"Can my code intervene before a tool runs?" is the question that separates
frameworks.

### Control surfaces explained

| Surface | What it lets you do |
|---|---|
| **Allow/deny list** | Pick which tools the agent is even shown |
| **Pattern matching** | Allow `Bash(git:*)` but deny `Bash(rm:*)` |
| **Permission modes** | Broad policy: "ask each time" / "auto-approve edits" / "skip all prompts" |
| **Pre-execution callback** | Your code runs before each tool call. Can block, modify input, or proceed. |
| **Post-execution callback** | Your code runs after each tool call. Can audit, log, react. |
| **Human approval gate** | Pause execution and wait for an external "yes" |
| **Runtime interrupt** | Inject a new instruction or cancel mid-run |

### How each framework supports them

| Surface | CLI | Agent SDK | Managed | Deep Agents | OpenCode | Messages API |
|---|---|---|---|---|---|---|
| Allow/deny list | ✅ | ✅ | ✅ | ✅ | ✅ | DIY |
| Pattern matching | ✅ (e.g. `Bash(git:*)`) | ✅ | basic | basic | basic | DIY |
| Permission modes | ✅ (4 modes) | ✅ (4 modes) | broad config | basic | basic | DIY |
| Pre-execution callback | shell script | **native code** | ❌ | **native code** (LangGraph nodes) | plugin | DIY |
| Post-execution callback | shell script | native code | event stream only | native code | plugin | DIY |
| Human approval gate | interactive only | ✅ (`canUseTool`) | ✅ | ✅ (LangGraph interrupts) | ✅ | DIY |
| Runtime interrupt | ❌ (in `-p` mode) | ✅ | ✅ | ✅ | ✅ | DIY |

### What "native code callback" means in practice

A pre-execution callback in code lets you write logic like:

```python
async def guard_bash(input, tool_use_id, context):
    cmd = input["tool_input"]["command"]
    if cmd.startswith("rm -rf") or "DROP TABLE" in cmd:
        await audit_log.record_blocked(cmd, user=context.user_id)
        return {"decision": "block", "reason": "destructive command"}
    if not rate_limiter.allow(context.user_id):
        return {"decision": "block", "reason": "rate limited"}
    return {}
```

You can call your application's database, your auth service, your rate limiter,
your metrics pipeline. With a shell-script hook you can do the same things, but
through subprocess invocations and JSON-on-stdout. With no callback, you can only
control which tools exist, not how they're called.

---

## Per-Option Summary

### 1. Claude Code CLI

The terminal binary that most developers use directly. Forks a subprocess per
call in headless mode. Reads `CLAUDE.md`, `~/.claude/settings.json`, skills,
slash commands, and memories from disk automatically.

| Pros | Cons |
|---|---|
| Most mature interface | Subprocess-per-call adds 1–2 s of startup |
| Drop-in install (`npm i -g`) | Hooks are shell scripts, not code |
| All Claude Code config files load automatically | Error reporting is via stderr strings |
| Works with any Anthropic-compatible endpoint | Session files can deadlock on mid-run failures |
| MCP servers via settings.json | Heavy container image |

### 2. Claude Agent SDK

The CLI's engine, exposed as a Python or TypeScript library. The agent loop
runs inside your process.

| Pros | Cons |
|---|---|
| Same engine, same session format as CLI | Python or TypeScript only |
| Pre/post-execution hooks are real callbacks | Migration cost from CLI ≈ 1 day |
| Typed errors, typed subagent definitions | Same on-disk session format → same race conditions |
| No subprocess overhead | Anthropic models only (via API, Bedrock, Vertex, or Foundry) |
| Programmatic MCP server registration | |

### 3. Claude Managed Agents

Anthropic hosts the agent loop, the container, and the filesystem. You POST
events and read SSE responses.

| Pros | Cons |
|---|---|
| Zero infrastructure to maintain | Runs in Anthropic's cloud, not yours |
| Sessions and FS state are server-side | No access to private repos, internal CLIs, or your VPC |
| Built-in container sandbox | No custom LLM provider (Anthropic API only) |
| Long-running tasks (minutes to hours) | No pre-execution callback — control is config-only |
| Multi-agent in research preview | Beta API, may change |

### 4. Deep Agents

LangChain's harness on top of LangGraph. Provider-agnostic, designed for
multi-step planning workflows.

| Pros | Cons |
|---|---|
| Provider-agnostic from day one (Anthropic, OpenAI, Google, Ollama, etc.) | Different config and tool conventions than Claude Code |
| LangGraph runtime: durable execution, streaming, human-in-the-loop | Coupled to the LangChain ecosystem |
| Built-in planning (`write_todos`) and subagents (`task`) | Smaller community than Claude Code |
| Pluggable filesystem backends (in-memory, local, sandboxed) | No CLAUDE.md / Claude Code config compatibility |
| Long-term memory across threads via LangGraph Memory Store | Learning curve if you don't already use LangChain |
| MIT license | |

### 5. OpenCode

Open-source Go binary. Pluggable LLM providers. Client/server architecture
makes remote agent execution natural.

| Pros | Cons |
|---|---|
| Apache-2.0, fork-friendly | Less polished than Claude Code |
| 75+ LLM providers via models.dev | Anthropic blocked consumer OAuth tokens (Jan 2026) — direct API keys only |
| Single Go binary, small image | Different session and config formats than Claude Code |
| Client/server split for remote execution | Smaller set of pre-tuned defaults |
| LSP-aware tool context (unique) | |
| First-class plugin system for custom tools | |

### 6. Messages API + Custom Loop

Direct calls to `/v1/messages`. You write the loop, the tool dispatcher, the
session store, the retry logic, and everything else.

| Pros | Cons |
|---|---|
| Total control over every byte | You implement everything from scratch |
| No framework lock-in | No built-in optimizations (caching, compaction, truncation) |
| Any language | Months of work to match a harness |
| Easiest to audit | Ongoing maintenance as the API evolves |

---

## Decision Guide

### If your top priority is...

| Priority | Pick |
|---|---|
| Fastest path to a working agent | Claude Code CLI |
| Code-level tool control + low latency | Claude Agent SDK |
| No infrastructure to manage | Claude Managed Agents |
| Multi-provider, long-running, planning-heavy workflows | Deep Agents |
| Open source, vendor independence | OpenCode |
| Requirements no harness can meet | Messages API |

### If you need access to private infrastructure

(your repos, internal CLIs, GKE/k8s, VPC services, custom networks)

| Framework | Works |
|---|---|
| Claude Code CLI | ✅ |
| Claude Agent SDK | ✅ |
| Claude Managed Agents | ❌ |
| Deep Agents | ✅ |
| OpenCode | ✅ |
| Messages API | ✅ |

### If you need code-level control over every tool call

| Framework | Works |
|---|---|
| Claude Code CLI | ⚠️ via shell scripts only |
| Claude Agent SDK | ✅ |
| Claude Managed Agents | ❌ |
| Deep Agents | ✅ (LangGraph nodes) |
| OpenCode | ⚠️ via plugins |
| Messages API | ✅ (you write it) |

### How hard is it to migrate later?

| From → To | Difficulty | Why |
|---|---|---|
| CLI → Agent SDK | Easy | Same session format, same config files |
| Agent SDK → CLI | Easy | Same |
| CLI → Deep Agents | Medium | Different config and session formats |
| CLI → OpenCode | Medium | Different config and session formats |
| Anything → Managed Agents | Easy | Configuration only, no lock-in code |
| Managed Agents → anything | Easy | Same |
| Anything → Messages API | Hard one-way | You wrote a loop; reverting means deleting it |

### Lock-in spectrum

```
Less lock-in                                                    More lock-in
─────────────────────────────────────────────────────────────────────────────
Messages API → Deep Agents → OpenCode → Claude Code CLI → Agent SDK → Managed
```

---

## Sources

- [Claude Agent SDK overview](https://code.claude.com/docs/en/agent-sdk/overview)
- [Agent SDK TypeScript reference](https://platform.claude.com/docs/en/agent-sdk/typescript)
- [Agent SDK Python reference](https://platform.claude.com/docs/en/agent-sdk/python)
- [Run Claude Code programmatically (headless)](https://code.claude.com/docs/en/headless)
- [claude-agent-sdk-typescript on GitHub](https://github.com/anthropics/claude-agent-sdk-typescript)
- [Claude Managed Agents overview](https://platform.claude.com/docs/en/managed-agents/overview)
- [Deep Agents overview — LangChain docs](https://docs.langchain.com/oss/python/deepagents/overview)
- [langchain-ai/deepagents on GitHub](https://github.com/langchain-ai/deepagents)
- [langchain-ai/deepagentsjs on GitHub](https://github.com/langchain-ai/deepagentsjs)
- [OpenCode — opencode.ai](https://opencode.ai/)
