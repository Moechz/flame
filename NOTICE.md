# Notices — Flame for TerraMaster TOS (`flamedocker`)

This repository contains **packaging only**. No upstream source code is
redistributed here: the application is delivered as the official Docker Hub
image, unmodified, together with a four-file TOS application archive
(`config.ini`, `flamedocker.lang`, `flamedocker.svg`, `docker-compose.yml`).

## 1. Upstream project

| | |
|---|---|
| Project | Flame — self-hosted start page and dashboard |
| Homepage | <https://github.com/pawelmalak/flame> |
| Author | Paweł Malak (`pawelmalak`) |
| License | **MIT** — Copyright (c) 2021 Paweł Malak |
| Version used | **2.4.0** (the latest upstream release, published 24 April 2026) |

The upstream MIT license text is available at
<https://github.com/pawelmalak/flame/blob/master/LICENSE.md>. It permits use,
modification and redistribution provided the copyright notice and permission
notice are retained; they remain in the upstream image and in this notice.

## 2. Container image

| | |
|---|---|
| Image | `pawelmalak/flame:multiarch2.4.0` (Docker Hub, official upstream image) |
| Manifest list | `sha256:1b54ea03eb880baa2b54b1e9886ce0a36e15f67e2cd24f062e4bfa8db371726d` |
| Platforms | `linux/amd64`, `linux/arm64`, `linux/arm/v7` |
| amd64 manifest | `sha256:8da1ba1901cdbb8a67bea6e395922328da6cf6240708852d48dcb9c4b149da46` |
| arm64 manifest | `sha256:1f167a21793a8ae19310b180721a8aa0bacfb2a50ba3fe4aca3a6299104f3b18` |
| arm/v7 manifest | `sha256:93da98a9fa7a65238945bdfbb0ce1a75ae644fbf65326fe64573c2b47359de29` |
| Base | Node.js 20.20.2 on Alpine Linux |
| Built | 24 April 2026 (upstream rebuild of the 2.4.0 source) |

The **plain `2.4.0` tag is an amd64-only manifest**. It cannot run on an aarch64
NAS (Docker fails with `exec format error`, which the App Center reports as a
failed installation). This package therefore uses the upstream
`multiarch2.4.0` tag for both architectures it ships, and never re-tags or
re-builds the image itself.

The image is referenced by tag. Upstream has rebuilt the `2.4.0` tag in the past,
so this repository records the exact manifest digests above; they can be
verified with

```bash
docker manifest inspect pawelmalak/flame:multiarch2.4.0
```

## 3. Trademarks and affiliation

- “Flame” and the Flame logo belong to the upstream project and its author.
- “TerraMaster”, “TOS” and “App Center” are trademarks of TerraMaster.
- Docker and Docker Hub are trademarks of Docker, Inc.

This is an **independent community submission** by Moechz. It is not produced,
endorsed or supported by the Flame upstream project, Paweł Malak or TerraMaster.

## 4. Third-party components inside the image

The container image bundles the upstream Node.js application and its
dependencies, including `axios 0.24.0`, `jsonwebtoken 8.5.1`, `multer 1.4.3`,
`sequelize 6.9.0`, `sqlite3 6.0.1`, `express 4.18.2` and `ws 8.13.0`. Those
libraries remain under their own licenses (mostly MIT) as declared by the
upstream project.

### Known vulnerabilities (T1)

Several of those bundled versions carry published CVE identifiers, for example
in `axios` 0.24.0 (XSRF token leakage, ReDoS), `jsonwebtoken` 8.5.1 (verification
bypass / RCE with an attacker-controlled key) and `multer` 1.4.3
(denial-of-service in multipart parsing). They are **inside the upstream image**:
this package cannot patch them without rebuilding and redistributing the
upstream application, which would stop being “the official image, used
unmodified”.

Mitigations that do apply and are part of this package:

- The container runs as uid 1000 with `cap_drop: [ALL]` and
  `no-new-privileges:true`; there is no shell exposed on the network and no
  Docker socket mounted.
- Flame has no public query endpoint that reaches those libraries before login:
  write operations require the administrator token and the JWT secret is
  generated per installation.
- The administrator password is random per installation, so the
  `jsonwebtoken` bypass cannot be reached with a known default secret or
  password.
- Keep the app on the LAN, behind a TLS reverse proxy if it must be reachable
  from outside.

Follow-up plan: the upstream project is watched for a new release or a security
rebuild; as soon as `pawelmalak/flame` publishes one, this package is rebuilt
against it and re-submitted. The check is repeated with every App Center review
cycle and recorded in `CHANGELOG.md`.

## 5. This packaging

Copyright (c) 2026 Moechz. The packaging files (the four-file archive, the build
scripts and the documentation in this repository) are released under the **MIT
license**, see `LICENSE`.

## 6. Privacy

The privacy policy for this application — what is stored, what leaves the NAS
and to which third-party endpoints — is in `PRIVACY.md`.
