# Claude Code on 10 Free LLM Providers

Point **Claude Code** at a local gateway that pools **10 different free LLM providers** — and have it **fail over automatically** when one is rate-limited, busy, or down. No paid API key. No per-provider client config. One command to start.

```
You type a prompt
      ↓
Claude Code  →  http://127.0.0.1:3001   (one local gateway)
      ↓
Router picks the best available model
      ↓
  works?  → answer, instantly
  busy?   → silently move to the next provider
  down?   → silently move to the next provider
      ↓
You get the answer — and never see an error
```

A single real request from this setup, showing the trail:

```
X-Routed-Via: groq/openai/gpt-oss-20b
X-Fallback-Attempts: 3
X-Fallback-Trail: kilo/nemotron:free      → rate_limited
                  ovh/Qwen3.5-397B-A17B   → rate_limited
                  aihorde/Cydonia-24B     → upstream_error
                  groq/gpt-oss-20b        → served ✅
```

Four providers tried, three failed, one answer. The user saw nothing.

---

## What you get

| | |
|---|---|
| **10 providers** | Google Gemini + Groq (keys you supply) plus 8 that work with **no key at all** |
| **1 endpoint** | `http://127.0.0.1:3001` — OpenAI- and Anthropic-compatible |
| **0 cost** | every provider is a genuine free tier |
| **Automatic failover** | on 429 / 5xx / errors, across providers, invisible to you |
| **Anything that speaks the API works** | Claude Code, Cursor, Cline, Aider, Continue, Codex, any OpenAI SDK |

### The providers

| Provider | Key needed? | Free allowance |
|---|---|---|
| **Google Gemini** | yes (email only) | generous daily quota |
| **Groq** | yes (email only) | ~30 req/min, ~1000/day, very fast |
| **Kilo Gateway** | no | 200 req/hr per IP |
| **OVH AI Endpoints** | no | 2 req/min per IP |
| **AI Horde** | no | community queue, no token cap |
| **LLM7** | no | 100 req/hr |
| **AI SENSE** | no | decision relay |
| **HAL-X** | no | decision relay |
| **Parallel** | no | search |
| **Pollinations** | no | anonymous text generation |

> **Two keys get you the most capacity.** Google and Groq are email-only signups with no credit card. Everything else is a bonus that adds resiliency.

---

## Quick start

### Windows

```cmd
git clone https://github.com/Abobakr-1/freellmapi-claude-setup.git
cd freellmapi-claude-setup
setup.cmd
```

Then double-click **`OPEN-CLAUDE.cmd`** any time you want to code.

### Manual (any OS)

```bash
# 1. Get FreeLLMAPI (the router underneath) - see "Credits" below
# 2. Point Claude Code at it
export ANTHROPIC_BASE_URL=http://127.0.0.1:3001
export ANTHROPIC_AUTH_TOKEN=<your-gateway-key>
export ANTHROPIC_MODEL=auto
claude
```

---

## Adding your provider keys

Two ways — pick one.

### A. The setup wizard (recommended)

Run `setup.cmd`. It asks for your Google and Groq keys and writes everything for you. Get them here:

- **Google Gemini** → <https://aistudio.google.com/apikey> (free, email only)
- **Groq** → <https://console.groq.com/keys> (free, email only)

### B. Edit the config

Copy the template and fill it in:

```bash
cp config/freellmapi.config.example.json <freellmapi>/server/data/freellmapi.config.json
```

The `example` file in this repo has **placeholder keys only** — replace them with your own.

> **Never commit real keys.** The example config ships with `YOUR_GROQ_KEY_HERE` style placeholders on purpose.

---

## Files in this repo

| File | What it does |
|---|---|
| `setup.cmd` | One-time installer: clones FreeLLMAPI, installs deps, builds, prompts for keys, writes config |
| `OPEN-CLAUDE.cmd` | Daily launcher: starts the gateway if needed, waits for health, opens Claude Code |
| `config/freellmapi.config.example.json` | Provider + routing template with placeholder keys |
| `docs/TROUBLESHOOTING.md` | When things go wrong |
| `docs/PROVIDER-CAPACITY.md` | Honest numbers on what free tiers really give you |

---

## Verify it works

```bash
# gateway up?
curl -s http://127.0.0.1:3001/v1/models -H "Authorization: Bearer $YOUR_KEY" -o /dev/null -w "%{http_code}\n"
# → 200

# which providers are healthy?
curl -s http://127.0.0.1:3001/api/keys -H "Authorization: Bearer $YOUR_DASHBOARD_TOKEN"
```

Then simply ask Claude Code something:

```
claude -p "Reply with exactly: WORKS"
```

---

## How the failover works

The gateway keeps a **live health score** for every provider, learned from real latency and success rate. Each request walks an ordered chain:

- **Pre-flight limits** — a provider already at its RPM/TPM cap is skipped before a request is even sent.
- **Cooldowns, not crashes** — a `429` parks that provider briefly and moves on immediately.
- **Sticky sessions** — follow-up turns prefer the model that just worked, so context stays coherent.
- **Visible trail** — every response carries `X-Routed-Via` and `X-Fallback-Trail`.

---

## Honest limits

This repo is a **setup kit**, not magic. A few things worth stating plainly:

- **The free tier is the real ceiling.** No configuration can make a provider grant more than its free allowance.
- **Rate limits are per-provider.** When every provider is busy at once, you wait. That is rare with 10, but possible.
- **No key = rate-limited, not token-metered.** The 8 keyless providers are capped by requests per minute, not monthly tokens.
- **Provider free tiers change.** They launch, retire, and re-price without notice.

See [`docs/PROVIDER-CAPACITY.md`](docs/PROVIDER-CAPACITY.md) for the numbers.

---

## Credits

The router doing the real work is **[FreeLLMAPI](https://github.com/tashfeenahmed/freellmapi)** by
[Tashfeen Ahmed](https://github.com/tashfeenahmed) — MIT licensed. This repo is a thin **setup kit**
around it (launcher, config template, docs) and ships **none** of its source. Go star the original.

Claude Code is Anthropic's CLI. This kit does not modify it — it only points it at your local gateway.

## License

MIT — see [`LICENSE`](LICENSE).
