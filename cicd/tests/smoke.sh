#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

cat > .env <<EOT
DB_NAME=cicdapp
DB_USER=cicduser
DB_PASS=testpass123
DB_ROOT_PASS=testroot456
EOT

docker compose up -d --build

ok=0
for i in {1..180}; do
  if curl -fsS http://127.0.0.1:30081/ >/dev/null; then ok=1; break; fi
  sleep 1
done

if [ "$ok" -ne 1 ]; then
  echo "ERROR: web ei noussut 180s sisällä"
  docker compose ps || true
  docker compose logs --tail=200 || true
  docker compose down -v || true
  rm -f .env || true
  exit 1
fi

curl -fsS -X POST -d "name=ci&content=hello-from-test" http://127.0.0.1:30081/ >/dev/null
curl -fsS http://127.0.0.1:30081/ | grep -q "hello-from-test"

docker compose down -v
rm -f .env
echo "OK"

