import { cache, sql } from "./db";

export type SessionContext = { userId: string; isAdmin: boolean };

const loginRateState = new Map<string, { count: number; resetAt: number }>();
const MAX_LOGIN_PER_WINDOW = 12;
const LOGIN_WINDOW_MS = 15 * 60 * 1000;

/**
 * CORS `Origin` is exact: scheme+host+port, no path. Browsers never send a trailing "/".
 * Strip quotes (some env files keep them) and trailing slashes.
 */
export function normalizeCorsOriginEntry(entry: string): string {
  let s = entry.trim();
  if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
    s = s.slice(1, -1).trim();
  }
  s = s.replace(/\/+$/, "");
  return s;
}

export function getCorsOriginsFromEnv(): Set<string> {
  const raw = process.env.CORS_ORIGINS?.trim() ?? "";
  if (raw) {
    return new Set(
      raw
        .split(",")
        .map((s) => normalizeCorsOriginEntry(s))
        .filter(Boolean)
    );
  }
  // Dev-friendly default: local web UI. Production must set CORS_ORIGINS explicitly.
  if (process.env.NODE_ENV === "production") {
    return new Set();
  }
  return new Set(["http://localhost:3000", "http://127.0.0.1:3000"]);
}

/**
 * Value for @elysiajs/cors `origin`.
 * Browsers send `Origin: <what you type in the address bar for the web app>` — that string must
 * be listed in CORS_ORIGINS (scheme + host + port, no path). Example: http://45.83.105.35:3000
 */
export function buildCorsOriginOption(): true | false | string[] {
  if (process.env.CORS_ALLOW_ALL === "1" || process.env.CORS_ALLOW_ALL === "true") {
    return true;
  }
  const fromEnv = Array.from(getCorsOriginsFromEnv());
  if (fromEnv.length > 0) {
    return fromEnv;
  }
  if (process.env.NODE_ENV === "production") {
    return false;
  }
  return ["http://localhost:3000", "http://127.0.0.1:3000"];
}

function clientKey(request: Request): string {
  const xff = request.headers.get("x-forwarded-for");
  if (xff) return xff.split(",")[0]?.trim() || "forwarded";
  return "direct";
}

export function recordLoginFailure(request: Request): { blocked: true } | { blocked: false } {
  const key = clientKey(request);
  const now = Date.now();
  const prev = loginRateState.get(key);
  if (!prev || now > prev.resetAt) {
    loginRateState.set(key, { count: 1, resetAt: now + LOGIN_WINDOW_MS });
    return { blocked: false };
  }
  prev.count += 1;
  if (prev.count > MAX_LOGIN_PER_WINDOW) {
    return { blocked: true };
  }
  return { blocked: false };
}

export function resetLoginAttempts(request: Request): void {
  const key = clientKey(request);
  loginRateState.delete(key);
}

export function readBearerSession(request: Request): string | null {
  const auth = request.headers.get("authorization");
  if (auth) {
    const m = /^Bearer\s+(\S+)$/i.exec(auth);
    if (m) return m[1] ?? null;
  }
  const alt = request.headers.get("x-session-id");
  return alt?.trim() || null;
}

export function readQuerySession(
  query: Record<string, string | undefined> | undefined
): string | null {
  const q = query?.session;
  if (q && String(q).trim()) return String(q);
  return null;
}

export function readQueryShare(
  query: Record<string, string | undefined> | undefined
): string | null {
  const s = query?.share;
  if (s && String(s).trim()) return String(s);
  return null;
}

export function sessionIdFromRequestOrQuery(
  request: Request,
  query: Record<string, string | undefined> | undefined
): string | null {
  return readBearerSession(request) ?? readQuerySession(query);
}

export async function resolveSession(sessionId: string | null | undefined): Promise<SessionContext | null> {
  if (!sessionId) return null;
  const cached = await cache.get(`session:${sessionId}`).catch(() => null);
  if (cached) {
    try {
      const parsed = JSON.parse(cached) as { userId: string; isAdmin: boolean };
      if (parsed.userId) return { userId: parsed.userId, isAdmin: Boolean(parsed.isAdmin) };
    } catch {
      // fall through
    }
  }
  const rows = await sql`
    SELECT s.user_id, u.is_admin
    FROM sessions s
    JOIN users u ON u.id = s.user_id
    WHERE s.id = ${sessionId}
    LIMIT 1
  `;
  const row = rows[0] as { user_id: string; is_admin: boolean } | undefined;
  if (!row) return null;
  const ctx: SessionContext = { userId: row.user_id, isAdmin: Boolean(row.is_admin) };
  await cache
    .set(
      `session:${sessionId}`,
      JSON.stringify({ userId: ctx.userId, isAdmin: ctx.isAdmin }),
      "EX",
      60 * 60 * 24 * 7
    )
    .catch(() => {});
  return ctx;
}

export async function requireSession(request: Request): Promise<SessionContext | Response> {
  const id = readBearerSession(request);
  if (!id) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" }
    });
  }
  const s = await resolveSession(id);
  if (!s) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" }
    });
  }
  return s;
}

export function requireUserId(session: SessionContext, userId: string): true | Response {
  if (session.userId !== userId) {
    return new Response(JSON.stringify({ error: "forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" }
    });
  }
  return true;
}

export function requireAdmin(session: SessionContext): true | Response {
  if (!session.isAdmin) {
    return new Response(JSON.stringify({ error: "forbidden" }), {
      status: 403,
      headers: { "Content-Type": "application/json" }
    });
  }
  return true;
}

export async function getTrackForAuth(
  trackId: string
): Promise<{ id: string; user_id: string } | null> {
  const rows = await sql`SELECT id, user_id FROM tracks WHERE id = ${trackId} LIMIT 1`;
  const r = rows[0] as { id: string; user_id: string } | undefined;
  return r ?? null;
}

export async function assertShareForTrack(share: string, trackId: string): Promise<boolean> {
  const rows = await sql`SELECT 1 as ok FROM shared_tracks WHERE token = ${share} AND track_id = ${trackId} LIMIT 1`;
  return Boolean((rows[0] as { ok: number } | undefined)?.ok);
}

export type MediaAccess = "ok" | "unauthorized" | "forbidden";

export async function resolveMediaAccess(
  trackId: string,
  request: Request,
  query: Record<string, string | undefined> | undefined
): Promise<MediaAccess> {
  const share = readQueryShare(query);
  const sessionId = sessionIdFromRequestOrQuery(request, query);
  const track = await getTrackForAuth(trackId);
  if (!track) return "forbidden";

  if (sessionId) {
    const ctx = await resolveSession(sessionId);
    if (!ctx) return "unauthorized";
    if (ctx.userId === track.user_id) return "ok";
  }

  if (share) {
    const ok = await assertShareForTrack(share, trackId);
    return ok ? "ok" : "forbidden";
  }

  return "unauthorized";
}
