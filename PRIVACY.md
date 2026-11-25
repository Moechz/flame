# Privacy Policy — Flame for TerraMaster TOS (`flamedocker`)

**Last updated:** 25 November 2026
**Data controller / contact:** Moechz — moechz@163.com
**Applies to:** version `2.4.0-3` and later of the TOS application `flamedocker`,
the container image it runs and this repository.

## 1. Summary

- Flame runs **entirely on your NAS**. The developer does not receive, collect or
  have access to any of your data.
- There is **no telemetry, no analytics, no account** and no service operated by
  the developer.
- The container contacts only the endpoints listed in §6. Most of them are
  optional and only active when you configure the matching feature. The rest of
  the traffic is your browser talking to the pages you choose to open.

## 2. What data is processed and where it is stored

Everything Flame writes lives in the application data folder
`/Volume1/DockerAppData/flamedocker/data` on your NAS.

| Data | Stored at | Notes |
|---|---|---|
| Layout and settings: categories, apps, bookmarks, theme, optional WeatherAPI.com key, optional Docker host, coordinates used for weather | `…/data/config.json` | plain JSON, readable by uid 1000 only (mode 600 for generated files) |
| Links, bookmark metadata, cached weather readings | `…/data/db.sqlite` (SQLite) | created on first start |
| JWT signing key used for the browser session of the administrator | `…/data/.secret` | generated on first start, never leaves the NAS |
| Administrator password | `…/data/admin-credentials.txt` | generated randomly on first start, mode 600 |
| Uploaded icons and theme files | `…/data/uploads/`, `…/data/themes.json` | only if you upload custom icons or export themes |
| Database backups | `…/data/db_backups/` | created by the upstream application |
| Container logs | stdout/stderr only — `docker logs flamedocker` | no log file is written to the NAS |

No data is uploaded to the developer or to TerraMaster. Flame has no user
accounts, so there is no account data to collect beyond the administrator
password described above.

## 3. Retention period

- **Configuration, links, bookmarks, uploads and the password:** kept until
  **you** delete them. There is no automatic expiry and no upload.
- **Weather readings:** cached in the local database and refreshed while the
  weather widget is enabled; you can clear them by deleting the database or the
  data folder.
- **Logs:** stdout/stderr only. The Docker daemon keeps them according to its own
  rotation settings.
- **Uninstalling** the application from the App Center does **not** delete the
  data folder; see §4 for the deletion steps.

## 4. Your rights and the deletion channel

| Right | How |
|---|---|
| Access / export | Copy `/Volume1/DockerAppData/flamedocker/data/`; it contains the complete state. Individual entries can be exported from the app's own UI. |
| Correct | Edit links, bookmarks, categories, theme and settings in the Flame web UI, or edit `config.json` while the container is stopped. |
| Delete | Delete the folder `/Volume1/DockerAppData/flamedocker/` (stop the container first), or uninstall the app with the App Center's “delete data” option where available. |
| Rotate the administrator password | Delete `…/data/admin-credentials.txt` and restart the application; a new random password is generated. |
| Assistance | Email **moechz@163.com** with the subject “Flame data request”; a reply follows within 30 days. |

The developer holds no copy of your data, so deletion is normally completed by
removing the folder on your own NAS. The email channel exists for questions and
for requests concerning the published package.

## 5. Security measures

- The container runs as **uid 1000**, never root, with `cap_drop: [ALL]` and
  `no-new-privileges:true`.
- No `privileged` mode, no host network, and **no Docker socket** is mounted.
- Only the application port is published (host `8027` → container `5005`).
- The administrator password is **random per installation**, generated on first
  start by the package wrapper; the default password baked into the upstream
  image is overridden and never effective.
- Data stays inside the application data folder, owned by the application user.
- The upstream image is pinned to a fixed multi-architecture tag. When upstream
  ships a security rebuild, the package is re-published against it.
- The UI is plain HTTP. If you expose it outside the LAN, put it behind a TLS
  reverse proxy and keep the application updated.

## 6. Third-party sharing and API disclosure (C8)

The developer shares nothing and operates no server. The application and the
browser contact only the endpoints below.

| Service | Endpoint | Data sent | Destination / region | When |
|---|---|---|---|---|
| WeatherAPI.com | `http://api.weatherapi.com/v1/current.json?key=<key>&q=<lat>,<long>` | your WeatherAPI.com API key and the latitude/longitude you configured | WeatherAPI.com (US-based service) | only when the weather widget is enabled in `config.json` |
| Your Docker Engine (optional) | `http://<docker_host>/containers/json` | an ordinary API request; **no** NAS data, no credentials | the Docker host you enter in `config.json` (normally a host on your own LAN). The package does **not** mount `/var/run/docker.sock`, so the “localhost” default cannot reach a Docker daemon unless you configure a reachable host. | only when Docker integration is enabled |
| Icon URLs you configure | whatever URL you paste into an app's icon field (for example a link to `pictogrammers.com` / `materialdesignicons.com`, or any site's `favicon.ico`) | your browser's IP address and user agent, the requested image file | the site you chose | when the start page renders, fetched by **your browser**, not by the NAS |
| Search providers | `google.com`, `duckduckgo.com`, `search.disroot.org`, `en.wikipedia.org`, `youtube.com`, `open.spotify.com`, `listen.tidal.com`, `deezer.com`, `imdb.com`, `themoviedb.org`, `reddit.com` | the query you type, sent by **your browser** when you submit the search bar | the provider you selected in the settings | only when you use the search bar |
| Links on the start page | the URLs you added | your browser opens them normally | the site you chose | when you click a link |
| Image pull | `registry-1.docker.io` (Docker Hub) or your configured registry mirror | anonymous pull request | Docker Hub, US / your mirror | at installation and when the image is updated |

There is **no update check**, no telemetry and no developer-operated endpoint.
Flame does not send your start-page content, bookmarks, password or usage data
anywhere.

Notes on the two server-side endpoints:

- The weather request is made by the **container**, over plain HTTP (the upstream
  code uses `http://`), and therefore includes your API key and coordinates in
  clear text on the way to WeatherAPI.com. Leave the weather widget disabled if
  that is not acceptable, or route the request through a TLS-terminating proxy.
- The Docker integration only reads the container list and `flame.*` /
  Traefik labels; nothing is written to your Docker host.

## 7. What the developer does not do

- No account, newsletter, license check or activation.
- No crash reports, usage statistics or “phone home”.
- No advertising or tracking pixels inside the application.
- No sharing of data with TerraMaster beyond what the App Center itself does
  (downloading the package and the container image).

## 8. Changes to this policy

The policy is versioned with the application in this repository. A material
change is described in `CHANGELOG.md` and in the release notes of the version
that introduces it.

## 9. Contact

Moechz — **moechz@163.com**
Issues and questions: <https://github.com/Moechz/flame/issues>
