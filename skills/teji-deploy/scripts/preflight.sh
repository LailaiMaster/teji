#!/usr/bin/env bash
set -uo pipefail

repo_path="${1:-.}"

if [[ ! -d "$repo_path" ]]; then
  echo "ERROR repo path does not exist"
  exit 2
fi

repo_path="$(cd "$repo_path" && pwd -P)"
errors=0
warnings=0

ok() { printf 'OK    %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
fail() { printf 'ERROR %s\n' "$1"; errors=$((errors + 1)); }

echo "Teji deployment preflight"

for required_file in README.md SECURITY.md api/.env.example api/docker-compose.yml app/pubspec.yaml; do
  if [[ -f "$repo_path/$required_file" ]]; then
    ok "$required_file present"
  else
    fail "$required_file missing"
  fi
done

for command_name in git curl docker flutter dart; do
  if command -v "$command_name" >/dev/null 2>&1; then
    ok "$command_name available"
  else
    warn "$command_name unavailable"
  fi
done

if command -v docker >/dev/null 2>&1; then
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose available"
  else
    warn "Docker Compose unavailable or inaccessible"
  fi

  if docker info >/dev/null 2>&1; then
    ok "Docker daemon accessible"
  else
    warn "Docker daemon unavailable or requires established host privileges"
  fi

  if docker network inspect teslamate_default --format '{{.Name}}' >/dev/null 2>&1; then
    ok "example TeslaMate network exists"
  else
    warn "teslamate_default not found; discover the actual TeslaMate network"
  fi
fi

if [[ -f "$repo_path/api/.env" ]]; then
  ok "api/.env exists (values not inspected)"
else
  warn "api/.env missing"
fi

if [[ -f "$repo_path/app/android/key.properties" ]]; then
  ok "Android key.properties exists (values not inspected)"
else
  warn "Android key.properties missing; routes need a matching AMap key"
fi

if command -v git >/dev/null 2>&1 && git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  tracked_sensitive="$(git -C "$repo_path" ls-files | grep -Ei '(^|/)(\.env|key\.properties)$|\.(jks|keystore|p12|pem)$|^artifacts/' || true)"
  if [[ -n "$tracked_sensitive" ]]; then
    fail "sensitive/generated filenames are tracked; inspect git ls-files"
  else
    ok "no sensitive/generated filenames tracked"
  fi

  if git -C "$repo_path" status --porcelain | grep -q .; then
    warn "working tree has changes"
  else
    ok "working tree clean"
  fi
fi

printf 'Summary: %d error(s), %d warning(s)\n' "$errors" "$warnings"

if (( errors > 0 )); then
  exit 1
fi
