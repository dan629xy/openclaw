#!/usr/bin/env sh
set -eu

CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-/home/node/.openclaw/openclaw.json}"

if [ -z "${FEISHU_APP_ID:-}" ] || [ -z "${FEISHU_APP_SECRET:-}" ]; then
  if [ -f "$CONFIG_PATH" ]; then
    extracted="$(
      node -e '
const fs = require("node:fs");
const file = process.argv[1];
try {
  const raw = fs.readFileSync(file, "utf8");
  let cfg;
  try {
    cfg = JSON.parse(raw);
  } catch {
    const JSON5 = require("json5");
    cfg = JSON5.parse(raw);
  }
  const feishu = cfg?.channels?.feishu ?? {};
  const appId = typeof feishu.appId === "string" ? feishu.appId.trim() : "";
  const appSecret = typeof feishu.appSecret === "string" ? feishu.appSecret.trim() : "";
  process.stdout.write(`${appId}\n${appSecret}\n`);
} catch {
  process.stdout.write("\n\n");
}
' "$CONFIG_PATH"
    )"

    extracted_app_id="$(printf "%s" "$extracted" | sed -n "1p")"
    extracted_app_secret="$(printf "%s" "$extracted" | sed -n "2p")"

    if [ -z "${FEISHU_APP_ID:-}" ] && [ -n "$extracted_app_id" ]; then
      FEISHU_APP_ID="$extracted_app_id"
      export FEISHU_APP_ID
      echo "[bootstrap-env] FEISHU_APP_ID injected from config."
    fi
    if [ -z "${FEISHU_APP_SECRET:-}" ] && [ -n "$extracted_app_secret" ]; then
      FEISHU_APP_SECRET="$extracted_app_secret"
      export FEISHU_APP_SECRET
      echo "[bootstrap-env] FEISHU_APP_SECRET injected from config."
    fi
  else
    echo "[bootstrap-env] Config not found at $CONFIG_PATH; skipping Feishu env injection."
  fi
fi

if [ -n "${FEISHU_APP_ID:-}" ] && [ -n "${FEISHU_APP_SECRET:-}" ]; then
  echo "[bootstrap-env] Feishu env ready."
else
  echo "[bootstrap-env] Feishu env incomplete (missing FEISHU_APP_ID or FEISHU_APP_SECRET)."
fi

exec node dist/index.js gateway --bind "${OPENCLAW_GATEWAY_BIND:-lan}" --port 18789
