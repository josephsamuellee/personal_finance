# Deployment

The application is a single Rails process on serverlite. Local users open `http://serverlite:8090`. Remote users open the Cloudflare Tunnel hostname over HTTPS. Cloudflare Access is an additional gate in front of the tunnel. The Rails session is still required after Access.

## Process

- Bind: `0.0.0.0:8090` (`PORT` and `BIND` override it)
- Allowed hosts: `localhost`, `127.0.0.1`, `serverlite`, and `TUNNEL_HOST`
- `force_ssl` is off so the local HTTP site can keep a session
- The session cookie is `Secure` only when the request is HTTPS
- cloudflared on the same machine is a trusted local proxy, so `X-Forwarded-Proto: https` marks tunneled requests as HTTPS
- Persistent paths: `DATABASE_PATH` (default `storage/production.sqlite3`) and the Active Storage disk root `storage/`

## Market data

Price refresh uses Alpha Vantage. Set `ALPHAVANTAGE_API_KEY` outside the repository. A failed refresh keeps cached prices. Manual prices use source `manual` and do not need the key.

## Backups

SQLite runs in WAL mode. Copying the database file by hand can miss the WAL, so backups use the SQLite backup API and copy receipt files with it.

```sh
BACKUP_ROOT=/var/lib/personal-finance/backups BACKUP_RETENTION=30 bin/rails household:backup
BACKUP_DIR=/var/lib/personal-finance/backups/backup-YYYYMMDDHHMMSS bin/rails household:restore
```

Schedule `household:backup` once a day. Retention defaults to 30 backups.

## Restore drill

Run this against a spare copy before treating a new install as accepted:

1. Create an expense and attach a receipt.
2. Run `bin/rails household:backup`.
3. Restore that backup onto a spare data directory.
4. Confirm the expense and the receipt file are both present.
5. Sign in through `http://serverlite:8090` and through the tunnel hostname.
