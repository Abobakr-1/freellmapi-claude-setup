# Troubleshooting

## "Gateway did not answer after 40 seconds"

Open the minimised window titled **free-LLM gateway** and read the error.

**Most common cause: a missing or invalid config.** The gateway exits immediately if
`freellmapi.config.json` is malformed. Validate it:

```bash
node -e "JSON.parse(require('fs').readFileSync('server/data/freellmapi.config.json','utf8'));console.log('config OK')"
```

**Second cause: port already in use.** Something else is on 3001:

```cmd
netstat -ano | findstr :3001
```

---

## "Could not read the gateway key"

The launcher reads `<router>/.unified-key`. That file is created the **first time the
gateway starts**. If it is missing, start the gateway once by hand:

```cmd
cd ..\freellmapi
node server\dist\index.js
```

The key also prints in the startup banner and lives in the dashboard under **Keys**.

---

## Claude Code replies but the answer looks truncated or odd

Some free models emit a *reasoning* preamble before the answer. If you see
`"Here's a thinking process..."`, the model is reasoning out loud. Ask it to be brief,
or switch model inside Claude Code with `/model`.

---

## "[claude-code:unrecognized_model] {"model":"auto"}"

Harmless. Claude Code notes that `auto` is not a native Anthropic model name.
Routing still works. To silence it, set `ANTHROPIC_MODEL` to a concrete catalog id
listed by `GET /v1/models`.

---

## Every provider is rate-limited at once

Rare with 10 providers, but possible under heavy load. Options:

1. **Wait** — most cooldowns clear in 30–90 seconds.
2. **Add a key** — a keyed provider (Gemini, Groq) carries far more headroom than the
   keyless ones.
3. **Check who is healthy:**

```cmd
curl -s http://127.0.0.1:3001/api/keys -H "Authorization: Bearer YOUR_DASHBOARD_TOKEN"
```

If a provider shows `"status":"invalid"`, its key is wrong or expired — fix it in the
dashboard at <http://127.0.0.1:3001>.

---

## Claude Code ignores the gateway and asks for an Anthropic login

Your `~/.claude/settings.json` is missing the gateway settings, or a pre-existing
`ANTHROPIC_API_KEY` is overriding them. Check:

```cmd
type %USERPROFILE%\.claude\settings.json
```

You want to see `ANTHROPIC_BASE_URL` pointing at `http://127.0.0.1:3001`. If an
`ANTHROPIC_API_KEY` variable is set anywhere (system env, `.env`, shell profile),
remove it — the gateway uses `ANTHROPIC_AUTH_TOKEN` instead.

Re-running `OPEN-CLAUDE.cmd` rewrites the settings correctly.

---

## The dashboard login does not work

The account is created only on the **first** start, from the `admin` block in your
config. If you changed the password in the config *after* first start, it has no effect —
the account already exists.

To reset, delete the database and start again (this also clears history):

```cmd
del server\data\freeapi.db
```

---

## Resetting everything

```cmd
cd ..\freellmapi
del server\data\freeapi.db
del .unified-key
```

Next start rebuilds the database, re-reads your config, and mints a fresh gateway key.
