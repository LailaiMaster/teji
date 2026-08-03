# Teji deployment reference

## Architecture

```text
TeslaMate -> PostgreSQL <- Teji API <- private network -> Teji Android
```

Teji does not authenticate to Tesla or control the vehicle. The FastAPI service issues read-only SQL queries against the user's TeslaMate database.

## Required files

- `api/.env.example`: supported database and CORS variables.
- `api/docker-compose.yml`: `teji-api` service and external TeslaMate network.
- `app/android/key.properties`: local AMap/signing configuration; never commit it.
- `app/lib/src/config.dart`: optional `TEJI_API_BASE_URL` build-time default.

## Discovery

Check rather than assume:

```bash
docker ps --format '{{.Names}}\t{{.Status}}'
docker network ls --format '{{.Name}}'
docker compose -f api/docker-compose.yml config
```

Do not print container environments or inspect secret values. If Docker requires `sudo`, follow the host owner's established access method.

## API environment

Copy `api/.env.example` to `api/.env` and set:

- `TESLAMATE_DB_HOST`
- `TESLAMATE_DB_PORT`
- `TESLAMATE_DB_NAME`
- `TESLAMATE_DB_USER`
- `TESLAMATE_DB_PASSWORD`
- `TESLAMATE_DB_SSLMODE`
- `CORS_ALLOW_ORIGINS`

Confirm that the Compose external network matches the TeslaMate deployment. Container DNS names work only when both services share a Docker network.

## Read-only PostgreSQL role

Offer this only when the user can safely administer PostgreSQL:

```sql
CREATE USER teji_reader WITH PASSWORD 'replace-with-a-strong-password';
GRANT CONNECT ON DATABASE teslamate TO teji_reader;
GRANT USAGE ON SCHEMA public TO teji_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO teji_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO teji_reader;
```

Never place the real password in shell history, chat output, source control, or screenshots.

## Access models

### Same LAN

Use the NAS LAN address. Check host firewall rules and ensure only trusted local networks can reach the API.

### Remote private access

Prefer an authenticated mesh/private network. Install its client on both NAS/server and phone, authorize only the user's devices, and point Teji at the NAS virtual address. This avoids a public HTTP endpoint.

### Public IP or tunnel

Do not map raw `8889` or `5432`. A reverse proxy with HTTPS encrypts traffic but does not authenticate the caller. Because the current Teji client/API has no built-in token flow, recommend a private network until compatible authentication is implemented.

## Android configuration

The default package is `com.lailaima.teji`. An AMap Android key must match both the package and the signing-certificate SHA-1.

```properties
amapApiKey=your-amap-key
```

Run without a baked-in API URL and configure it in the app, or build with:

```bash
flutter run --dart-define=TEJI_API_BASE_URL=http://private-address:8889
```

Use HTTPS for any traffic leaving a trusted private network.

## Verification

Validate in this order:

1. API container is running.
2. `/health` succeeds locally on the server.
3. `/health` succeeds from the phone's network path.
4. App loads vehicle overview.
5. A known drive renders a route after the AMap key is configured.

Avoid showing raw vehicle data while reporting results.
