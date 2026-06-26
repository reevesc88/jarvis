# Copilot Instructions — jarvis

Jarvis — Cal's personal AI assistant infrastructure. Part of The Conductor ecosystem.

## Context
- Owner: Calum Reeves (@reevesc88), Perth, WA
- Company: AI1AU Solutions (ai1auslutions.com)
- Related repos: jarvis-command-center (knowledge hub), conductor-brain (ops brain)

## Key Rules
- Secrets in `.env` only — never committed
- API keys via environment variables only
- Never push directly to master — use branches + PRs

## Token Budget
See conductor-brain repo (CONTEXT_CONTROL.md) for agent delegation rules.
Load SESSION_CONTEXT.md (jarvis-command-center) only at session start.
