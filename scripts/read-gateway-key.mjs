// Read the FreeLLMAPI gateway (unified) API key so the launcher can hand it
// to Claude Code without the user copying it by hand.
//
// The router stores this key in the `settings` table of its SQLite database.
// Older or hand-made installs may instead keep a `.unified-key` file, so we
// fall back to that. Nothing here is a credential of ours: we only read back
// the key the router itself generated on first start.
//
// Usage: node read-gateway-key.mjs <router-dir>
// Prints the key on stdout, or nothing (exit 1) if it cannot be found.

import { readFileSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { createRequire } from 'node:module';

const routerDir = resolve(process.argv[2] ?? process.cwd());

function fromEnvOrFile() {
  // Legacy/simple layout: `<router>/.unified-key`, optionally prefixed `KEY=`.
  const file = join(routerDir, '.unified-key');
  if (!existsSync(file)) return null;
  const raw = readFileSync(file, 'utf8').trim();
  if (!raw) return null;
  const m = raw.match(/^(?:KEY\s*=\s*)?(.+)$/m);
  return m ? m[1].trim() : null;
}

function fromDatabase() {
  // The database location mirrors the server's own resolution order:
  // FREEAPI_DB_PATH, then <router>/server/data/freeapi.db.
  const candidates = [
    process.env.FREEAPI_DB_PATH?.trim(),
    join(routerDir, 'server', 'data', 'freeapi.db'),
  ].filter(Boolean);

  let Database;
  try {
    // Resolve better-sqlite3 from the router's own node_modules.
    const req = createRequire(join(routerDir, 'server', 'package.json'));
    Database = req('better-sqlite3');
  } catch {
    return null; // Not installed yet; caller falls back.
  }

  for (const dbPath of candidates) {
    if (!existsSync(dbPath)) continue;
    try {
      const db = new Database(dbPath, { readonly: true, fileMustExist: true });
      const row = db
        .prepare("SELECT value FROM settings WHERE key = 'unified_api_key'")
        .get();
      db.close();
      if (row?.value) return String(row.value).trim();
    } catch {
      // Locked or unexpected schema; try the next candidate.
    }
  }
  return null;
}

const key = fromEnvOrFile() ?? fromDatabase() ?? '';
if (key) {
  process.stdout.write(key);
  process.exit(0);
}
process.exit(1);
