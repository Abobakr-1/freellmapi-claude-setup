# Provider capacity — real numbers

Free LLM tiers get advertised with big numbers. Here are the honest ones, measured
against a live install rather than marketing copy.

---

## The short version

| Scope | Realistic monthly capacity |
|---|---|
| This kit, out of the box (2 keys + 8 keyless) | **tens of millions of tokens/month**, plus request-rate headroom |
| Keyless providers (8 of them) | rate-limited (req/min), **not** monthly token budgets |
| Every documented provider in the catalog, keyed | a few hundred million/month |

**There is no configuration that turns a free tier into billions of tokens.** The
provider's own allowance is the ceiling.

---

## Why the headline numbers look enormous

You will see claims like *"10 billion tokens/month across 87 providers."* Those numbers
are computed by **summing the monthly budget label of every model row separately**.

That double-counts. One Google project pool (~30M/month) is shared across *all* Gemini
models — but it gets counted once per model in the sum:

| Model | Label |
|---|---|
| gemini-2.5-flash | 3 M |
| gemini-3.5-flash | 3 M |
| gemini-3.8-flash | 3 M |
| ...12 more models | 3 M each |
| gemma-4-31b | 30 M |
| **Naive sum across models** | **96 M** |
| **Actual account-level pool** | **~30 M** |

Measured across the whole catalog in one install:

| Method | Result |
|---|---|
| Sum of every model label | **1.11 B** |
| Max per provider (pool-aware) | **0.25 B** |
| Inflation | **4.4×** |

So when you read a headline, divide by roughly 4 — then remember it also assumes you
keyed **every** provider, which requires dozens of separate signups.

---

## Why keyless providers show 0 monthly tokens

Kilo, OVH, AI Horde, LLM7 and friends meter **requests per minute or per hour**, not
monthly tokens. There is no "monthly budget" to report — they will serve you happily
for as long as you stay under the rate limit, then throttle you until the window resets.

That is why the dashboard may show `0 M` next to a provider that is working perfectly.
It is not broken; it is unmetered in the way the dashboard counts.

---

## What actually increases your capacity

Ranked by benefit per effort:

| Provider | Key? | Rough free allowance | Notes |
|---|---|---|---|
| **Mistral** | yes | ~50–100 M/mo | console.mistral.ai, no card |
| **Cloudflare Workers AI** | yes | ~18–45 M/mo | needs account ID + token |
| **Zhipu / Z.ai** | yes | ~30 M/mo | z.ai, no card |
| **Cerebras** | yes | ~30 M/mo | cloud.cerebras.ai, very fast |
| **Google Gemini** | yes | ~30 M/mo pool | aistudio.google.com |
| **Groq** | yes | ~15 M/mo + high RPM | console.groq.com |
| **Cohere** | yes | ~1–2 M/mo | dashboard.cohere.com |
| **NVIDIA NIM** | yes | credit pool, 40 RPM | build.nvidia.com |

**Two keys (Google + Groq) already get you the bulk of practical headroom.** The rest
adds resilience more than raw volume.

---

## What you should *not* expect

- **Billions of tokens for one person, with no card.** The providers that offer that
  volume require a card, a phone number, or (for several Chinese clouds) real-name
  identity verification.
- **"Free" gateways that ask for nothing.** We tested several advertised anonymous
  endpoints while building this kit — most return `401`, `402`, or `403` until you
  pay. Airforce, for example, answers every model with *"requires an active
  subscription or a positive Pay-As-You-Go balance."*
- **Stable numbers.** Free tiers launch, retire and re-price without notice. Treat
  every figure here as a snapshot, not a promise.

---

## How this kit stays honest

- It ships a config with **placeholder** keys only.
- The README states the free tier is the real ceiling.
- The launcher reads the gateway key from the router's own file instead of hardcoding
  a secret into the repo.
