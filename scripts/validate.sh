#!/usr/bin/env bash
# Basic validation. A failure here stops the pipeline before anything is built or deployed.
set -euo pipefail

fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f site/index.html ]            || fail "site/index.html is missing"
grep -qi "<title>" site/index.html  || fail "site/index.html has no <title>"
grep -qi "</html>" site/index.html  || fail "site/index.html has no closing </html>"
[ -f Dockerfile ]                 || fail "Dockerfile is missing"
[ -f deploy/docker-compose.yml ]  || fail "deploy/docker-compose.yml is missing"
[ -f deploy/Caddyfile ]           || fail "deploy/Caddyfile is missing"
[ -f deploy/deploy.sh ]           || fail "deploy/deploy.sh is missing"

echo "Validation passed"
