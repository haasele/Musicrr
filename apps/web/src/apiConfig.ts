const raw = (import.meta.env.VITE_API_ORIGIN as string | undefined)?.trim() ?? "";

export function getApiHttpBase(): string {
  if (raw) {
    return raw.replace(/\/$/, "");
  }
  if (typeof window === "undefined") {
    return "http://localhost:3001";
  }
  return `${window.location.protocol}//${window.location.hostname}:3001`;
}

export function getApiWsBase(): string {
  if (raw) {
    try {
      const u = new URL(raw);
      u.protocol = u.protocol === "https:" ? "wss:" : "ws:";
      return u.origin;
    } catch {
      // fall through
    }
  }
  if (typeof window === "undefined") {
    return "ws://localhost:3001";
  }
  return `${window.location.protocol === "https:" ? "wss" : "ws"}://${window.location.hostname}:3001`;
}

export function apiUrl(path: string): string {
  const base = getApiHttpBase();
  if (path.startsWith("http")) return path;
  return `${base}${path.startsWith("/") ? path : `/${path}`}`;
}

function mergeHeaders(
  h: RequestInit["headers"] | undefined,
  sessionId: string | null | undefined
): Headers {
  const headers = new Headers(h);
  if (sessionId) {
    if (!headers.has("Authorization")) {
      headers.set("Authorization", `Bearer ${sessionId}`);
    }
  }
  return headers;
}

export async function apiFetch(
  path: string,
  init: RequestInit & { sessionId?: string | null } = {}
): Promise<Response> {
  const { sessionId, ...rest } = init;
  return fetch(apiUrl(path), { ...rest, headers: mergeHeaders(init.headers, sessionId) });
}

/** Session (owner) and/or public share token for <audio> / <img> — API accepts ?session= and ?share=. */
export function mediaUrl(
  path: string,
  sessionId: string | null | undefined,
  shareToken: string | null | undefined
): string {
  if (!path.startsWith("/media/")) {
    return apiUrl(path);
  }
  const base = apiUrl(path);
  const p = new URLSearchParams();
  if (sessionId) p.set("session", sessionId);
  if (shareToken) p.set("share", shareToken);
  const s = p.toString();
  if (!s) return base;
  return base.includes("?") ? `${base}&${s}` : `${base}?${s}`;
}
