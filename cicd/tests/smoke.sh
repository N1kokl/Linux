#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "PWD: $(pwd)"
ls -la

echo "--- docker info ---"
docker --version
docker compose version

# tee .env testia varten (käytä .env.example jos löytyy)
if [ -f .env.example ]; then
  cp .env.example .env
else
  : > .env
fi

set_kv () {
  local k="$1" v="$2"
  if grep -qE "^${k}=" .env; then
    sed -i "s#^${k}=.*#${k}=${v}#g" .env
  else
    printf "%s=%s\n" "$k" "$v" >> .env
  fi
}

set_kv DB_NAME "cicdapp"
set_kv DB_USER "cicduser"
set_kv DB_PASS "testpass123"
set_kv DB_ROOT_PASS "testroot456"

echo "--- compose up ---"
docker compose up -d --build

echo "--- wait for web ---"
ok=0
for i in {1..180}; do
  if curl -fsS http://127.0.0.1:30081/ >/dev/null; then ok=1; break; fi
  sleep 1
done

if [ "$ok" -ne 1 ]; then
  echo "ERROR: web ei vastannut 180s sisällä"
  docker compose ps || true
  docker compose logs --tail=200 || true
  docker compose down -v || true
  exit 1
fi

echo "OK: web vastaa"
docker compose down -v
rm -f .env


