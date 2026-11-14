# flame-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Flame](https://github.com/pawelmalak/flame).

## What this is

A four-file TOS Docker application archive (`flamedocker.tar.gz`) that installs
Flame on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `flamedocker`)
- `flamedocker.lang` — 23-language superset (TOS requires 14)
- `flamedocker.svg` — application icon (274 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `pawelmalak/flame:2.4.0`

## How it works

| | |
|---|---|
| Container image | `pawelmalak/flame:2.4.0` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8027/` (container port 5005) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/app/data` → `/Volume1/DockerAppData/flamedocker/data` |
| Logs | `docker logs flamedocker` (stdout/stderr) |

`/app/data` (mounted from `DockerAppData/flamedocker/data`) holds `config.yml`, `db.sqlite` and the `.secret` file Flame generates on first start.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper**: the app rewrites files inside `/app/public` on start, impossible for uid 1000; the wrapper runs it from a `/tmp` copy and keeps `/app/data` as the volume.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 5005.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Writable copy in /tmp.** Flame regenerates CSS inside its app directory; the wrapper copies the app to `/tmp/flame` and symlinks `data` back to the volume.
- **SQLite only.** Links and settings live in a small SQLite database plus YAML files.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `/Volume1/DockerAppData/flamedocker/data` | Flame application data (everything the container writes outside /tmp) | on first start / on demand | bounded by your own data | persistent; kept on uninstall unless you ask to delete it |

## Build

```bash
scripts/build.sh                  # -> out/flamedocker.tar.gz + .sha256
scripts/build.sh 2.4.0-2   # packaging iteration bump
scripts/build.sh 2.4.0-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/flamedocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v2.4.0-1`**, assets `flamedocker.tar.gz` +
   `flamedocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `flamedocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `2.4.0-1` → automated validation → review.

## License / branding

Flame is distributed by its upstream authors under **MIT**. The container image is the official image from Docker Hub (`pawelmalak/flame:2.4.0`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

- The layout is edited as YAML files in the data folder; there is no admin UI for it.
- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the internet.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
