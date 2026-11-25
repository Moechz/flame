# flame-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [Flame](https://github.com/pawelmalak/flame), the self-hosted start page.

## What this is

A four-file TOS Docker application archive (`flamedocker.tar.gz`) that installs
Flame on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `flamedocker`)
- `flamedocker.lang` — 23-language superset (TOS requires 14)
- `flamedocker.svg` — application icon
- `docker-compose.yml` — one service, image `pawelmalak/flame:multiarch2.4.0`

The application runs **entirely on your NAS**. The developer receives no data;
see [PRIVACY.md](PRIVACY.md).

## Repository layout

```text
.
├── tosapp.json                 # packaging spec: image, ports, volumes, texts, translations
├── README.md                   # this file
├── PRIVACY.md                  # privacy policy / third-party endpoint disclosure
├── NOTICE.md                   # upstream license, image digests, CVE tracking
├── CHANGELOG.md                # per-version change log
├── LICENSE                     # MIT, packaging only
├── src/
│   ├── config.ini              # TOS application metadata
│   ├── docker-compose.yml      # the service definition (entrypoint embedded at build time)
│   ├── entrypoint.sh           # wrapper: writable /tmp copy + generated password
│   ├── flamedocker.lang        # 23-language UI texts
│   └── flamedocker.svg         # icon (512×512 viewBox)
├── scripts/
│   ├── build.sh                # stage → verify → package, one architecture
│   └── build-dual.sh           # x86_64 + aarch64, then the official check on both
├── tools/
│   └── verify.py               # review-standards self-check run by build.sh
└── test/
    └── install-and-verify.sh   # on-device end-to-end check (needs root, not run in CI)
```

The archive contains exactly the four files the App Center expects; everything
else stays in the repository.

## How it works

| | |
|---|---|
| Container image | `pawelmalak/flame:multiarch2.4.0` (Docker Hub, used unmodified) |
| Architectures | `linux/amd64`, `linux/arm64`, `linux/arm/v7` (upstream manifest list) |
| Open | `http://<NAS-IP>:8027/` (container port 5005) |
| Runs as | non-root, `user: "1000:1000"`, `cap_drop: [ALL]`, `no-new-privileges` |
| Persistent data | `/app/data` → `/Volume1/DockerAppData/flamedocker/data` |
| Logs | `docker logs flamedocker` (stdout/stderr) |
| Password | random, generated on first start, see below |

## Authentication

Flame protects every write operation with a password (`POST /api/auth/`, JWT
session). The upstream image ships a **default password in its environment**
(`PASSWORD=flame_password`), which would let anyone on the LAN edit your start
page.

This package removes that default from the effective configuration:

- `docker-compose.yml` sets `PASSWORD` to an empty string, so the baked-in
  default is not part of the container environment any more;
- `src/entrypoint.sh` generates a random 24-character password on the first
  start, stores it in the data folder and exports it before starting the server.

Read the password on the NAS:

```bash
cat /Volume1/DockerAppData/flamedocker/data/admin-credentials.txt
```

To rotate it, delete that file and restart the application.

## Privacy

The full policy is [PRIVACY.md](PRIVACY.md). In short:

- Flame runs entirely on your NAS. There is no telemetry, no analytics, no
  account and no developer-operated server.
- The only **server-side** outbound requests are the optional weather lookup
  (WeatherAPI.com, over plain HTTP) and the optional Docker Engine API call to a
  host **you** configure.
- Icons and search results are fetched by **your browser**, not by the NAS: the
  icon URL you paste is loaded by the browser, and the search bar hands your
  query to the provider you selected.
- The full endpoint → data → destination table is in
  [PRIVACY.md §6](PRIVACY.md#6-third-party-sharing-and-api-disclosure-c8).

## Third-party services

| Service | What is sent | When |
|---|---|---|
| WeatherAPI.com | API key + your coordinates, over plain HTTP | only if the weather widget is enabled |
| Your Docker Engine (optional) | container-list request to the host you configure | only if Docker integration is enabled |
| Icon sites you choose | browser request for the icon image | when the page renders |
| Search providers (Google, DuckDuckGo, Disroot, Wikipedia, YouTube, Spotify, Tidal, Deezer, IMDb, TMDb, Reddit) | your query, from the browser | when you use the search bar |
| Docker Hub | anonymous image pull | install / update |

There is **no update check** and no call to the package author or TerraMaster.

## Notices

[NOTICE.md](NOTICE.md) records the upstream MIT license (Copyright © 2021 Paweł
Malak), the exact image digests, the trademark attributions, the third-party
components and the CVE tracking / follow-up plan for the dependencies bundled in
the upstream image.

## Data and uninstall

Everything the application writes is inside its own data folder:

| Path | Purpose | Created when | Lifecycle |
|---|---|---|---|
| `/Volume1/DockerAppData/flamedocker/data` | Complete Flame state: `config.json`, `db.sqlite`, `.secret`, `themes.json`, `uploads/`, `db_backups/` | first start / on demand | persistent |
| `…/data/admin-credentials.txt` | generated administrator password (mode 600) | first start | persists across restarts; delete + restart to rotate |

Uninstalling the application from the App Center **keeps** the data folder.
To remove everything, stop the container and delete the folder:

```bash
# stop through the App Center, then:
rm -rf /Volume1/DockerAppData/flamedocker
```

There is no uninstall hook in a Docker package, so this manual step is the
documented way to remove all traces (F11).

## Design highlights

- **Multi-architecture.** Both packages pull the upstream manifest list, so an
  aarch64 NAS runs `linux/arm64` instead of failing with `exec format error`.
- **Non-root.** `user: "1000:1000"`, `cap_drop: [ALL]`,
  `no-new-privileges:true`; no `privileged`, no host network, no Docker socket.
- **Generated credential.** Random administrator password per installation.
- **Entrypoint wrapper.** Flame rewrites files inside `/app/public` on start,
  impossible for uid 1000; the wrapper runs the server from a `/tmp` copy and
  keeps `/app/data` as the volume.
- **Fixed image tag, never `:latest`**, Docker Hub only.
- **Health check** probing the service on container port 5005.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip
  without a timestamp, plus the review-standards self-check.

## Build

```bash
scripts/build.sh                  # one architecture (default: tosapp.json)
scripts/build.sh 2.4.0-3 x86_64   # explicit version + architecture
scripts/build-dual.sh 2.4.0-3     # both architectures + official check
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`),
removes CRLF/BOM/AppleDouble, then runs `tools/verify.py`, a review-standards
self-check (archive layout, JSON validity, required fields, 14+ language
coverage, version consistency, Docker-Hub-only images, fixed tag,
reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets, no ASCII semicolons in the `.lang` values and the SVG
size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/flamedocker_x86_64.tar.gz    # official spec check
./TOSAppSelfTestingTool -c out/flamedocker_aarch64.tar.gz
bash test/install-and-verify.sh                             # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (this one).
2. Release **tag `v2.4.0-3`**, assets `flamedocker_x86_64.tar.gz` /
   `flamedocker_aarch64.tar.gz` plus their `.sha256` files.
3. Developer platform → Application `flamedocker`, package type Docker,
   repository URL, both architectures.
4. Version Management → Add Version `2.4.0-3` per architecture → automated
   validation → review.

## License / branding

Flame is distributed by its upstream author under **MIT**. The container image
is the official multi-architecture image from Docker Hub
(`pawelmalak/flame:multiarch2.4.0`) and is used unmodified; no upstream source
code is redistributed here. This packaging is an independent community
submission by Moechz and is not affiliated with the upstream project or
TerraMaster. See [NOTICE.md](NOTICE.md).

## Limitations

- The layout is edited through the configuration files in the data folder; there
  is no admin UI for the overall layout.
- The UI is plain HTTP; use a TLS reverse proxy before exposing it to the
  internet.
- Upstream 2.4.0 is the latest release, so the CVEs in its bundled Node
  dependencies cannot be fixed by packaging alone; tracking and follow-up are in
  [NOTICE.md §4](NOTICE.md#4-third-party-components-inside-the-image).

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
