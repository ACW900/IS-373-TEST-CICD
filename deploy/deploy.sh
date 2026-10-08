#!/usr/bin/env bash
# Usage: deploy.sh <qa|prod> <full-image-ref>
# Runs on the server. Updates one environment and rolls back if it never becomes healthy.
set -euo pipefail

ENVIRONMENT="${1:?usage: deploy.sh <qa|prod> <image>}"
IMAGE="${2:?usage: deploy.sh <qa|prod> <image>}"

cd "$(dirname "$0")"
touch .env

case "$ENVIRONMENT" in
  qa)   KEY=QA_IMAGE;   SERVICE=site-qa ;;
  prod) KEY=PROD_IMAGE; SERVICE=site-prod ;;
  *)    echo "Unknown environment: $ENVIRONMENT" >&2; exit 1 ;;
esac

PREVIOUS="$(grep "^${KEY}=" .env | cut -d= -f2- || true)"

set_image() {
  if grep -q "^${KEY}=" .env; then
    sed -i "s|^${KEY}=.*|${KEY}=$1|" .env
  else
    echo "${KEY}=$1" >> .env
  fi
}

wait_healthy() {
  for _ in $(seq 1 30); do
    status="$(docker inspect -f '{{.State.Health.Status}}' "$SERVICE" 2>/dev/null || echo starting)"
    [ "$status" = "healthy" ] && return 0
    sleep 2
  done
  return 1
}

echo "Deploying $IMAGE to $ENVIRONMENT"
set_image "$IMAGE"
docker compose pull "$SERVICE"
docker compose up -d --remove-orphans
docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile >/dev/null 2>&1 \
  || docker compose restart caddy

if wait_healthy; then
  docker image prune -f >/dev/null
  echo "Deployed $IMAGE to $ENVIRONMENT"
else
  echo "Health check failed for $SERVICE" >&2
  docker compose logs --tail=30 "$SERVICE" >&2 || true
  if [ -n "$PREVIOUS" ]; then
    echo "Rolling back to $PREVIOUS" >&2
    set_image "$PREVIOUS"
    docker compose up -d "$SERVICE"
  fi
  exit 1
fi
