#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# testi .env (ei commitata, poistetaan lopuksi)
cat > .env <<EOT
DB_NAME=cicdapp
DB_USER=cicduser
DB_PASS=testpass123
DB_ROOT_PASS=testroot456
EOT

docker compose up -d --build

for i in {1..40}; do
  if curl -fsS http://127.0.0.1:30081/ >/dev/null; then break; fi
  sleep 1
done

curl -fsS -X POST -d "name=ci&content=hello-from-test" http://127.0.0.1:30081/ >/dev/null
curl -fsS http://127.0.0.1:30081/ | grep -q "hello-from-test"

docker compose down -v
rm -f .env
echo "OK"
