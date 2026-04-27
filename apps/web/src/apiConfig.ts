const raw = (import.meta.env.VITE_API_ORIGIN as string | undefined)?.trim() ?? "";
const tauriRaw = (import.meta.env.VITE_TAURI_API_ORIGIN as string | undefined)?.trim() ?? "";
const API_PROXY_PREFIX = "/api";
const LOOPBACK_HOSTS = new Set(["localhost", "127.0.0.1", "::1"]);

function isTauriRuntime(): boolean {
  if (typeof window === "undefined") return false;
  const w = window as Window & { __TAURI__?: unknown };
  if (w.__TAURI__) return true;
  return navigator.userAgent.toLowerCase().includes("tauri");
}

function getConfiguredHttpBase(): string {
  const effectiveRaw = isTauriRuntime() && tauriRaw ? tauriRaw : raw;
  if (!effectiveRaw) return "";
  try {
    const configured = new URL(effectiveRaw);
    if (typeof window !== "undefined") {
      const pageHost = window.location.hostname.toLowerCase();
      const configuredHost = configured.hostname.toLowerCase();
      const pageIsLoopback = LOOPBACK_HOSTS.has(pageHost);
      const configuredIsLoopback = LOOPBACK_HOSTS.has(configuredHost);
      // Prevent accidental localhost API targets on public domains (blocked by browser extensions / mismatch).
      if (configuredIsLoopback && !pageIsLoopback) return "";
    }
    const basePath = configured.pathname.replace(/\/$/, "");
    return `${configured.origin}${basePath === "/" ? "" : basePath}`;
  } catch {
    return "";
  }
}

export function getApiHttpBase(): string {
  const configuredBase = getConfiguredHttpBase();
  if (configuredBase) {
    return configuredBase;
  }
  if (typeof window === "undefined") {
    return "http://musicrr-api:3001";
  }
  return API_PROXY_PREFIX;
}

export function getApiWsBase(): string {
  const configuredBase = getConfiguredHttpBase();
  if (configuredBase) {
    try {
      const u = new URL(configuredBase);
      u.protocol = u.protocol === "https:" ? "wss:" : "ws:";
      return u.origin;
    } catch {
      // fall through
    }
  }
  if (typeof window === "undefined") {
    return "ws://musicrr-api:3001";
  }
  return `${window.location.protocol === "https:" ? "wss" : "ws"}://${window.location.host}`;
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
