# Teji troubleshooting reference

## `/health` returns 503

- Confirm the database container is running without restarting it.
- Confirm `TESLAMATE_DB_HOST`, port, database, and user are set.
- Confirm `teji-api` and PostgreSQL share a Docker network.
- Test name resolution from the API container without printing environment values.
- Check whether the database role has `CONNECT`, schema `USAGE`, and table `SELECT`.

## API works on NAS but not on phone

- Confirm the phone uses a LAN/VPN address reachable from its current network.
- Check NAS firewall rules for the trusted subnet.
- Check VPN device authorization and routes.
- Do not solve the issue by opening `8889` to the entire internet.
- Android cleartext HTTP may be unsuitable outside a trusted LAN; prefer private routing or HTTPS.

## App opens the configuration screen repeatedly

- Test the exact configured base URL with `/health` from the phone's network.
- Remove trailing slashes and confirm the URL includes the expected scheme and port.
- Verify DNS/TLS certificates from the phone, not only from the server.

## Overview works but history is empty or slow

- The app loads overview first and fetches history asynchronously.
- Check `/api/drives?limit=1` and `/api/charging-processes?limit=1` using only status and field names.
- Confirm the TeslaMate schema version contains the columns expected by `api/app/main.py`.
- Review query duration before adding indexes or changing TeslaMate tables.

## Route map is blank

- Confirm the selected drive contains position samples.
- Confirm `app/android/key.properties` exists locally and its Key matches package `com.lailaima.teji`.
- Confirm the Key matches the Debug or Release signing SHA-1 actually used.
- Inspect Android logs for AMap authorization failures and redact the Key before sharing.

## Docker Compose cannot find the external network

- List Docker networks and identify the TeslaMate network created by its Compose project.
- Update only Teji's `networks` name unless the user explicitly wants TeslaMate changed.
- Do not create a disconnected network with the expected name merely to silence the error.

## Safe logs

Collect the smallest useful slice. Redact:

- passwords, tokens, cookies, and API keys;
- database URLs and container environments;
- coordinates, addresses, geofences, VINs, and vehicle names;
- private domains and public tunnel URLs.
