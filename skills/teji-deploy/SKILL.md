---
name: teji-deploy
description: Deploy, configure, validate, and troubleshoot the Teji Android client and read-only FastAPI bridge with an existing TeslaMate installation on a NAS or Linux server. Use for Docker/PostgreSQL setup, read-only database access, API health checks, LAN/VPN access, 内网穿透 decisions, AMap Android keys, APK builds, upgrades, and privacy-safe diagnostics. Never expose Teji API or PostgreSQL directly to the public internet.
---

# Deploy Teji

Deploy Teji without weakening the security of the user's TeslaMate data.

## Safety boundaries

- Treat coordinates, addresses, vehicle names, database credentials, API URLs, logs, and screenshots as sensitive.
- Inspect before changing. Never print `.env`, `key.properties`, signing files, tokens, or raw vehicle responses.
- Limit mutations to Teji unless the user explicitly authorizes a TeslaMate or PostgreSQL change.
- Never restart, rebuild, upgrade, or reconfigure TeslaMate/database containers as an incidental deployment step.
- Never expose PostgreSQL `5432` or unauthenticated Teji API `8889` directly to the internet.
- Prefer LAN or an authenticated mesh VPN. A public tunnel is not safe merely because it uses HTTPS or a hard-to-guess URL.
- Use a dedicated PostgreSQL read-only role when possible.
- Preserve the required unofficial-project disclaimer and do not present Teji as an official Tesla/TeslaMate product.

## Workflow

1. Locate the Teji checkout and read its root `README.md`, `SECURITY.md`, `api/.env.example`, and `api/docker-compose.yml`.
2. Run `scripts/preflight.sh <repo-path>` for read-only environment checks.
3. Discover the actual TeslaMate container names and Docker network. Do not assume the examples match every Compose project.
4. Choose the access model:
   - Same Wi-Fi: use the NAS LAN address.
   - Remote use without a public IP: prefer WireGuard, Tailscale, ZeroTier, or another authenticated private network.
   - Public endpoint: stop unless an authentication layer compatible with the client is present. TLS alone is insufficient.
5. Configure `api/.env` without displaying its values. Attach `teji-api` to the TeslaMate network and start/rebuild only that service.
6. Validate `/health`, then inspect only response shapes/field names from data endpoints unless the user explicitly requests actual values.
7. Configure the Android client with the user's API address and AMap key. Keep `key.properties` and signing files ignored.
8. Run the proportionate checks: format, analyze, test, and build.
9. Report what changed, how access is protected, what was verified, and any remaining manual step.

Read [references/deployment.md](references/deployment.md) for first-time setup and access patterns. Read [references/troubleshooting.md](references/troubleshooting.md) only when diagnosing a failure.

## Mutating operations

Deployment authorizes creation/update of the Teji API service and its own configuration. Request confirmation before:

- changing TeslaMate Compose files;
- creating or altering a database role when the user did not ask for it;
- changing router/firewall/public DNS state;
- replacing an existing Android signing identity;
- restarting or rebuilding non-Teji containers.

Prefer `docker compose up -d --build teji-api` scoped to the Teji Compose project. Verify resolved targets before running it.

## Validation commands

Use commands appropriate to the discovered environment:

```bash
curl -fsS --connect-timeout 5 --max-time 15 http://127.0.0.1:8889/health
```

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Do not use `/api/overview` or route endpoints as generic connectivity probes when `/health` is sufficient.
