# Changelog

All notable user-visible changes to the Flame TOS application package.

## 2.4.0-3 — 2026-11-25

Remediation of the App Center review findings for `2.4.0-2` (aarch64),
codes C10 / C3 / C8 / T1 plus the blocking items F2 and S6 reported in the
review body.

### Fixed
- **F2 / D18 — service fails to start on aarch64 (install failed).** The image
  reference `pawelmalak/flame:2.4.0` is an **amd64-only** manifest, so an
  aarch64 NAS could not execute it (`exec format error`, which the App Center
  shows as “installation failed — cannot be opened”). Both architectures now use
  the upstream multi-architecture build `pawelmalak/flame:multiarch2.4.0`
  (manifest list for amd64, arm64 and arm/v7, digests in `NOTICE.md`).
- **S6 — hard-coded credentials.** The upstream image bakes
  `PASSWORD=flame_password` into its environment and the login controller
  compares against it. The compose file now overrides `PASSWORD` with an empty
  value, and `src/entrypoint.sh` generates a random 24-character administrator
  password on first start, stores it at
  `DockerAppData/flamedocker/data/admin-credentials.txt` (uid 1000, mode 600)
  and exports it before starting the server. The upstream default is never the
  effective credential.
- **C3 / C4 / C5 — privacy policy missing.** Added `PRIVACY.md` (stored data,
  retention, user rights, deletion channel, security measures, third-party
  disclosure), linked from `README.md`, and `help` in `config.ini` /
  `tosapp.json` now points at the public policy URL.
- **C8 — third-party API usage not disclosed.** `PRIVACY.md §6` lists every
  endpoint, the data sent and the destination: WeatherAPI.com (weather key and
  coordinates, server-side, plain HTTP), the optional user-configured Docker
  Engine API, the icon URLs fetched by the browser, the search providers and
  Docker Hub for the image pull. There is no update check and no telemetry.
- **C10 — repository/README compliance.** `README.md` now documents the
  repository layout, how it works, authentication, privacy, third-party
  services, notices, build steps and data/uninstall. Added `NOTICE.md`. The
  repository is public.
- **C9 — description/i18n.** Re-rendered `flamedocker.lang` for all 23
  languages from `tosapp.json`; `zh-cn` and `zh-hk` carry their own Flame texts
  again (no cross-app text). Removed every ASCII semicolon from the language
  values, which the store parser treated as an INI comment and truncated the
  release note at “search” (visible as a leading quote on the platform).
- **T1 — high/critical CVE.** Upstream `2.4.0` is the latest release (published
  2026-04-24) and the findings sit in the Node dependencies bundled inside the
  upstream image, so packaging cannot patch them without rebuilding that image.
  The image is retained, `NOTICE.md §4` documents the affected components
  (axios 0.24.0, jsonwebtoken 8.5.1, multer 1.4.3), the mitigations shipped in
  this package and the follow-up plan (rebuild as soon as upstream publishes a
  security release).
- **F11 — uninstall residue.** `README.md` documents that uninstalling keeps
  `DockerAppData/flamedocker` and how to delete it.

### Changed
- Weather is documented as **WeatherAPI.com** (the endpoint the upstream code
  actually calls), not OpenWeatherMap; the config location and the generated
  files (`config.json`, `db.sqlite`, `.secret`) are described as they are.
- Added `cap_drop: [ALL]` and `security_opt: no-new-privileges:true`.
- `tools/verify.py` now also fails the build on ASCII semicolons inside `.lang`
  values and on a non-empty `PASSWORD` in the compose file.

## 2.4.0-2 — 2026-11-15

### Changed
- Version-only resubmission of `2.4.0-1` (same package content, no functional
  change).

## 2.4.0-1 — 2026-11-14

### Added
- First release. Flame (`pawelmalak/flame:2.4.0`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8027 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/flamedocker/`.
