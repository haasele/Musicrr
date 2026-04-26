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
- `PUBLIC_BASE_URL`
- `ADMIN_EMAIL`, `ADMIN_PASSWORD`, `ADMIN_NAME`
- `POSTGRES_URL` und `DRAGONFLY_URL` werden im Compose-API-Service gesetzt

## Admin Login

Der initiale Admin-User wird beim API-Start aus den ENV-Variablen erzeugt (siehe `apps/api/src/db.ts`).

Standardwerte aus `.env.example`:

- Email: `admin@musicrr.local`
- Passwort: `admin123`
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
