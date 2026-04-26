# Hybrid Bun Music Platform

Ready-to-use Musikplattform mit Bun, Elysia, Tailwind, Login, Admin-Userverwaltung, Bulk-Import, Player, Playlists, Share-Links, Visualizer und E2EE-Grundlage.

## Features

- Login mit Email/Passwort
- Initialer Admin (per ENV), der weitere User ueber Admin-UI erstellen kann
- Persistente Session + Logout + Session-Pruefung
- E2EE-Bausteine mit Recovery-Envelope und verschluesselten Settings-Blobs
- Bulk-Import rekursiver Musikordner inkl. Subfolder + Hash-Dedup
- Bibliothek mit Tabs: Tracks, Artists, Albums, Playlists
- Player Queue mit Next/Shuffle/Repeat-Basis
- Song Actions per `...`: Playlist erstellen/hinzufuegen, Favorisieren, Teilen, Metadata anzeigen, Entfernen
- Anonyme Share-Links: ein Song oeffnet direkt im Vollbild-Player
- Dynamischer Live-Visualizer mit umschaltbaren Presets
- Responsive UI fuer Mobile/Tablet/Desktop

## Workspace Structure

- `apps/api`: Elysia API + Postgres Storage + Dragonfly Cache + WebSocket Events
- `apps/web`: React/Vite/Tailwind Frontend
- `apps/desktop`: Tauri Shell + native Folder Scan Command
- `packages/core`: Domain-Logik (Queue, Playlists, Typen)
- `packages/crypto`: E2EE Utilities (AES-GCM, PBKDF2, Recovery)
- `packages/importer`: Rekursiver Import + Metadata Parsing
- `packages/ui`: Reusable UI components + Loader

## Environment

Wichtige Variablen (siehe `.env.example`):

- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_PORT`
- `DRAGONFLY_PORT`
- `PUBLIC_BASE_URL` (öffentliche API-URL, z. B. für Links)
- `CORS_ORIGINS` – komma-separierte erlaubte Web-Origins für den Browser (z. B. `https://app.example.com`)
- `NODE_ENV` – in Produktion typischerweise `production` (CORS ohne explizite Origins ist dann streng)
- `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_NAME` – **vor dem ersten Deploy ändern**
- Optionales `VITE_API_ORIGIN` – feste API-Origin für die Web-App (wenn leer: gleicher Host wie die Seite, Port 3001)
- `POSTGRES_URL` und `DRAGONFLY_URL` werden im Compose-API-Service gesetzt

### Docker: Daten behalten (wichtig)

Die Datenbank und Uploads hängen an **Host-Ordnern** unter **`.data/`** (siehe `docker-compose.yml`):

- **Postgres:** `./.data/postgres` → komplette DB (User, Sessions in Redis sind separat unter `.data/dragonfly` und Uploads unter `.data/uploads`).

Wenn die Bibliothek nach jedem `docker compose up --build` **wieder leer** ist, liegt das fast immer daran, dass:

- der **Projektordner** jedes Mal neu ist (z. B. frischer CI-Clone ohne `.data`),

- jemand **`.data` gelöscht** hat, oder

- **kein** persistiertes Verzeichnis gemountet wird (API/Web nur per `docker run` **ohne** die Compose-Volumes).

`docker build` ersetzt nur Images; **Bind-Mounts** bleiben, solange der Host-Ordner bleibt. Backups: `.data/postgres` (und ggf. `.data/uploads`, `.data/dragonfly`) sichern oder ein benanntes Docker-Volume mit festem Host-Pfad nutzen.

## Security & Internet-Deployment

Die API erwartet für geschützte Routen eine Session (`Authorization: Bearer <sessionId>` oder für Medien optional `?session=` / Share-`?share=`). Öffentlich bleiben u. a. `GET /health`, `POST /auth/login`, `GET /auth/session/:id`, `GET /share/:token` und die Visualizer-Preset-Reads.

Für ein öffentliches Setup:

- **TLS** vor der API und dem Web (Reverse-Proxy / Load-Balancer).
- **`CORS_ORIGINS`** auf die exakte Origin deines Web-Frontends setzen (kein `*`). Muss exakt dem entsprechen, was im Browser in der **Adresszeile** steht, z. B. `http://DEINE_IP:3000` wenn die Web-UI auf Port 3000 läuft (nicht die API-URL auf :3001). Mehrere Einträge komma-separiert.
- **Admin- und DB-Passwörter** nicht auf Beispielwerte lassen.
- Optional: API und Web nur intern und nur der Proxy nach außen.

**„API nicht erreichbar“ / CORS im Browser:** Wenn die Web-Seite `http://IP:3000` ist und die API `http://IP:3001`, trägst du in der API-Env z. B. `CORS_ORIGINS=http://IP:3000` ein, API neu starten. Wenn `NODE_ENV=production` und `CORS_ORIGINS` leer ist, blockt die API Cross-Origin-Requests. Nur zum Debuggen: `CORS_ALLOW_ALL=1` (unsicher, nicht dauerhaft).

Häufige Stolperer: **kein** `/` am Ende einer Origin (nicht `https://foo/` – die API normalisiert das jetzt mit). `http://IP:3000` und `http://IP` (Port 80) sind unterschiedliche Origins. Die API-Subdomain (z. B. `api-…`) gehört in CORS in der Regel **nicht** rein, weil `Origin` die **Seite** ist, von der das JS läuft (z. B. `https://musicrr…`). Zum Gegenprüfen: in den API-Logs erscheint die erlaubte Liste beim Start. Mit `DEBUG_CORS=1` werden abgelehnte `Origin`-Header geloggt.

## Admin Login

Der initiale Admin-User wird beim API-Start aus den ENV-Variablen erzeugt (siehe `apps/api/src/db.ts`).

Beispielwerte aus `.env.example` (unbedingt überschreiben):

- Email: `admin@example.com`
- Passwort: `change-me-now-please`
- Name: `Musicrr Admin`

## Docker Compose (empfohlen)

```bash
cp .env.example .env
docker compose up -d
```

Persistente Root-Volumes:

- `./.data/postgres`
- `./.data/dragonfly`
- `./.data/uploads`

Container:

- Web: `http://localhost:3000`
- API: `http://localhost:3001`
- Postgres: `localhost:5432`
- Dragonfly (Redis-Protokoll): `localhost:6379`

Reset (alle persistierten Daten loeschen):

```bash
docker compose down
rm -rf .data/postgres .data/dragonfly .data/uploads
```

## Local Dev (ohne Compose)

```bash
bun install
bun run dev:api
bun run dev:web
```

API: `http://localhost:3001`  
Web: `http://localhost:3000`

## Build & Test

```bash
bun run build
bun run test
```
