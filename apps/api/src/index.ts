import { Elysia, t } from "elysia";
import { cors } from "@elysiajs/cors";
import { createHash } from "node:crypto";
import { mkdir, readdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { createPlaylist, reorderPlaylistItems } from "@music/core";
import { encryptJson } from "@music/crypto";
import { importFolderRecursive } from "@music/importer";
import { parseBuffer } from "music-metadata";
import {
  buildCorsOriginOption,
  readBearerSession,
  recordLoginFailure,
  requireSession,
  requireUserId,
  resetLoginAttempts,
  resolveMediaAccess,
  resolveSession
} from "./auth";
import { cache, initPersistence, sql } from "./db";

const sockets = new Set<{ send: (data: string) => void; close: () => void }>();
const wsPendingAuth = new Set<{ send: (data: string) => void; close: () => void }>();

const PRESET_EXTENSIONS = new Set([".milk", ".json", ".preset"]);
const EXCLUDED_PRESET_DIRS = new Set(["milk_textures", "milk"]);
const uploadRoot = process.env.UPLOAD_DIR ?? join(process.cwd(), "apps/api/uploads");
const visualPresetsRoot = process.env.VISUAL_PRESETS_DIR ?? join(process.cwd(), "visual");

async function collectPresetFiles(dir: string): Promise<string[]> {
  const entries = await readdir(dir, { withFileTypes: true });
  const files: string[] = [];
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (EXCLUDED_PRESET_DIRS.has(entry.name)) continue;
      files.push(...(await collectPresetFiles(full)));
      continue;
    }
    const lower = entry.name.toLowerCase();
    const ext = lower.includes(".") ? lower.slice(lower.lastIndexOf(".")) : "";
    if (entry.isFile() && PRESET_EXTENSIONS.has(ext)) files.push(full);
  }
  return files;
}

async function upsertTrackSearchDoc(trackId: string): Promise<void> {
  await sql`
    UPDATE tracks
    SET search_doc = to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(artist, '') || ' ' || coalesce(album, ''))
    WHERE id = ${trackId}
  `;
}

async function getTrackById(trackId: string): Promise<Record<string, unknown> | null> {
  const rows = await sql`SELECT * FROM tracks WHERE id = ${trackId} LIMIT 1`;
  return (rows[0] as Record<string, unknown> | undefined) ?? null;
}

function normalizeTrack(row: Record<string, unknown>) {
  return {
    ...row,
    is_favorite: Boolean(row.is_favorite)
  };
}

async function resolveStoredMediaPath(storedPath: string): Promise<string | null> {
  const primary = Bun.file(storedPath);
  if (await primary.exists()) return storedPath;

  const marker = "/uploads/";
  const markerIdx = storedPath.lastIndexOf(marker);
  if (markerIdx === -1) return null;

  const relative = storedPath.slice(markerIdx + marker.length);
  const fallbackPath = join(uploadRoot, relative);
  const fallback = Bun.file(fallbackPath);
  if (await fallback.exists()) return fallbackPath;
  return null;
}

await initPersistence();
await cache.connect().catch(() => {});

const corsMode = buildCorsOriginOption();
if (corsMode === false) {
  console.warn(
    "[musicrr:api] CORS is disabled (no CORS_ORIGINS in production). Browser logins from another origin will fail. Set CORS_ORIGINS to your web UI origin, e.g. http://45.83.105.35:3000 or use CORS_ALLOW_ALL=1 only for debugging."
  );
} else if (corsMode === true) {
  console.warn("[musicrr:api] CORS_ALLOW_ALL is on — not recommended for production.");
}

const app = new Elysia()
  .use(
    cors({
      origin: corsMode,
      methods: ["GET", "POST", "OPTIONS", "PUT", "DELETE"],
      allowedHeaders: ["Content-Type", "Authorization", "X-Session-Id", "Range"]
    })
  )
  .get("/", () => ({
    ok: true,
    service: "musicrr-api",
    hint: "Protected routes require Authorization: Bearer <sessionId>. See README (CORS, TLS, deployment)."
  }))
  .get("/health", () => ({ ok: true }))
  .get("/media/track/:trackId/stream", async ({ params, request, query }) => {
    const access = await resolveMediaAccess(params.trackId, request, query);
    if (access === "unauthorized") return new Response("unauthorized", { status: 401 });
    if (access === "forbidden") return new Response("forbidden", { status: 403 });

    const track = await getTrackById(params.trackId);
    if (!track?.file_path) return new Response("not found", { status: 404 });
    const resolvedPath = await resolveStoredMediaPath(String(track.file_path));
    if (!resolvedPath) return new Response("not found", { status: 404 });
    const file = Bun.file(resolvedPath);
    const range = request.headers.get("range");
    const size = file.size;
    const type = file.type || "audio/mpeg";

    if (range) {
      // Handle browser range variations according to RFC 7233.
      const firstRange = range.split(",")[0]?.trim() ?? "";
      const match = /^bytes=(\d*)-(\d*)$/.exec(firstRange);
      if (match) {
        const rawStart = match[1];
        const rawEnd = match[2];
        let start = 0;
        let end = size - 1;

        if (rawStart && rawEnd) {
          start = Number(rawStart);
          end = Number(rawEnd);
        } else if (rawStart && !rawEnd) {
          start = Number(rawStart);
          end = size - 1;
        } else if (!rawStart && rawEnd) {
          const suffixLen = Number(rawEnd);
          if (!Number.isFinite(suffixLen) || suffixLen <= 0) {
            return new Response("range not satisfiable", {
              status: 416,
              headers: {
                "Content-Range": `bytes */${size}`,
                "Accept-Ranges": "bytes"
              }
            });
          }
          start = Math.max(0, size - suffixLen);
          end = size - 1;
        }

        if (!Number.isFinite(start) || start < 0) start = 0;
        if (!Number.isFinite(end) || end < start) end = size - 1;
        if (start >= size) {
          return new Response("range not satisfiable", {
            status: 416,
            headers: {
              "Content-Range": `bytes */${size}`,
              "Accept-Ranges": "bytes"
            }
          });
        }
        if (end >= size) end = size - 1;
        const chunk = file.slice(start, end + 1);
        const chunkBuffer = await chunk.arrayBuffer();
        const chunkLength = end - start + 1;
        return new Response(chunkBuffer, {
          status: 206,
          headers: {
            "Content-Type": type,
            "Content-Range": `bytes ${start}-${end}/${size}`,
            "Content-Length": String(chunkLength),
            "Accept-Ranges": "bytes",
            "Cache-Control": "public, max-age=31536000, immutable"
          }
        });
      }
      // Unknown range format: fall back to full-body response instead of failing playback.
    }

    return new Response(file, {
      headers: {
        "Content-Type": type,
        "Content-Length": String(size),
        "Accept-Ranges": "bytes",
        "Cache-Control": "public, max-age=31536000, immutable"
      }
    });
  })
  .get("/media/track/:trackId/cover", async ({ params, request, query }) => {
    const access = await resolveMediaAccess(params.trackId, request, query);
    if (access === "unauthorized") return new Response("unauthorized", { status: 401 });
    if (access === "forbidden") return new Response("forbidden", { status: 403 });

    const track = await getTrackById(params.trackId);
    if (!track?.cover_path) return new Response("not found", { status: 404 });
    const resolvedPath = await resolveStoredMediaPath(String(track.cover_path));
    if (!resolvedPath) return new Response("not found", { status: 404 });
    const file = Bun.file(resolvedPath);
    return new Response(file);
  })
  .get("/visual/presets", async () => {
    const presets = await collectPresetFiles(visualPresetsRoot).catch(() => []);
    return presets
      .map((p) => p.replace(visualPresetsRoot + "/", "").replace(/\\/g, "/"))
      .sort((a, b) => a.localeCompare(b));
  })
  .get("/visual/preset", async ({ query }) => {
    const requested = String(query.name ?? "");
    const normalized = requested.replace(/\\/g, "/").replace(/^\/+/, "");
    if (!normalized || normalized.includes("..")) {
      return { error: "Invalid preset path" };
    }
    const filePath = join(visualPresetsRoot, normalized);
    const content = await readFile(filePath, "utf-8");
    return { name: normalized, content };
  })
  .post(
    "/auth/login",
    async ({ body, request }) => {
      const email = body.email.trim().toLowerCase();
      const password = body.password;
      if (!email || !password) return { error: "Missing credentials" };
      try {
        const users = await sql`SELECT id, password_hash, is_admin FROM users WHERE email = ${email} LIMIT 1`;
        const user = users[0] as { id: string; password_hash: string | null; is_admin: boolean } | undefined;
        if (!user?.password_hash) {
          if (recordLoginFailure(request).blocked) {
            return new Response(JSON.stringify({ error: "too many attempts" }), {
              status: 429,
              headers: { "Content-Type": "application/json" }
            });
          }
          return { error: "Invalid credentials" };
        }
        const valid = await Bun.password.verify(password, user.password_hash);
        if (!valid) {
          if (recordLoginFailure(request).blocked) {
            return new Response(JSON.stringify({ error: "too many attempts" }), {
              status: 429,
              headers: { "Content-Type": "application/json" }
            });
          }
          return { error: "Invalid credentials" };
        }
        resetLoginAttempts(request);
        const sessionId = crypto.randomUUID();
        const now = Date.now();
        await sql`INSERT INTO sessions (id, user_id, created_at) VALUES (${sessionId}, ${user.id}, ${now})`;
        await cache.set(`session:${sessionId}`, JSON.stringify({ userId: user.id, isAdmin: Boolean(user.is_admin) }), "EX", 60 * 60 * 24 * 7).catch(() => {});
        return { sessionId, userId: user.id, isAdmin: Boolean(user.is_admin) };
      } catch {
        return { error: "login failed" };
      }
    },
    { body: t.Object({ email: t.String(), password: t.String() }) }
  )
  .get("/auth/session/:sessionId", ({ params }) => {
    return cache.get(`session:${params.sessionId}`).then(async (cachedUserId) => {
      if (cachedUserId) {
        const parsed = JSON.parse(cachedUserId) as { userId: string; isAdmin: boolean };
        return { valid: true, sessionId: params.sessionId, userId: parsed.userId, isAdmin: parsed.isAdmin };
      }
      const sessions = await sql`
        SELECT s.id, s.user_id, u.is_admin
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.id = ${params.sessionId}
        LIMIT 1
      `;
      const session = sessions[0] as { id: string; user_id: string; is_admin: boolean } | undefined;
      if (!session) return { valid: false };
      await cache
        .set(`session:${params.sessionId}`, JSON.stringify({ userId: session.user_id, isAdmin: Boolean(session.is_admin) }), "EX", 60 * 60 * 24 * 7)
        .catch(() => {});
      return { valid: true, sessionId: session.id, userId: session.user_id, isAdmin: Boolean(session.is_admin) };
    });
  })
  .post(
    "/admin/users/create",
    async ({ body, request }) => {
      const sessionId = readBearerSession(request) ?? body.sessionId;
      if (!sessionId) {
        return new Response(JSON.stringify({ error: "unauthorized" }), {
          status: 401,
          headers: { "Content-Type": "application/json" }
        });
      }
      const sessions = await sql`
        SELECT s.user_id, u.is_admin
        FROM sessions s
        JOIN users u ON u.id = s.user_id
        WHERE s.id = ${sessionId}
        LIMIT 1
      `;
      const session = sessions[0] as { user_id: string; is_admin: boolean } | undefined;
      if (!session || !session.is_admin) return new Response("forbidden", { status: 403 });
      const email = body.email.trim().toLowerCase();
      const existing = await sql`SELECT id FROM users WHERE email = ${email} LIMIT 1`;
      if (existing[0]) return new Response("exists", { status: 409 });
      const passwordHash = await Bun.password.hash(body.password);
      const created = await sql`
        INSERT INTO users (id, email, password_hash, display_name, is_admin, created_at)
        VALUES (${crypto.randomUUID()}, ${email}, ${passwordHash}, ${body.displayName ?? null}, ${Boolean(body.isAdmin)}, ${Date.now()})
        RETURNING id, email, display_name, is_admin
      `;
      return created[0];
    },
    {
      body: t.Object({
        sessionId: t.String(),
        email: t.String(),
        password: t.String(),
        displayName: t.Optional(t.String()),
        isAdmin: t.Optional(t.Boolean())
      })
    }
  )
  .post("/auth/logout", async ({ request, body }) => {
    const sessionId = readBearerSession(request) ?? body.sessionId;
    if (!sessionId) {
      return new Response(JSON.stringify({ error: "unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" }
      });
    }
    await sql`DELETE FROM sessions WHERE id = ${sessionId}`;
    await cache.del(`session:${sessionId}`).catch(() => {});
    return { ok: true };
  }, { body: t.Object({ sessionId: t.String() }) })
  .post(
    "/secure/blob",
    async ({ body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const m = requireUserId(ctx, body.userId);
      if (m !== true) return m;
      const encrypted = await encryptJson(body.secret, body.payload);
      await sql`
        INSERT INTO encrypted_blobs (id, user_id, payload, created_at)
        VALUES (${crypto.randomUUID()}, ${body.userId}, ${JSON.stringify(encrypted)}, ${Date.now()})
      `;
      return { ok: true };
    },
    { body: t.Object({ userId: t.String(), secret: t.String(), payload: t.Any() }) }
  )
  .get("/library/tracks/:userId", async ({ request, params, query }) => {
    const ctx = await requireSession(request);
    if (ctx instanceof Response) return ctx;
    const m = requireUserId(ctx, params.userId);
    if (m !== true) return m;
    const limit = Number(query.limit ?? "200");
    const rows = await sql`
      SELECT t.*, EXISTS (
        SELECT 1 FROM favorites f WHERE f.user_id = ${params.userId} AND f.track_id = t.id
      ) AS is_favorite
      FROM tracks t
      WHERE t.user_id = ${params.userId}
      ORDER BY t.added_at DESC
      LIMIT ${limit}
    `;
    return rows.map((row) => normalizeTrack(row as Record<string, unknown>));
  })
  .get("/library/artists/:userId", async ({ request, params }) => {
    const ctx = await requireSession(request);
    if (ctx instanceof Response) return ctx;
    const m = requireUserId(ctx, params.userId);
    if (m !== true) return m;
    return sql`SELECT artist, COUNT(*)::int as count FROM tracks WHERE user_id = ${params.userId} GROUP BY artist ORDER BY artist ASC`;
  })
  .get("/library/albums/:userId", async ({ request, params }) => {
    const ctx = await requireSession(request);
    if (ctx instanceof Response) return ctx;
    const m = requireUserId(ctx, params.userId);
    if (m !== true) return m;
    return sql`SELECT album, artist, COUNT(*)::int as count FROM tracks WHERE user_id = ${params.userId} GROUP BY album, artist ORDER BY album ASC`;
  })
  .get("/library/search/:userId", async ({ request, params, query }) => {
    const ctx = await requireSession(request);
    if (ctx instanceof Response) return ctx;
    const m = requireUserId(ctx, params.userId);
    if (m !== true) return m;
    const term = String(query.q ?? "").trim();
    if (!term) return [];
    const rows = await sql`
      SELECT t.*, EXISTS (
        SELECT 1 FROM favorites f WHERE f.user_id = ${params.userId} AND f.track_id = t.id
      ) AS is_favorite
      FROM tracks t
      WHERE t.user_id = ${params.userId}
        AND t.search_doc @@ plainto_tsquery('simple', ${term})
      ORDER BY t.added_at DESC
      LIMIT 100
    `;
    return rows.map((row) => normalizeTrack(row as Record<string, unknown>));
  })
  .post(
    "/library/import",
    async ({ body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const m = requireUserId(ctx, body.userId);
      if (m !== true) return m;
      const tracks = await importFolderRecursive(body.directory, (progress: { processed: number; total: number; currentFile?: string }) => {
        const event = JSON.stringify({ type: "import.progress", userId: body.userId, ...progress });
        for (const ws of sockets) ws.send(event);
      });
      for (const track of tracks) {
        const id = crypto.randomUUID();
        const inserted = await sql`
          INSERT INTO tracks (id, user_id, artist, album, title, file_path, cover_path, lyrics, hash, duration_sec, added_at, metadata_json)
          VALUES (${id}, ${body.userId}, ${track.artist}, ${track.album ?? null}, ${track.title}, ${track.filePath}, ${null}, ${null},
            ${track.hash}, ${track.durationSec}, ${Date.now()}, ${sql.json({})})
          ON CONFLICT (hash) DO NOTHING
          RETURNING id
        `;
        if (inserted[0]) await upsertTrackSearchDoc(String(inserted[0].id));
      }
      const done = JSON.stringify({ type: "import.done", userId: body.userId, imported: tracks.length });
      for (const ws of sockets) ws.send(done);
      return { imported: tracks.length };
    },
    { body: t.Object({ userId: t.String(), directory: t.String() }) }
  )
  .post("/library/import-upload", async ({ request }) => {
    const ctx = await requireSession(request);
    if (ctx instanceof Response) return ctx;
    const form = await request.formData();
    const userId = String(form.get("userId") ?? "");
    if (!userId) return new Response("missing userId", { status: 400 });
    const m = requireUserId(ctx, userId);
    if (m !== true) return m;

    const uploadDir = join(uploadRoot, userId);
    const coverDir = join(uploadRoot, userId, "covers");
    await mkdir(uploadDir, { recursive: true });
    await mkdir(coverDir, { recursive: true });

    const files = form.getAll("files").filter((entry): entry is File => entry instanceof File);
    let imported = 0;
    for (const file of files) {
      const bytes = new Uint8Array(await file.arrayBuffer());
      const hash = createHash("sha256").update(bytes).digest("hex");
      const ext = file.name.includes(".") ? file.name.slice(file.name.lastIndexOf(".")) : ".bin";
      const storedPath = join(uploadDir, `${hash}${ext}`);
      await writeFile(storedPath, bytes);

      const metadata = await parseBuffer(Buffer.from(bytes), ext.replace(".", ""));
      let coverPath: string | null = null;
      const picture = metadata.common.picture?.[0];
      if (picture?.data) {
        const mime = picture.format.toLowerCase();
        const coverExt = mime.includes("png") ? ".png" : ".jpg";
        coverPath = join(coverDir, `${hash}${coverExt}`);
        await writeFile(coverPath, picture.data);
      }

      const lyricsText = Array.isArray(metadata.common.lyrics) && metadata.common.lyrics.length > 0
        ? metadata.common.lyrics.join("\n\n")
        : null;

      const id = crypto.randomUUID();
      const trackTitle = metadata.common.title ?? file.name.replace(/\.[^/.]+$/, "");
      const metadataPayload = {
        fileName: file.name,
        mimeType: file.type,
        size: bytes.length,
        albumArtist: metadata.common.albumartist ?? null,
        year: metadata.common.year ?? null
      };
      const inserted = await sql`
        INSERT INTO tracks (id, user_id, artist, album, title, file_path, cover_path, lyrics, hash, duration_sec, added_at, metadata_json)
        VALUES (${id}, ${userId}, ${metadata.common.artist ?? "Unknown Artist"}, ${metadata.common.album ?? null},
          ${trackTitle}, ${storedPath}, ${coverPath}, ${lyricsText}, ${hash},
          ${Math.floor(metadata.format.duration ?? 0)}, ${Date.now()}, ${sql.json(metadataPayload)})
        ON CONFLICT (hash) DO NOTHING
        RETURNING id
      `;
      if (inserted[0]) {
        imported += 1;
        await upsertTrackSearchDoc(String(inserted[0].id));
      }
    }

    return { imported };
  })
  .post(
    "/playlist/create",
    async ({ body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const m = requireUserId(ctx, body.userId);
      if (m !== true) return m;
      const playlist = createPlaylist(body.userId, body.name);
      await sql`
        INSERT INTO playlists (id, user_id, name, created_at, updated_at)
        VALUES (${playlist.id}, ${playlist.ownerUserId}, ${playlist.name}, ${playlist.createdAt}, ${playlist.updatedAt})
      `;
      const items = reorderPlaylistItems(body.trackIds, playlist.id);
      for (const item of items) {
        await sql`
          INSERT INTO playlist_items (playlist_id, track_id, item_order)
          VALUES (${item.playlistId}, ${item.trackId}, ${item.order})
        `;
      }
      return playlist;
    },
    { body: t.Object({ userId: t.String(), name: t.String(), trackIds: t.Array(t.String()) }) }
  )
  .post(
    "/playlist/delete",
    async ({ body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const m = requireUserId(ctx, body.userId);
      if (m !== true) return m;
      const result = await sql`DELETE FROM playlists WHERE id = ${body.playlistId} AND user_id = ${body.userId}`;
      return { deleted: result.count > 0 };
    },
    { body: t.Object({ userId: t.String(), playlistId: t.String() }) }
  )
  .post(
    "/library/track/update",
    async ({ body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const m = requireUserId(ctx, body.userId);
      if (m !== true) return m;
      const updated = await sql`
        UPDATE tracks SET title = ${body.title}
        WHERE id = ${body.trackId} AND user_id = ${body.userId}
        RETURNING id
      `;
      if (updated[0]) await upsertTrackSearchDoc(body.trackId);
      return { updated: Boolean(updated[0]) };
    },
    { body: t.Object({ userId: t.String(), trackId: t.String(), title: t.String() }) }
  )
  .post(
    "/library/track/delete",
    async ({ body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const m = requireUserId(ctx, body.userId);
      if (m !== true) return m;
      const result = await sql`DELETE FROM tracks WHERE id = ${body.trackId} AND user_id = ${body.userId}`;
      return { deleted: result.count > 0 };
    },
    { body: t.Object({ userId: t.String(), trackId: t.String() }) }
  )
  .post(
    "/playlists/:playlistId/add-track",
    async ({ params, body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const plRows = await sql`
        SELECT user_id FROM playlists WHERE id = ${params.playlistId} LIMIT 1
      `;
      const pl = plRows[0] as { user_id: string } | undefined;
      if (!pl || pl.user_id !== ctx.userId) {
        return new Response(JSON.stringify({ error: "forbidden" }), {
          status: 403,
          headers: { "Content-Type": "application/json" }
        });
      }
      const tRows = await sql`SELECT user_id FROM tracks WHERE id = ${body.trackId} LIMIT 1`;
      const tr = tRows[0] as { user_id: string } | undefined;
      if (!tr || tr.user_id !== ctx.userId) {
        return new Response(JSON.stringify({ error: "forbidden" }), {
          status: 403,
          headers: { "Content-Type": "application/json" }
        });
      }
      const maxOrderRows = await sql`
        SELECT COALESCE(MAX(item_order), -1)::int AS max_order
        FROM playlist_items
        WHERE playlist_id = ${params.playlistId}
      `;
      const nextOrder = Number((maxOrderRows[0] as { max_order: number }).max_order) + 1;
      await sql`
        INSERT INTO playlist_items (playlist_id, track_id, item_order)
        VALUES (${params.playlistId}, ${body.trackId}, ${nextOrder})
      `;
      return { ok: true };
    },
    { body: t.Object({ trackId: t.String() }) }
  )
  .post(
    "/library/track/favorite-toggle",
    async ({ body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const m = requireUserId(ctx, body.userId);
      if (m !== true) return m;
      const existing = await sql`
        SELECT 1 FROM favorites WHERE user_id = ${body.userId} AND track_id = ${body.trackId} LIMIT 1
      `;
      if (existing[0]) {
        await sql`DELETE FROM favorites WHERE user_id = ${body.userId} AND track_id = ${body.trackId}`;
        return { isFavorite: false };
      }
      await sql`
        INSERT INTO favorites (user_id, track_id, created_at)
        VALUES (${body.userId}, ${body.trackId}, ${Date.now()})
      `;
      return { isFavorite: true };
    },
    { body: t.Object({ userId: t.String(), trackId: t.String() }) }
  )
  .post(
    "/library/track/share",
    async ({ body, request }) => {
      const ctx = await requireSession(request);
      if (ctx instanceof Response) return ctx;
      const m = requireUserId(ctx, body.userId);
      if (m !== true) return m;
      const tRows = await sql`SELECT user_id FROM tracks WHERE id = ${body.trackId} LIMIT 1`;
      const tr = tRows[0] as { user_id: string } | undefined;
      if (!tr || tr.user_id !== body.userId) {
        return new Response(JSON.stringify({ error: "forbidden" }), {
          status: 403,
          headers: { "Content-Type": "application/json" }
        });
      }
      const token = crypto.randomUUID().replace(/-/g, "").slice(0, 16);
      const now = Date.now();
      await sql`
        INSERT INTO shared_tracks (token, track_id, created_by_user_id, created_at)
        VALUES (${token}, ${body.trackId}, ${body.userId}, ${now})
      `;
      await cache.set(`share:${token}`, body.trackId, "EX", 60 * 60 * 24 * 30).catch(() => {});
      return { token };
    },
    { body: t.Object({ userId: t.String(), trackId: t.String() }) }
  )
  .get("/share/:token", async ({ params }) => {
    let trackId = await cache.get(`share:${params.token}`).catch(() => null);
    if (!trackId) {
      const rows = await sql`SELECT track_id FROM shared_tracks WHERE token = ${params.token} LIMIT 1`;
      const entry = rows[0] as { track_id: string } | undefined;
      if (!entry) return new Response("not found", { status: 404 });
      trackId = entry.track_id;
      await cache.set(`share:${params.token}`, trackId, "EX", 60 * 60 * 24 * 30).catch(() => {});
    }
    const track = await getTrackById(trackId);
    if (!track) return new Response("not found", { status: 404 });
    return normalizeTrack(track);
  })
  .get("/users/:userId/playlists", async ({ request, params }) => {
    const ctx = await requireSession(request);
    if (ctx instanceof Response) return ctx;
    const m = requireUserId(ctx, params.userId);
    if (m !== true) return m;
    const rows = await sql`SELECT * FROM playlists WHERE user_id = ${params.userId} ORDER BY updated_at DESC`;
    return rows;
  })
  .get("/playlists/:playlistId/items", async ({ request, params }) => {
    const ctx = await requireSession(request);
    if (ctx instanceof Response) return ctx;
    const plRows = await sql`SELECT user_id FROM playlists WHERE id = ${params.playlistId} LIMIT 1`;
    const pl = plRows[0] as { user_id: string } | undefined;
    if (!pl || pl.user_id !== ctx.userId) {
      return new Response(JSON.stringify({ error: "forbidden" }), {
        status: 403,
        headers: { "Content-Type": "application/json" }
      });
    }
    const rows = await sql`
      SELECT t.*
      FROM playlist_items p
      JOIN tracks t ON p.track_id = t.id
      WHERE p.playlist_id = ${params.playlistId}
      ORDER BY p.item_order ASC
    `;
    return rows.map((row) => normalizeTrack(row as Record<string, unknown>));
  })
  .ws("/events", {
    open(ws) {
      wsPendingAuth.add(ws);
    },
    message(ws, message) {
      void (async () => {
        if (sockets.has(ws)) return;
        if (!wsPendingAuth.has(ws)) return;
        try {
          const raw = String(message);
          const body = JSON.parse(raw) as { type?: string; sessionId?: string; session?: string };
          const sid = body.sessionId ?? body.session;
          if (!sid) {
            ws.close();
            return;
          }
          const u = await resolveSession(sid);
          if (!u) {
            ws.close();
            return;
          }
          wsPendingAuth.delete(ws);
          sockets.add(ws);
          ws.send(JSON.stringify({ type: "connected", now: Date.now() }));
        } catch {
          ws.close();
        }
      })();
    },
    close(ws) {
      wsPendingAuth.delete(ws);
      sockets.delete(ws);
    }
  })
  .listen(Number(process.env.PORT ?? "3001"));

console.log(`API listening on ${app.server?.hostname}:${app.server?.port}`);
