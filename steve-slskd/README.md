# steve-slskd

[slskd](https://github.com/slskd/slskd) (Soulseek daemon + web UI) in Docker. Moving off Nicotine+.

## Layout

```
steve-slskd/
├── docker-compose.yml   # the service; paths come from .env
├── .env                 # host paths + PUID/PGID/TZ  (secret-ish, gitignored)
└── config/              # slskd's whole app dir, bind-mounted to /app in the container
    ├── slskd.yml        # your config (gitignored — has passwords)
    ├── data/            # STATE: favourited users, share cache, db  ← the precious bit
    └── logs/
```

## The volumes

| Host | Container | Mode | What |
|------|-----------|------|------|
| `$MUSIC_PATH` (default `/home/s/Music/71mix/`) | `/music` | **ro** | library you share (same mount as jamsend) |
| `$DOWNLOAD_PATH` (`…/steve/Soul`) | `/downloads` | rw | downloads + `.incomplete` |
| `./config` | `/app` | rw | config **and state** — plain host folder |

## First run

1. Edit **`config/slskd.yml`** — set your Soulseek `username`/`password` and a web-UI login (every `TODO-…`).
2. Check the paths in **`.env`** match this box.
3. `docker compose up -d`
4. Open **http://localhost:5030**, log in, confirm shares/downloads under System → Options.
5. Forward Soulseek's `listen_port` (50300) on your router so peers can connect to you.

Logs: `docker compose logs -f`  ·  Stop: `docker compose down`  ·  Update: `docker compose pull && docker compose up -d`

## Backup (the whole point)

Everything worth keeping — favourited users, settings, share cache — is in **`config/`** as ordinary
files. No docker volume to lose track of this time:

```sh
tar czf steve-slskd-config-$(date +%F).tgz -C /path/to/steve-slskd config
```

Restore = drop `config/` back next to `docker-compose.yml` and `up -d`.

## Note

Stubbed from inside the jamsend working tree because that was the only host-visible writable
spot available. **Move this folder out to your projects dir** and keep it out of jamsend's git.
`slskd.yml` and `.env` are gitignored because they hold credentials.
