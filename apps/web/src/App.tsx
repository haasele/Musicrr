import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { AppShell, NeonLoader } from "@music/ui";
import { PlayerQueue } from "@music/core";
import { apiFetch, apiUrl, getApiWsBase, mediaUrl } from "./apiConfig";
import { MilkEngine } from "./visualizer/MilkEngine";

type Track = {
  id: string;
  title: string;
  artist: string;
  album?: string;
  duration_sec: number;
  file_path: string;
  cover_path?: string | null;
  source?: "local" | "server";
  object_url?: string;
  lyrics?: string | null;
  is_favorite?: boolean;
  metadata_json?: Record<string, unknown> | null;
};

const queue = new PlayerQueue();

function IconButton({
  title,
  onClick,
  primary = false,
  children
}: {
  title: string;
  onClick: () => void;
  primary?: boolean;
  children: React.ReactNode;
}) {
  return (
    <button className={primary ? "player-btn-primary" : "player-btn"} onClick={onClick} title={title} aria-label={title}>
      {children}
    </button>
  );
}

function IconBase({ children }: { children: React.ReactNode }) {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      {children}
    </svg>
  );
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function rgbToHsl(r: number, g: number, b: number): { h: number; s: number; l: number } {
  const rr = r / 255;
  const gg = g / 255;
  const bb = b / 255;
  const max = Math.max(rr, gg, bb);
  const min = Math.min(rr, gg, bb);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case rr:
        h = (gg - bb) / d + (gg < bb ? 6 : 0);
        break;
      case gg:
        h = (bb - rr) / d + 2;
        break;
      default:
        h = (rr - gg) / d + 4;
    }
    h /= 6;
  }
  return { h: h * 360, s, l };
}

function hslToRgb(h: number, s: number, l: number): { r: number; g: number; b: number } {
  const hue = ((h % 360) + 360) % 360;
  const c = (1 - Math.abs(2 * l - 1)) * s;
  const x = c * (1 - Math.abs(((hue / 60) % 2) - 1));
  const m = l - c / 2;
  let rr = 0;
  let gg = 0;
  let bb = 0;

  if (hue < 60) {
    rr = c; gg = x; bb = 0;
  } else if (hue < 120) {
    rr = x; gg = c; bb = 0;
  } else if (hue < 180) {
    rr = 0; gg = c; bb = x;
  } else if (hue < 240) {
    rr = 0; gg = x; bb = c;
  } else if (hue < 300) {
    rr = x; gg = 0; bb = c;
  } else {
    rr = c; gg = 0; bb = x;
  }

  return {
    r: Math.round((rr + m) * 255),
    g: Math.round((gg + m) * 255),
    b: Math.round((bb + m) * 255)
  };
}

function colorFromHsl(h: number, s: number, l: number): string {
  const { r, g, b } = hslToRgb(h, s, l);
  return `rgb(${r}, ${g}, ${b})`;
}

function colorDistance(a: { r: number; g: number; b: number }, b: { r: number; g: number; b: number }): number {
  const dr = a.r - b.r;
  const dg = a.g - b.g;
  const db = a.b - b.b;
  return Math.sqrt(dr * dr + dg * dg + db * db);
}

function colorToRgbString(color: { r: number; g: number; b: number }): string {
  return `rgb(${Math.round(color.r)}, ${Math.round(color.g)}, ${Math.round(color.b)})`;
}

function adjustColorLightness(color: { r: number; g: number; b: number }, delta: number): { r: number; g: number; b: number } {
  const hsl = rgbToHsl(color.r, color.g, color.b);
  const next = hslToRgb(hsl.h, hsl.s, clamp(hsl.l + delta, 0.24, 0.78));
  return next;
}

export function App() {
  const [email, setEmail] = useState(localStorage.getItem("email") ?? "");
  const [password, setPassword] = useState("");
  const [sessionId, setSessionId] = useState(localStorage.getItem("sessionId") ?? "");
  const [userId, setUserId] = useState(localStorage.getItem("userId") ?? "");
  const [isAdmin, setIsAdmin] = useState(localStorage.getItem("isAdmin") === "true");
  const [newUserEmail, setNewUserEmail] = useState("");
  const [newUserPassword, setNewUserPassword] = useState("");
  const [newUserName, setNewUserName] = useState("");
  const [newUserIsAdmin, setNewUserIsAdmin] = useState(false);
  const [loading, setLoading] = useState(false);
  const [authMessage, setAuthMessage] = useState("");
  const [playbackDebug, setPlaybackDebug] = useState("");
  const [tracks, setTracks] = useState<Track[]>([]);
  const [tab, setTab] = useState<"tracks" | "artists" | "albums" | "playlists">("tracks");
  const [selectedArtist, setSelectedArtist] = useState<string | null>(null);
  const [selectedAlbum, setSelectedAlbum] = useState<string | null>(null);
  const [currentTrackIndex, setCurrentTrackIndex] = useState(0);
  const [visualPresets, setVisualPresets] = useState<string[]>([]);
  const [preset, setPreset] = useState<string>("");
  const [query, setQuery] = useState("");
  const [importTitle, setImportTitle] = useState("");
  const [importProgress, setImportProgress] = useState("idle");
  const [selectedTrackIds, setSelectedTrackIds] = useState<string[]>([]);
  const [isEditMode, setIsEditMode] = useState(false);
  const [playlists, setPlaylists] = useState<{ id: string; name: string }[]>([]);
  const [playlistName, setPlaylistName] = useState("");
  const [sortBy, setSortBy] = useState<"title" | "artist" | "duration">("title");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [editingTrackId, setEditingTrackId] = useState<string | null>(null);
  const [editingTrackTitle, setEditingTrackTitle] = useState("");
  const [openTrackMenuId, setOpenTrackMenuId] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [isPlayerExpanded, setIsPlayerExpanded] = useState(false);
  const [playerViewMode, setPlayerViewMode] = useState<"gradient" | "visualizer">("gradient");
  const [isLyricsOpen, setIsLyricsOpen] = useState(false);
  const [isFullscreenMenuOpen, setIsFullscreenMenuOpen] = useState(false);
  const [isFilterMenuOpen, setIsFilterMenuOpen] = useState(false);
  const [isBeatReactive, setIsBeatReactive] = useState(false);
  const [accentA, setAccentA] = useState("#d0bcff");
  const [accentB, setAccentB] = useState("#7d5260");
  const [accentC, setAccentC] = useState("#4f378b");
  const [audioEnergy, setAudioEnergy] = useState(0.18);
  const [isAnonymousShareMode, setIsAnonymousShareMode] = useState(false);
  const [shareAccessToken, setShareAccessToken] = useState<string | null>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const audioRef = useRef<HTMLAudioElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const folderInputRef = useRef<HTMLInputElement>(null);
  const importMenuRef = useRef<HTMLDivElement | null>(null);
  const importMenuTriggerRef = useRef<HTMLButtonElement | null>(null);
  const [isImportMenuOpen, setIsImportMenuOpen] = useState(false);
  const audioContextRef = useRef<AudioContext | null>(null);
  const sourceNodeRef = useRef<MediaElementAudioSourceNode | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const analyserRafRef = useRef<number | null>(null);
  const playbackRetryCountRef = useRef(0);
  const playbackRetryingRef = useRef(false);
  const currentTrackMetaRef = useRef<{ id: string; title: string } | null>(null);
  const streamBlobFallbackRef = useRef<Map<string, string>>(new Map());
  const streamBlobFallbackTriedRef = useRef<Set<string>>(new Set());
  const energySmoothRef = useRef(0.18);
  const milkEngineRef = useRef<MilkEngine | null>(null);
  const moreMenuRef = useRef<HTMLDivElement | null>(null);
  const moreMenuTriggerRef = useRef<HTMLButtonElement | null>(null);
  const filterMenuRef = useRef<HTMLDivElement | null>(null);
  const filterMenuTriggerRef = useRef<HTMLButtonElement | null>(null);
  const tabs = ["tracks", "artists", "albums", "playlists"] as const;

  const murl = useCallback(
    (path: string) => mediaUrl(path, sessionId, isAnonymousShareMode ? shareAccessToken : null),
    [sessionId, shareAccessToken, isAnonymousShareMode]
  );

  useEffect(() => {
    const match = /^\/share\/([^/]+)$/.exec(window.location.pathname);
    if (!match) return;
    const token = match[1];
    setShareAccessToken(token);
    setIsAnonymousShareMode(true);
    fetch(apiUrl(`/share/${encodeURIComponent(token)}`))
      .then((res) => (res.ok ? res.json() : null))
      .then((data: Track | null) => {
        if (!data) {
          setAuthMessage("Ungültiger Share-Link.");
          return;
        }
        const normalized = [{ ...data, source: "server" as const }];
        setTracks(normalized);
        queue.load(normalized.map((t) => t.id));
        setCurrentTrackIndex(0);
        setIsPlayerExpanded(true);
        setTimeout(() => play(0), 120);
      })
      .catch(() => setAuthMessage("Share-Link konnte nicht geladen werden."));
  }, []);

  useEffect(() => {
    return () => {
      for (const url of streamBlobFallbackRef.current.values()) {
        URL.revokeObjectURL(url);
      }
      streamBlobFallbackRef.current.clear();
      streamBlobFallbackTriedRef.current.clear();
    };
  }, []);

  useEffect(() => {
    fetch(apiUrl("/visual/presets"))
      .then((res) => res.json())
      .then((data: string[]) => {
        setVisualPresets(data);
        setPreset(data[0] ?? "");
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (!preset || !milkEngineRef.current) return;
    fetch(apiUrl(`/visual/preset?name=${encodeURIComponent(preset)}`))
      .then((res) => res.json())
      .then((data: { content?: string }) => {
        milkEngineRef.current?.loadPresetByName(preset, data.content);
      })
      .catch(() => {
        milkEngineRef.current?.loadPresetByName(preset);
      });
  }, [preset]);

  useEffect(() => {
    if (!userId || !sessionId) return;
    apiFetch(`/library/tracks/${userId}?limit=500`, { sessionId })
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error(`tracks ${res.status}`))))
      .then((data: Track[]) => {
        const normalized = data.map((t) => ({ ...t, source: "server" as const }));
        setTracks(normalized);
        queue.load(normalized.map((t) => t.id));
      })
      .catch(() => {
        setAuthMessage("Track-Liste konnte nicht geladen werden.");
      });
    apiFetch(`/users/${userId}/playlists`, { sessionId })
      .then((res) => (res.ok ? res.json() : Promise.reject(new Error(`playlists ${res.status}`))))
      .then((data: { id: string; name: string }[]) => setPlaylists(data))
      .catch(() => {
        setAuthMessage("Playlisten konnten nicht geladen werden.");
      });
  }, [userId, sessionId]);

  useEffect(() => {
    if (!sessionId) return;
    fetch(apiUrl(`/auth/session/${sessionId}`))
      .then((res) => res.json())
      .then((data) => {
        if (!data.valid) {
          setSessionId("");
          setUserId("");
          setIsAdmin(false);
          localStorage.removeItem("sessionId");
          localStorage.removeItem("userId");
          localStorage.removeItem("isAdmin");
          localStorage.removeItem("email");
        } else {
          setIsAdmin(Boolean(data.isAdmin));
          localStorage.setItem("isAdmin", String(Boolean(data.isAdmin)));
        }
      })
      .catch(() => {});
  }, [sessionId]);

  useEffect(() => {
    if (!sessionId) return;
    const ws = new WebSocket(`${getApiWsBase()}/events`);
    ws.onopen = () => {
      ws.send(JSON.stringify({ type: "client.auth", sessionId }));
    };
    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      if (message.type === "import.progress") {
        setImportProgress(`${message.processed}/${message.total}`);
      }
      if (message.type === "import.done") {
        setImportProgress(`done (${message.imported})`);
      }
    };
    return () => ws.close();
  }, [sessionId]);

  useEffect(() => {
    const onResize = () => {
      if (canvasRef.current && milkEngineRef.current) milkEngineRef.current.resize(canvasRef.current);
    };
    window.addEventListener("resize", onResize);
    return () => {
      window.removeEventListener("resize", onResize);
      milkEngineRef.current?.dispose();
      milkEngineRef.current = null;
    };
  }, []);

  useEffect(() => {
    if (!isPlayerExpanded || playerViewMode !== "visualizer") {
      milkEngineRef.current?.stop();
      return;
    }
    if (!canvasRef.current || !audioContextRef.current || !sourceNodeRef.current) return;
    if (milkEngineRef.current) {
      milkEngineRef.current.resize(canvasRef.current);
      milkEngineRef.current.start();
      return;
    }
    let cancelled = false;
    milkEngineRef.current = new MilkEngine();
    milkEngineRef.current
      .init(canvasRef.current, audioContextRef.current, sourceNodeRef.current)
      .then(() => {
        if (cancelled) return;
        if (preset) {
          fetch(apiUrl(`/visual/preset?name=${encodeURIComponent(preset)}`))
            .then((res) => res.json())
            .then((data: { content?: string }) => milkEngineRef.current?.loadPresetByName(preset, data.content))
            .catch(() => milkEngineRef.current?.loadPresetByName(preset));
        }
      })
      .catch(() => {});
    return () => {
      cancelled = true;
    };
  }, [isPlayerExpanded, playerViewMode, preset]);

  useEffect(() => {
    if (playerViewMode === "visualizer" && isBeatReactive) {
      setIsBeatReactive(false);
    }
  }, [playerViewMode, isBeatReactive]);

  const artists = useMemo(() => {
    const map = new Map<string, { name: string; coverTrackId: string | null }>();
    for (const track of tracks) {
      const current = map.get(track.artist);
      if (!current) {
        map.set(track.artist, { name: track.artist, coverTrackId: track.cover_path ? track.id : null });
      } else if (!current.coverTrackId && track.cover_path) {
        current.coverTrackId = track.id;
      }
    }
    return [...map.values()].sort((a, b) => a.name.localeCompare(b.name));
  }, [tracks]);

  const albums = useMemo(() => {
    const map = new Map<string, { name: string; coverTrackId: string | null }>();
    for (const track of tracks) {
      if (!track.album) continue;
      const current = map.get(track.album);
      if (!current) {
        map.set(track.album, { name: track.album, coverTrackId: track.cover_path ? track.id : null });
      } else if (!current.coverTrackId && track.cover_path) {
        current.coverTrackId = track.id;
      }
    }
    return [...map.values()].sort((a, b) => a.name.localeCompare(b.name));
  }, [tracks]);

  const sortedTracks = useMemo(() => {
    const list = [...tracks];
    list.sort((a, b) => {
      const dir = sortDir === "asc" ? 1 : -1;
      if (sortBy === "duration") return (a.duration_sec - b.duration_sec) * dir;
      return a[sortBy].localeCompare(b[sortBy]) * dir;
    });
    return list;
  }, [tracks, sortBy, sortDir]);
  const artistTracks = useMemo(
    () => (selectedArtist ? sortedTracks.filter((track) => track.artist === selectedArtist) : []),
    [selectedArtist, sortedTracks]
  );
  const albumTracks = useMemo(
    () => (selectedAlbum ? sortedTracks.filter((track) => track.album === selectedAlbum) : []),
    [selectedAlbum, sortedTracks]
  );
  const activeTrack = sortedTracks[currentTrackIndex];
  function openArtistPage(artistName: string): void {
    if (!artistName) return;
    setSelectedArtist(artistName);
    setSelectedAlbum(null);
    setTab("artists");
  }

  function openAlbumPage(albumName: string): void {
    if (!albumName) return;
    setSelectedAlbum(albumName);
    setSelectedArtist(null);
    setTab("albums");
  }

  const progressRatio = duration > 0 ? Math.max(0, Math.min(1, currentTime / duration)) : 0;
  const waveBars = useMemo(() => Array.from({ length: 56 }, (_, i) => i), []);
  const auroraOrbs = useMemo(
    () =>
      Array.from({ length: 7 }, (_, i) => ({
        id: i,
        left: `${8 + Math.random() * 84}%`,
        top: `${6 + Math.random() * 82}%`,
        size: `${18 + Math.random() * 24}vw`,
        duration: `${11 + Math.random() * 13}s`,
        delay: `${Math.random() * 3.8}s`
      })),
    []
  );

  useEffect(() => {
    if (!activeTrack?.cover_path) {
      setAccentA("#d0bcff");
      setAccentB("#ff8fa3");
      setAccentC("#4f8bff");
      return;
    }
    const img = new Image();
    img.crossOrigin = "anonymous";
    img.src = murl(`/media/track/${activeTrack.id}/cover`);
    img.onload = () => {
      const swatch = document.createElement("canvas");
      swatch.width = 32;
      swatch.height = 32;
      const ctx = swatch.getContext("2d");
      if (!ctx) return;
      ctx.drawImage(img, 0, 0, 32, 32);
      const { data } = ctx.getImageData(0, 0, 32, 32);
      let r = 0;
      let g = 0;
      let b = 0;
      const pixels = data.length / 4;
      for (let i = 0; i < data.length; i += 4) {
        r += data[i];
        g += data[i + 1];
        b += data[i + 2];
      }
      const avgR = Math.floor(r / pixels);
      const avgG = Math.floor(g / pixels);
      const avgB = Math.floor(b / pixels);

      const buckets = new Map<string, { count: number; r: number; g: number; b: number }>();
      for (let i = 0; i < data.length; i += 4) {
        const rr = data[i];
        const gg = data[i + 1];
        const bb = data[i + 2];
        const alpha = data[i + 3];
        if (alpha < 20) continue;
        const key = `${rr >> 3}-${gg >> 3}-${bb >> 3}`;
        const prev = buckets.get(key);
        if (prev) {
          prev.count += 1;
          prev.r += rr;
          prev.g += gg;
          prev.b += bb;
        } else {
          buckets.set(key, { count: 1, r: rr, g: gg, b: bb });
        }
      }

      const palette = [...buckets.values()]
        .map((entry) => {
          const color = { r: entry.r / entry.count, g: entry.g / entry.count, b: entry.b / entry.count };
          const hsl = rgbToHsl(color.r, color.g, color.b);
          return {
            count: entry.count,
            color,
            saturation: hsl.s,
            lightness: hsl.l
          };
        })
        .filter((entry) => entry.count >= 3)
        .sort((a, b) => b.count - a.count)
        .slice(0, 80)
        .sort((a, b) => {
          const scoreA = a.saturation * 1.7 + clamp(1 - Math.abs(a.lightness - 0.52), 0, 1) * 0.5 + Math.log10(a.count + 1) * 0.38;
          const scoreB = b.saturation * 1.7 + clamp(1 - Math.abs(b.lightness - 0.52), 0, 1) * 0.5 + Math.log10(b.count + 1) * 0.38;
          return scoreB - scoreA;
        })
        .map((entry) => ({
          count: entry.count,
          color: entry.color
        }))
        .map((entry) => entry.color);

      const fallbackBase = { r: avgR, g: avgG, b: avgB };
      const primary = palette[0] ?? fallbackBase;
      const second =
        palette.find((candidate) => colorDistance(candidate, primary) > 48) ??
        adjustColorLightness(primary, -0.12);
      const third =
        palette.find((candidate) => colorDistance(candidate, primary) > 78 && colorDistance(candidate, second) > 42) ??
        adjustColorLightness(primary, 0.14);

      setAccentA(colorToRgbString(primary));
      setAccentB(colorToRgbString(second));
      setAccentC(colorToRgbString(third));
    };
  }, [activeTrack?.id, activeTrack?.cover_path, murl]);

  useEffect(() => {
    const needsEnergyLoop = isPlayerExpanded && playerViewMode === "gradient" && isBeatReactive && isPlaying;
    if (!needsEnergyLoop) {
      if (analyserRafRef.current) {
        cancelAnimationFrame(analyserRafRef.current);
        analyserRafRef.current = null;
      }
      return;
    }
    if (!audioContextRef.current || !sourceNodeRef.current) return;
    if (!analyserRef.current) {
      const analyser = audioContextRef.current.createAnalyser();
      analyser.fftSize = 256;
      analyser.smoothingTimeConstant = 0.86;
      sourceNodeRef.current.connect(analyser);
      analyserRef.current = analyser;
    }
    if (analyserRafRef.current) cancelAnimationFrame(analyserRafRef.current);
    const analyser = analyserRef.current;
    if (!analyser) return;
    const data = new Uint8Array(analyser.frequencyBinCount);
    let frameCounter = 0;

    const tick = () => {
      analyser.getByteFrequencyData(data);
      let sum = 0;
      for (let i = 0; i < data.length; i++) sum += data[i];
      const raw = sum / (data.length * 255);
      const target = 0.14 + raw * 0.95;
      energySmoothRef.current += (target - energySmoothRef.current) * 0.08;
      frameCounter += 1;
      // Keep React updates sparse; this state drives only CSS energy effects.
      if (frameCounter % 4 === 0) {
        setAudioEnergy(clamp(energySmoothRef.current, 0.08, 1));
      }
      analyserRafRef.current = requestAnimationFrame(tick);
    };
    analyserRafRef.current = requestAnimationFrame(tick);
    return () => {
      if (analyserRafRef.current) {
        cancelAnimationFrame(analyserRafRef.current);
        analyserRafRef.current = null;
      }
    };
  }, [isPlayerExpanded, playerViewMode, isBeatReactive, isPlaying]);

  useEffect(() => {
    if (!isFullscreenMenuOpen) return;
    const onPointerDown = (event: PointerEvent) => {
      const target = event.target as Node | null;
      if (!target) return;
      const insideMenu = moreMenuRef.current?.contains(target);
      const insideTrigger = moreMenuTriggerRef.current?.contains(target);
      if (!insideMenu && !insideTrigger) {
        setIsFullscreenMenuOpen(false);
      }
    };
    window.addEventListener("pointerdown", onPointerDown);
    return () => window.removeEventListener("pointerdown", onPointerDown);
  }, [isFullscreenMenuOpen]);

  useEffect(() => {
    const onPointerDown = (event: PointerEvent) => {
      const target = event.target as Node | null;
      if (!target) return;
      const insideFilterMenu = filterMenuRef.current?.contains(target);
      const insideFilterTrigger = filterMenuTriggerRef.current?.contains(target);
      if (isFilterMenuOpen && !insideFilterMenu && !insideFilterTrigger) {
        setIsFilterMenuOpen(false);
      }
    };
    window.addEventListener("pointerdown", onPointerDown);
    return () => window.removeEventListener("pointerdown", onPointerDown);
  }, [isFilterMenuOpen]);

  useEffect(() => {
    if (!isImportMenuOpen) return;
    const onPointerDown = (event: PointerEvent) => {
      const target = event.target as Node | null;
      if (!target) return;
      if (
        importMenuRef.current?.contains(target) ||
        importMenuTriggerRef.current?.contains(target)
      ) {
        return;
      }
      setIsImportMenuOpen(false);
    };
    window.addEventListener("pointerdown", onPointerDown);
    return () => window.removeEventListener("pointerdown", onPointerDown);
  }, [isImportMenuOpen]);

  useEffect(() => {
    if (!openTrackMenuId) return;
    const onPointerDown = () => setOpenTrackMenuId(null);
    window.addEventListener("pointerdown", onPointerDown);
    return () => window.removeEventListener("pointerdown", onPointerDown);
  }, [openTrackMenuId]);

  async function login() {
    setLoading(true);
    setAuthMessage("");
    try {
      const res = await fetch(apiUrl("/auth/login"), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password })
      });
      if (!res.ok) {
        setAuthMessage("Login fehlgeschlagen (API Fehler).");
        return;
      }
      const data = await res.json();
      if (data.error) {
        setAuthMessage(data.error);
        return;
      }
      setSessionId(data.sessionId);
      setUserId(data.userId);
      setIsAdmin(Boolean(data.isAdmin));
      localStorage.setItem("sessionId", data.sessionId);
      localStorage.setItem("userId", data.userId);
      localStorage.setItem("email", email);
      localStorage.setItem("isAdmin", String(Boolean(data.isAdmin)));
      setAuthMessage("Login erfolgreich.");
    } catch {
      setAuthMessage("API nicht erreichbar. Bitte zuerst 'bun run dev:api' starten.");
    } finally {
      setLoading(false);
    }
  }

  async function logout() {
    if (sessionId) {
      await apiFetch("/auth/logout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sessionId }),
        sessionId
      });
    }
    setSessionId("");
    setUserId("");
    setIsAdmin(false);
    setPassword("");
    localStorage.removeItem("sessionId");
    localStorage.removeItem("userId");
    localStorage.removeItem("isAdmin");
  }

  const audioExt = new Set([
    ".mp3",
    ".wav",
    ".flac",
    ".ogg",
    ".m4a",
    ".aac",
    ".opus",
    ".wma",
    ".webm"
  ]);

  function isLikelyAudioFile(file: File): boolean {
    if (file.type && file.type.startsWith("audio/")) return true;
    const n = file.name.toLowerCase();
    const d = n.lastIndexOf(".");
    if (d < 0) return false;
    return audioExt.has(n.slice(d));
  }

  function openFilePicker() {
    fileInputRef.current?.click();
  }

  async function importFromFiles() {
    setIsImportMenuOpen(false);
    try {
      if ("showOpenFilePicker" in window) {
        const picker = (window as unknown as {
          showOpenFilePicker: (opts: {
            multiple: boolean;
            excludeAcceptAllOption: boolean;
            types: Array<{ description: string; accept: Record<string, string[]> }>;
          }) => Promise<Array<{ getFile: () => Promise<File> }>>;
        }).showOpenFilePicker;
        const handles = await picker({
          multiple: true,
          excludeAcceptAllOption: false,
          types: [
            {
              description: "Audio",
              accept: { "audio/*": [".mp3", ".wav", ".flac", ".ogg", ".m4a", ".aac", ".opus"] }
            }
          ]
        });
        const files = await Promise.all(handles.map((h) => h.getFile()));
        if (files.length > 0) {
          await importLocalFiles(files);
          return;
        }
      }
    } catch {
      // Abgebrochen: Fallback-Dateidialog
    }
    openFilePicker();
  }

  async function importFromFolder() {
    setIsImportMenuOpen(false);
    if ("showDirectoryPicker" in window) {
      await pickDirectoryWithFsApi();
      return;
    }
    folderInputRef.current?.click();
  }

  async function uploadAndPersistFiles(fileList: FileList | File[]) {
    if (!userId || !sessionId) return;
    const files = Array.isArray(fileList) ? fileList : Array.from(fileList);
    if (files.length === 0) return;
    setImportProgress("uploading");
    const form = new FormData();
    form.append("userId", userId);
    for (const file of files) form.append("files", file);
    const response = await apiFetch("/library/import-upload", { method: "POST", body: form, sessionId });
    if (!response.ok) {
      setImportProgress("upload failed");
      return;
    }
    const result = await response.json() as { imported: number };
    const data = await apiFetch(`/library/tracks/${userId}?limit=500`, { sessionId }).then((res) => res.json());
    const normalized = (data as Track[]).map((t) => ({ ...t, source: "server" as const }));
    setTracks(normalized);
    queue.load(normalized.map((t) => t.id));
    setImportProgress(`${result.imported} Dateien importiert`);
  }

  async function pickDirectoryWithFsApi() {
    type DirWithValues = FileSystemDirectoryHandle & {
      values: () => AsyncIterableIterator<FileSystemFileHandle | FileSystemDirectoryHandle>;
    };
    try {
      const picker = (window as unknown as { showDirectoryPicker: () => Promise<FileSystemDirectoryHandle> }).showDirectoryPicker;
      const handle = await picker();
      const collected: File[] = [];
      const walk = async (dir: FileSystemDirectoryHandle) => {
        for await (const entry of (dir as DirWithValues).values()) {
          if (entry.kind === "directory") {
            await walk(entry);
          } else if (entry.kind === "file") {
            const file = await entry.getFile();
            if (isLikelyAudioFile(file)) collected.push(file);
          }
        }
      };
      await walk(handle);
      if (collected.length === 0) {
        setImportProgress("keine Audiodateien im Ordner");
        return;
      }
      await uploadAndPersistFiles(collected);
    } catch {
      setImportProgress("folder picker cancelled");
    }
  }

  async function importLocalFiles(files: FileList | File[] | null) {
    if (!files || files.length === 0) return;
    const fileArr = Array.isArray(files) ? files : Array.from(files);
    const imported: Track[] = [];
    fileArr.forEach((file, idx) => {
      const name = file.name.replace(/\.[^/.]+$/, "");
      imported.push({
        id: `local-${Date.now()}-${idx}-${crypto.randomUUID()}`,
        title: importTitle.trim() ? `${importTitle.trim()} - ${name}` : name,
        artist: "Lokale Datei",
        album: "Lokaler Import",
        duration_sec: 0,
        file_path: file.name,
        source: "local",
        object_url: URL.createObjectURL(file)
      });
    });
    setTracks((prev) => {
      const nextTracks = [...imported, ...prev];
      queue.load(nextTracks.map((t) => t.id));
      return nextTracks;
    });
    await uploadAndPersistFiles(fileArr);
  }

  async function searchTracks(term: string) {
    setQuery(term);
    if (!userId || !sessionId) return;
    if (!term.trim()) {
      const data = await apiFetch(`/library/tracks/${userId}?limit=500`, { sessionId }).then((res) => res.json());
      setTracks(data);
      return;
    }
    const data = await apiFetch(`/library/search/${userId}?q=${encodeURIComponent(term)}`, { sessionId }).then((res) =>
      res.json()
    );
    setTracks(data);
  }

  async function createPlaylistFromSelection() {
    if (!playlistName || !selectedTrackIds.length || !userId || !sessionId) return;
    await apiFetch("/playlist/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId, name: playlistName, trackIds: selectedTrackIds }),
      sessionId
    });
    setPlaylistName("");
    setSelectedTrackIds([]);
    const data = await apiFetch(`/users/${userId}/playlists`, { sessionId }).then((res) => res.json());
    setPlaylists(data);
  }

  async function createPlaylistWithTrack(track: Track) {
    if (!userId || !sessionId) return;
    const name = window.prompt("Playlist Name");
    if (!name?.trim()) return;
    await apiFetch("/playlist/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId, name: name.trim(), trackIds: [track.id] }),
      sessionId
    });
    const data = await apiFetch(`/users/${userId}/playlists`, { sessionId }).then((res) => res.json());
    setPlaylists(data);
    setOpenTrackMenuId(null);
  }

  async function addTrackToPlaylist(track: Track) {
    if (!userId || !sessionId) return;
    if (!playlists.length) {
      setAuthMessage("Keine Playlists vorhanden.");
      return;
    }
    const list = playlists.map((p, idx) => `${idx + 1}. ${p.name}`).join("\n");
    const selection = window.prompt(`Zu welcher Playlist hinzufügen?\n${list}`);
    const numeric = Number(selection);
    const chosen = Number.isFinite(numeric) ? playlists[numeric - 1] : playlists.find((p) => p.name.toLowerCase() === selection?.toLowerCase());
    if (!chosen) return;
    await apiFetch(`/playlists/${chosen.id}/add-track`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ trackId: track.id }),
      sessionId
    });
    setOpenTrackMenuId(null);
  }

  async function removeTrack(track: Track) {
    if (!userId || !sessionId) return;
    await apiFetch("/library/track/delete", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId, trackId: track.id }),
      sessionId
    });
    setTracks((prev) => prev.filter((t) => t.id !== track.id));
    setOpenTrackMenuId(null);
  }

  async function shareTrack(track: Track) {
    if (!userId || !sessionId) return;
    const response = await apiFetch("/library/track/share", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId, trackId: track.id }),
      sessionId
    });
    const data = await response.json() as { token?: string };
    if (data.token) {
      const shareUrl = `${window.location.origin}/share/${data.token}`;
      await navigator.clipboard.writeText(shareUrl).catch(() => {});
      setAuthMessage("Share-Link kopiert.");
    }
    setOpenTrackMenuId(null);
  }

  function viewTrackInfo(track: Track) {
    const info = [
      `Title: ${track.title}`,
      `Artist: ${track.artist}`,
      `Album: ${track.album ?? "-"}`,
      `Duration: ${track.duration_sec}s`,
      `File: ${track.file_path}`,
      `Favorite: ${track.is_favorite ? "Yes" : "No"}`,
      `Lyrics: ${track.lyrics ? "available" : "none"}`
    ].join("\n");
    window.alert(info);
    setOpenTrackMenuId(null);
  }

  async function toggleFavorite(track: Track) {
    if (!userId || !sessionId) return;
    const response = await apiFetch("/library/track/favorite-toggle", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ userId, trackId: track.id }),
      sessionId
    });
    const data = await response.json() as { isFavorite: boolean };
    setTracks((prev) => prev.map((t) => (t.id === track.id ? { ...t, is_favorite: data.isFavorite } : t)));
    setOpenTrackMenuId(null);
  }

  async function createUserAsAdmin() {
    if (!sessionId || !newUserEmail.trim() || !newUserPassword.trim()) return;
    const res = await apiFetch("/admin/users/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        sessionId,
        email: newUserEmail.trim().toLowerCase(),
        password: newUserPassword,
        displayName: newUserName.trim() || undefined,
        isAdmin: newUserIsAdmin
      }),
      sessionId
    });
    if (!res.ok) {
      setAuthMessage("User konnte nicht erstellt werden.");
      return;
    }
    setNewUserEmail("");
    setNewUserPassword("");
    setNewUserName("");
    setNewUserIsAdmin(false);
    setAuthMessage("User erstellt.");
  }

  async function persistEncryptedSettings() {
    if (!password || !userId) return;
    if (!sessionId) return;
    await apiFetch("/secure/blob", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        userId,
        secret: password,
        payload: {
          visualPreset: preset,
          repeatMode: queue.getState().repeatMode,
          updatedAt: Date.now()
        }
      }),
      sessionId
    });
  }

  function play(index: number) {
    const track = sortedTracks[index];
    if (audioRef.current && track) {
      currentTrackMetaRef.current = { id: track.id, title: track.title };
      streamBlobFallbackTriedRef.current.delete(track.id);
      const nextSrc = track.source === "local" && track.object_url
        ? track.object_url
        : streamBlobFallbackRef.current.get(track.id) ?? murl(`/media/track/${track.id}/stream`);
      const currentSrc = audioRef.current.currentSrc || audioRef.current.src || "";
      if (currentSrc === nextSrc) {
        audioContextRef.current?.resume().catch(() => {});
        audioRef.current
          .play()
          .then(() => {
          playbackRetryCountRef.current = 0;
          playbackRetryingRef.current = false;
            setCurrentTrackIndex(index);
            setAuthMessage("");
            setPlaybackDebug("");
            setIsPlaying(true);
          })
          .catch(() => {
            reportPlaybackIssue("play() failed while resuming same src", audioRef.current as HTMLAudioElement);
          });
        return;
      }
      setCurrentTrackIndex(index);
      if (!audioContextRef.current) {
        audioContextRef.current = new AudioContext();
      }
      if (!sourceNodeRef.current) {
        const sourceNode = audioContextRef.current.createMediaElementSource(audioRef.current);
        // Keep audio audible after routing through WebAudio graph.
        sourceNode.connect(audioContextRef.current.destination);
        sourceNodeRef.current = sourceNode;
      }
      if (track.source === "local" && track.object_url) {
        audioRef.current.src = track.object_url;
      } else {
        audioRef.current.src = murl(`/media/track/${track.id}/stream`);
      }
      audioRef.current.load();
      audioContextRef.current.resume().catch(() => {});
      audioRef.current
        .play()
        .then(() => {
          playbackRetryCountRef.current = 0;
          playbackRetryingRef.current = false;
          setAuthMessage("");
          setPlaybackDebug("");
          setIsPlaying(true);
        })
        .catch(() => {
          reportPlaybackIssue("play() failed after source swap", audioRef.current as HTMLAudioElement);
        });
    }
  }

  function next() {
    const nextIndex = queue.next();
    play(nextIndex);
  }

  function previous() {
    const prevIndex = queue.previous();
    play(prevIndex);
  }

  function pause() {
    if (!audioRef.current) return;
    audioRef.current.pause();
    setIsPlaying(false);
  }

  function resumePlayback() {
    if (!audioRef.current) return;
    if (!audioRef.current.src && !audioRef.current.currentSrc) {
      play(currentTrackIndex);
      return;
    }
    audioContextRef.current?.resume().catch(() => {});
    audioRef.current
      .play()
      .then(() => {
        setAuthMessage("");
        setPlaybackDebug("");
        setIsPlaying(true);
      })
      .catch(() => {
        reportPlaybackIssue("resumePlayback() failed", audioRef.current as HTMLAudioElement);
      });
  }

  function stop() {
    if (!audioRef.current) return;
    audioRef.current.pause();
    audioRef.current.currentTime = 0;
    setIsPlaying(false);
  }

  function skip(seconds: number) {
    if (!audioRef.current) return;
    audioRef.current.currentTime = Math.max(0, audioRef.current.currentTime + seconds);
  }

  function seekTo(ratio: number) {
    if (!audioRef.current) return;
    const knownDuration = duration > 0 ? duration : (activeTrack?.duration_sec ?? 0);
    if (!Number.isFinite(knownDuration) || knownDuration <= 0) return;
    const nextTime = knownDuration * ratio;
    audioRef.current.currentTime = nextTime;
    setCurrentTime(nextTime);
  }

  function formatTime(seconds: number): string {
    if (!Number.isFinite(seconds) || seconds <= 0) return "0:00";
    const total = Math.floor(seconds);
    const min = Math.floor(total / 60);
    const sec = total % 60;
    return `${min}:${sec.toString().padStart(2, "0")}`;
  }

  function mediaErrorLabel(code: number): string {
    if (code === 1) return "MEDIA_ERR_ABORTED";
    if (code === 2) return "MEDIA_ERR_NETWORK";
    if (code === 3) return "MEDIA_ERR_DECODE";
    if (code === 4) return "MEDIA_ERR_SRC_NOT_SUPPORTED";
    return "UNKNOWN_MEDIA_ERROR";
  }

  function reportPlaybackIssue(reason: string, audio: HTMLAudioElement): void {
    const mediaErr = audio.error;
    const srcTrackIdMatch = /\/media\/track\/([^/]+)\//.exec(audio.currentSrc || audio.src || "");
    const details = {
      reason,
      mediaErrorCode: mediaErr?.code ?? null,
      mediaErrorLabel: mediaErr ? mediaErrorLabel(mediaErr.code) : null,
      networkState: audio.networkState,
      readyState: audio.readyState,
      currentTime: Number((audio.currentTime || 0).toFixed(3)),
      duration: Number((audio.duration || 0).toFixed(3)),
      src: audio.currentSrc || audio.src || null,
      trackId: activeTrack?.id ?? currentTrackMetaRef.current?.id ?? srcTrackIdMatch?.[1] ?? null,
      trackTitle: activeTrack?.title ?? currentTrackMetaRef.current?.title ?? null
    };
    console.error("[musicrr:playback]", details);
    setPlaybackDebug(JSON.stringify(details, null, 2));
    const codeSuffix = details.mediaErrorLabel ? ` (${details.mediaErrorLabel})` : "";
    setAuthMessage(`Playback fehlgeschlagen${codeSuffix}. Siehe Debug-Details.`);
  }

  async function attemptStreamBlobFallback(audio: HTMLAudioElement, resumeAt: number, trackId: string): Promise<void> {
    if (playbackRetryingRef.current) return;
    playbackRetryingRef.current = true;
    try {
      const base = murl(`/media/track/${trackId}/stream`);
      const blobUrl = `${base}${base.includes("?") ? "&" : "?"}blob_fallback=${Date.now()}`;
      const response = await fetch(blobUrl, {
        cache: "no-store",
        headers: sessionId ? { Authorization: `Bearer ${sessionId}` } : undefined
      });
      if (!response.ok) throw new Error(`blob fallback fetch failed (${response.status})`);
      const blob = await response.blob();
      if (!blob.size) throw new Error("blob fallback returned empty payload");

      const previous = streamBlobFallbackRef.current.get(trackId);
      if (previous) URL.revokeObjectURL(previous);
      const objectUrl = URL.createObjectURL(blob);
      streamBlobFallbackRef.current.set(trackId, objectUrl);

      audio.src = objectUrl;
      audio.load();
      await new Promise<void>((resolve, reject) => {
        const onCanPlay = () => {
          audio.removeEventListener("canplay", onCanPlay);
          audio.removeEventListener("error", onErr);
          resolve();
        };
        const onErr = () => {
          audio.removeEventListener("canplay", onCanPlay);
          audio.removeEventListener("error", onErr);
          reject(new Error("blob fallback canplay failed"));
        };
        audio.addEventListener("canplay", onCanPlay);
        audio.addEventListener("error", onErr);
      });

      audio.currentTime = Math.max(0, Math.min((audio.duration || resumeAt + 1), resumeAt));
      await audio.play();
      setAuthMessage(`Stream-Decode-Problem erkannt, lokaler Fallback aktiv (${formatTime(audio.currentTime)}).`);
      setPlaybackDebug("");
      setIsPlaying(true);
    } catch (error) {
      reportPlaybackIssue(`blob fallback failed: ${error instanceof Error ? error.message : "unknown"}`, audio);
    } finally {
      playbackRetryingRef.current = false;
    }
  }

  useEffect(() => {
    const audio = audioRef.current;
    if (!audio) return;
    const onPause = () => setIsPlaying(false);
    const onPlay = () => setIsPlaying(true);
    const onTimeUpdate = () => setCurrentTime(audio.currentTime || 0);
    const onLoadedMetadata = () => setDuration(audio.duration || 0);
    const onDurationChange = () => setDuration(audio.duration || 0);
    const onEnded = () => {
      setIsPlaying(false);
      next();
    };
    const onError = () => {
      if (playbackRetryingRef.current) return;
      const currentErrorCode = audio.error?.code ?? 0;
      const srcTrackIdMatch = /\/media\/track\/([^/]+)\//.exec(audio.currentSrc || audio.src || "");
      const sourceTrackId = currentTrackMetaRef.current?.id ?? srcTrackIdMatch?.[1] ?? null;
      if (currentErrorCode === 3 && playbackRetryCountRef.current < 2 && Number.isFinite(audio.duration) && audio.duration > 0) {
        playbackRetryingRef.current = true;
        playbackRetryCountRef.current += 1;
        // Decode glitch recovery: skip a small window around the broken frame.
        const resumeAt = Math.max(0, Math.min((audio.duration || 0) - 0.4, (audio.currentTime || 0) + 1.1));
        const retrySrc = `${audio.currentSrc.split("?")[0]}?decode_retry=${Date.now()}`;
        audio.src = retrySrc;
        audio.load();
        const handleCanPlay = () => {
          audio.removeEventListener("canplay", handleCanPlay);
          audio.currentTime = resumeAt;
          audio
            .play()
            .then(() => {
              playbackRetryingRef.current = false;
              setAuthMessage(`Decode-Glitch erkannt, bei ${formatTime(resumeAt)} fortgesetzt.`);
              setPlaybackDebug("");
              setIsPlaying(true);
            })
            .catch(() => {
              playbackRetryingRef.current = false;
              setIsPlaying(false);
              reportPlaybackIssue("decode recovery failed after skip-ahead", audio);
            });
        };
        audio.addEventListener("canplay", handleCanPlay);
        return;
      }
      if (currentErrorCode === 3 && sourceTrackId && !streamBlobFallbackTriedRef.current.has(sourceTrackId)) {
        streamBlobFallbackTriedRef.current.add(sourceTrackId);
        const resumeAt = Math.max(0, (audio.currentTime || 0) + 0.6);
        void attemptStreamBlobFallback(audio, resumeAt, sourceTrackId);
        return;
      }
      if (playbackRetryCountRef.current < 1 && audio.currentSrc && audio.currentSrc.includes("/media/track/")) {
        playbackRetryingRef.current = true;
        playbackRetryCountRef.current += 1;
        const resumeAt = Math.max(0, audio.currentTime || 0);
        const retrySrc = `${audio.currentSrc.split("?")[0]}?retry=${Date.now()}`;
        audio.src = retrySrc;
        audio.load();
        const handleLoaded = () => {
          audio.removeEventListener("loadedmetadata", handleLoaded);
          audio.currentTime = Math.max(0, resumeAt - 0.2);
          audio
            .play()
            .then(() => {
              playbackRetryingRef.current = false;
              setAuthMessage("");
              setPlaybackDebug("");
              setIsPlaying(true);
            })
            .catch(() => {
              playbackRetryingRef.current = false;
              setIsPlaying(false);
              reportPlaybackIssue("retry play() failed after media error", audio);
            });
        };
        audio.addEventListener("loadedmetadata", handleLoaded);
        return;
      }
      playbackRetryingRef.current = false;
      setIsPlaying(false);
      reportPlaybackIssue("audio element emitted error event", audio);
    };
    audio.addEventListener("pause", onPause);
    audio.addEventListener("play", onPlay);
    audio.addEventListener("timeupdate", onTimeUpdate);
    audio.addEventListener("loadedmetadata", onLoadedMetadata);
    audio.addEventListener("durationchange", onDurationChange);
    audio.addEventListener("ended", onEnded);
    audio.addEventListener("error", onError);
    return () => {
      audio.removeEventListener("pause", onPause);
      audio.removeEventListener("play", onPlay);
      audio.removeEventListener("timeupdate", onTimeUpdate);
      audio.removeEventListener("loadedmetadata", onLoadedMetadata);
      audio.removeEventListener("durationchange", onDurationChange);
      audio.removeEventListener("ended", onEnded);
      audio.removeEventListener("error", onError);
    };
  }, []);

  async function deleteSelectedTracks() {
    if (!selectedTrackIds.length) return;
    if (userId && sessionId) {
      await Promise.all(
        selectedTrackIds.map((trackId) =>
          apiFetch("/library/track/delete", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ userId, trackId }),
            sessionId
          }).catch(() => {})
        )
      );
    }
    setTracks((prev) => prev.filter((track) => !selectedTrackIds.includes(track.id)));
    setSelectedTrackIds([]);
  }

  function toggleTrackSelection(trackId: string) {
    setSelectedTrackIds((prev) => (prev.includes(trackId) ? prev.filter((id) => id !== trackId) : [...prev, trackId]));
  }

  function startEditTrack(track: Track) {
    setEditingTrackId(track.id);
    setEditingTrackTitle(track.title);
  }

  async function saveTrackEdit(track: Track) {
    const title = editingTrackTitle.trim();
    if (!title) return;
    if (track.source !== "local" && userId && sessionId) {
      await apiFetch("/library/track/update", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, trackId: track.id, title }),
        sessionId
      }).catch(() => {});
    }
    setTracks((prev) => prev.map((t) => (t.id === track.id ? { ...t, title } : t)));
    setEditingTrackId(null);
    setEditingTrackTitle("");
  }

  async function deletePlaylist(playlistId: string) {
    if (userId && sessionId) {
      await apiFetch("/playlist/delete", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, playlistId }),
        sessionId
      }).catch(() => {});
    }
    setPlaylists((prev) => prev.filter((p) => p.id !== playlistId));
  }

  if (!sessionId && !isAnonymousShareMode) {
    return (
      <AppShell title="Musicrr">
        <div className="mx-auto mt-12 max-w-xl rounded-[28px] border border-[#4a445866] bg-[#211f26cc] p-8 shadow-2xl backdrop-blur">
          <p className="mb-2 text-xs uppercase tracking-[0.16em] text-[#ccc2dc]">Material 3 Expressive</p>
          <h1 className="text-3xl font-semibold text-[#f5eff7]">Login</h1>
          <p className="mt-2 text-sm text-[#cac4d0]">Melde dich mit Email und Passwort an. User werden vom Admin erstellt.</p>
          <form
            className="mt-6"
            onSubmit={(e) => {
              e.preventDefault();
              void login();
            }}
          >
            <input
              className="w-full rounded-2xl border border-[#4a4458] bg-[#2b2930] px-4 py-3 text-[#e6e0e9] outline-none ring-0 placeholder:text-[#938f99] focus:border-[#d0bcff]"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Email"
              autoComplete="email"
            />
            <input
              className="mt-3 w-full rounded-2xl border border-[#4a4458] bg-[#2b2930] px-4 py-3 text-[#e6e0e9] outline-none ring-0 placeholder:text-[#938f99] focus:border-[#d0bcff]"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Passwort"
              autoComplete="current-password"
            />
            <div className="mt-4 flex flex-wrap gap-3">
              <button
                type="submit"
                className="rounded-full border border-[#4a4458] bg-[#332d41] px-5 py-2 text-sm font-semibold text-[#e8def8] transition hover:bg-[#3c3650]"
              >
                Einloggen
              </button>
            </div>
          </form>
          <div className="mt-4">{loading ? <NeonLoader /> : null}</div>
          {authMessage ? <div className="mt-3 rounded-xl border border-[#4a4458] bg-[#2b2930] px-3 py-2 text-sm text-[#e6e0e9]">{authMessage}</div> : null}
          {playbackDebug ? (
            <pre className="mt-2 max-h-44 overflow-auto rounded-xl border border-[#4a4458] bg-[#16131d] px-3 py-2 text-[11px] text-[#d9d1e5]">
              {playbackDebug}
            </pre>
          ) : null}
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell
      title="Musicrr"
      headerRight={
        !isAnonymousShareMode ? (
          <button className="panel-icon-btn" title="Logout" aria-label="Logout" onClick={logout}>
            <IconBase>
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <path d="M16 17l5-5-5-5" />
              <path d="M21 12H9" />
            </IconBase>
          </button>
        ) : null
      }
    >
      <div className="grid gap-4 pb-44 md:gap-5 md:pb-40">
        <section className="rounded-[24px] border border-[#4a445866] bg-[#211f26cc] p-3 shadow-xl sm:rounded-[28px] sm:p-5">
          <div className="mb-4 flex flex-wrap justify-center gap-2">
            {tabs.map((value) => (
              <button
                key={value}
                className={`rounded-full px-4 py-2 text-sm font-medium capitalize transition ${
                  tab === value ? "bg-[#eaddff] text-[#21005d]" : "border border-[#4a4458] bg-[#2b2930] text-[#e6e0e9]"
                }`}
                onClick={() => setTab(value)}
              >
                {value}
              </button>
            ))}
          </div>
          <div className="mb-4 grid grid-cols-3 gap-2 sm:flex sm:flex-wrap sm:items-center sm:gap-2 sm:overflow-x-visible sm:pb-1">
            <input
              className="col-span-3 w-full min-w-0 flex-1 rounded-2xl border border-[#4a4458] bg-[#2b2930] px-4 py-2 text-sm text-[#e6e0e9] placeholder:text-[#938f99] outline-none focus:border-[#d0bcff] sm:min-w-[220px]"
              value={query}
              onChange={(e) => searchTracks(e.target.value)}
              placeholder="Suche nach Track, Artist, Album"
            />
            <input
              className="col-span-3 w-full min-w-0 rounded-2xl border border-[#4a4458] bg-[#2b2930] px-4 py-2 text-sm text-[#e6e0e9] placeholder:text-[#938f99] outline-none focus:border-[#d0bcff] sm:min-w-[180px] sm:w-auto"
              value={importTitle}
              onChange={(e) => setImportTitle(e.target.value)}
              placeholder="Import Titel (optional)"
            />

            <div className="relative justify-self-center sm:justify-self-auto">
              <button
                className={`panel-icon-btn h-10 min-w-10 px-0 sm:h-auto sm:min-w-[40px] sm:px-[10px] ${isEditMode ? "panel-icon-btn-active" : ""}`}
                title={isEditMode ? "Edit Mode beenden" : "Edit Mode"}
                aria-label={isEditMode ? "Edit Mode beenden" : "Edit Mode"}
                onClick={() => {
                  setIsEditMode((v) => {
                    if (v) setSelectedTrackIds([]);
                    return !v;
                  });
                }}
              >
                <IconBase>
                  <rect x="5" y="4" width="10" height="14" rx="2" />
                  <path d="M8 8h4" />
                  <path d="M8 11h4" />
                  <path d="M14.5 15.5l4-4 1.5 1.5-4 4-2 .5z" />
                </IconBase>
              </button>
            </div>

            <div className="relative justify-self-center sm:justify-self-auto">
              <button
                ref={importMenuTriggerRef}
                type="button"
                className="panel-icon-btn h-10 min-w-10 px-0 sm:h-auto sm:min-w-[40px] sm:px-[10px]"
                title="Import"
                aria-label="Import"
                aria-expanded={isImportMenuOpen}
                onClick={() => setIsImportMenuOpen((v) => !v)}
              >
                <IconBase>
                  <path d="M12 3v12" />
                  <path d="M8 11l4 4 4-4" />
                  <path d="M4 19h16" />
                </IconBase>
              </button>
              {isImportMenuOpen ? (
                <div
                  ref={importMenuRef}
                  className="absolute left-0 top-full z-20 mt-2 w-56 rounded-2xl border border-white/15 bg-[#1c1826e0] p-2 shadow-xl backdrop-blur-2xl"
                >
                  <button
                    type="button"
                    className="mb-1 w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-left text-sm text-[#e6e0e9] hover:bg-white/15"
                    onClick={() => void importFromFiles()}
                  >
                    Dateien wählen…
                  </button>
                  <button
                    type="button"
                    className="w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-left text-sm text-[#e6e0e9] hover:bg-white/15"
                    onClick={() => void importFromFolder()}
                  >
                    Ordner (rekursiv)…
                  </button>
                </div>
              ) : null}
            </div>

            <div className="relative justify-self-center sm:justify-self-auto">
              <button
                ref={filterMenuTriggerRef}
                className="panel-icon-btn h-10 min-w-10 px-0 sm:h-auto sm:min-w-[40px] sm:px-[10px]"
                title="Filter Optionen"
                aria-label="Filter Optionen"
                onClick={() => setIsFilterMenuOpen((v) => !v)}
              >
                <IconBase>
                  <path d="M4 6h16" />
                  <path d="M7 12h10" />
                  <path d="M10 18h4" />
                </IconBase>
              </button>
              {isFilterMenuOpen ? (
                <div ref={filterMenuRef} className="absolute right-0 top-full z-20 mt-2 w-56 rounded-2xl border border-white/15 bg-[#1c1826e0] p-2 shadow-xl backdrop-blur-2xl">
                  <select
                    className="mb-2 w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-sm text-[#e6e0e9]"
                    value={sortBy}
                    onChange={(e) => setSortBy(e.target.value as "title" | "artist" | "duration")}
                    style={{ colorScheme: "dark" }}
                  >
                    <option value="title" style={{ backgroundColor: "#1a1622", color: "#f5eff7" }}>Sort: Title</option>
                    <option value="artist" style={{ backgroundColor: "#1a1622", color: "#f5eff7" }}>Sort: Artist</option>
                    <option value="duration" style={{ backgroundColor: "#1a1622", color: "#f5eff7" }}>Sort: Duration</option>
                  </select>
                  <button
                    className="mb-2 w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-sm text-[#e6e0e9]"
                    onClick={() => setSortDir((d) => (d === "asc" ? "desc" : "asc"))}
                  >
                    Direction: {sortDir === "asc" ? "Asc" : "Desc"}
                  </button>
                  <button className="w-full rounded-xl bg-[#7d5260] px-3 py-2 text-sm font-medium text-[#f5eff7]" onClick={deleteSelectedTracks}>
                    Ausgewaehlte loeschen
                  </button>
                </div>
              ) : null}
            </div>

          </div>

          {isEditMode ? (
            <div className="mb-4 grid grid-cols-1 gap-2 sm:flex sm:flex-wrap sm:items-center sm:gap-2 sm:overflow-x-visible sm:pb-1">
              <input
                className="w-full min-w-0 rounded-2xl border border-[#4a4458] bg-[#2b2930] px-4 py-2 text-sm text-[#e6e0e9] placeholder:text-[#938f99] outline-none focus:border-[#d0bcff] sm:min-w-[180px] sm:w-auto"
                value={playlistName}
                onChange={(e) => setPlaylistName(e.target.value)}
                placeholder="Playlist Name"
              />
              <button
                className="rounded-full border border-[#4a4458] bg-[#2b2930] px-4 py-2 text-sm font-medium text-[#f5eff7] hover:bg-[#36303e]"
                onClick={createPlaylistFromSelection}
              >
                Zur Playlist
              </button>
              <button
                className="rounded-full bg-[#7d5260] px-4 py-2 text-sm font-medium text-[#f5eff7] hover:brightness-110"
                onClick={deleteSelectedTracks}
              >
                Auswahl loeschen
              </button>
              <div className="rounded-full border border-[#4a4458] bg-[#2b2930] px-3 py-2 text-xs text-[#cac4d0]">
                {selectedTrackIds.length} ausgewaehlt
              </div>
            </div>
          ) : null}

          {isAdmin ? (
            <div className="mb-4 rounded-2xl border border-[#4a4458] bg-[#2b2930] p-3">
              <div className="mb-2 text-xs uppercase tracking-[0.14em] text-[#cac4d0]">Admin: User erstellen</div>
              <div className="flex flex-wrap gap-2">
                <input
                  className="min-w-[180px] flex-1 rounded-xl border border-[#4a4458] bg-[#1f1b24] px-3 py-2 text-sm text-[#e6e0e9]"
                  placeholder="Email"
                  value={newUserEmail}
                  onChange={(e) => setNewUserEmail(e.target.value)}
                />
                <input
                  className="min-w-[180px] flex-1 rounded-xl border border-[#4a4458] bg-[#1f1b24] px-3 py-2 text-sm text-[#e6e0e9]"
                  placeholder="Passwort"
                  type="password"
                  value={newUserPassword}
                  onChange={(e) => setNewUserPassword(e.target.value)}
                />
                <input
                  className="min-w-[150px] flex-1 rounded-xl border border-[#4a4458] bg-[#1f1b24] px-3 py-2 text-sm text-[#e6e0e9]"
                  placeholder="Name (optional)"
                  value={newUserName}
                  onChange={(e) => setNewUserName(e.target.value)}
                />
                <label className="inline-flex items-center gap-2 rounded-xl border border-[#4a4458] bg-[#1f1b24] px-3 py-2 text-sm text-[#e6e0e9]">
                  <input type="checkbox" checked={newUserIsAdmin} onChange={(e) => setNewUserIsAdmin(e.target.checked)} />
                  Admin
                </label>
                <button className="rounded-xl bg-[#6750a4] px-4 py-2 text-sm font-medium text-[#f5eff7]" onClick={createUserAsAdmin}>
                  User erstellen
                </button>
              </div>
            </div>
          ) : null}
          <input
            ref={fileInputRef}
            type="file"
            accept="audio/*"
            multiple
            className="hidden"
            onChange={(e) => {
              void importLocalFiles(e.target.files);
              e.target.value = "";
            }}
          />
          <input
            ref={folderInputRef}
            type="file"
            // eslint-disable-next-line @typescript-eslint/no-explicit-any -- non-standard: directory picker in Chromium
            {...({ webkitdirectory: true } as any)}
            multiple
            className="hidden"
            onChange={(e) => {
              const list = e.target.files;
              e.target.value = "";
              if (!list || list.length === 0) return;
              const audio = Array.from(list).filter((f) => isLikelyAudioFile(f));
              if (audio.length === 0) {
                setImportProgress("keine Audiodateien im Ordner");
                return;
              }
              void importLocalFiles(audio);
            }}
          />
          {tab === "tracks" && (
            <div className="mx-auto w-full max-w-4xl space-y-2">
              {sortedTracks.map((track, idx) => (
                <div
                  key={track.id}
                  className={`flex items-start gap-2 rounded-2xl border px-2 py-2 transition sm:items-center sm:gap-3 sm:px-3 ${
                    selectedTrackIds.includes(track.id) && isEditMode
                      ? "border-[#d0bcff] bg-[#3a314b]"
                      : "border-[#4a4458] bg-[#2b2930] hover:bg-[#36303e]"
                  }`}
                >
                  {isEditMode ? (
                    <button
                      className={`h-5 w-5 rounded-md border ${
                        selectedTrackIds.includes(track.id) ? "border-[#d0bcff] bg-[#d0bcff]" : "border-[#938f99] bg-transparent"
                      }`}
                      onClick={() => toggleTrackSelection(track.id)}
                      aria-label={selectedTrackIds.includes(track.id) ? "Auswahl entfernen" : "Auswaehlen"}
                    >
                      {selectedTrackIds.includes(track.id) ? <span className="block text-[10px] leading-none text-[#2b2930]">✓</span> : null}
                    </button>
                  ) : null}
                  <button
                    className="flex min-w-0 flex-1 items-center justify-between gap-2 text-left"
                    onClick={() => {
                      if (isEditMode) {
                        toggleTrackSelection(track.id);
                        return;
                      }
                      play(idx);
                    }}
                  >
                    <span className="flex min-w-0 items-center gap-2">
                        <img
                          src={track.cover_path ? murl(`/media/track/${track.id}/cover`) : undefined}
                        alt=""
                        className="h-8 w-8 rounded-md border border-[#4a4458] bg-[#1f1b24] object-cover"
                        style={{ visibility: track.cover_path ? "visible" : "hidden" }}
                      />
                      {editingTrackId === track.id ? (
                        <input
                          className="rounded-lg border border-[#4a4458] bg-[#1f1b24] px-2 py-1 text-sm text-[#f5eff7]"
                          value={editingTrackTitle}
                          onChange={(e) => setEditingTrackTitle(e.target.value)}
                        />
                      ) : (
                        <span className="min-w-0 truncate text-sm text-[#f5eff7]">
                          <span className="font-medium">{track.title}</span>
                          <span className="text-[#cac4d0]"> - {track.artist}</span>
                        </span>
                      )}
                    </span>
                    <span className="shrink-0 text-[11px] text-[#938f99] sm:text-xs">{track.duration_sec}s</span>
                  </button>
                  {!isEditMode && editingTrackId === track.id ? (
                    <button
                      className="rounded-full border border-[#4a4458] bg-[#1f1b24] px-3 py-1 text-xs text-[#e6e0e9]"
                      onClick={() => saveTrackEdit(track)}
                    >
                      Save
                    </button>
                  ) : !isEditMode ? (
                    <div className="relative">
                      <button
                        className="panel-icon-btn h-8 min-w-8 px-2"
                        onPointerDown={(e) => e.stopPropagation()}
                        onClick={() => setOpenTrackMenuId((prev) => (prev === track.id ? null : track.id))}
                        title="Song Aktionen"
                        aria-label="Song Aktionen"
                      >
                        <IconBase>
                          <circle cx="6" cy="12" r="1.6" />
                          <circle cx="12" cy="12" r="1.6" />
                          <circle cx="18" cy="12" r="1.6" />
                        </IconBase>
                      </button>
                      {openTrackMenuId === track.id ? (
                        <div
                          className="absolute right-0 top-full z-50 mt-2 w-56 rounded-2xl border border-white/15 bg-[#1c1826e0] p-2 shadow-xl backdrop-blur-2xl"
                          onPointerDown={(e) => e.stopPropagation()}
                        >
                          <button className="mb-1 w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-left text-xs text-[#f5eff7]" onClick={() => createPlaylistWithTrack(track)}>
                            Create Playlist with this Song
                          </button>
                          <button className="mb-1 w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-left text-xs text-[#f5eff7]" onClick={() => addTrackToPlaylist(track)}>
                            Add Song to a Playlist
                          </button>
                          <button className="mb-1 w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-left text-xs text-[#f5eff7]" onClick={() => removeTrack(track)}>
                            Remove Song
                          </button>
                          <button className="mb-1 w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-left text-xs text-[#f5eff7]" onClick={() => shareTrack(track)}>
                            Share Song
                          </button>
                          <button className="mb-1 w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-left text-xs text-[#f5eff7]" onClick={() => viewTrackInfo(track)}>
                            View Song information (Metadata)
                          </button>
                          <button className="w-full rounded-xl border border-white/15 bg-white/10 px-3 py-2 text-left text-xs text-[#f5eff7]" onClick={() => toggleFavorite(track)}>
                            {track.is_favorite ? "Remove from Favorites" : "Add to Favorites"}
                          </button>
                        </div>
                      ) : null}
                    </div>
                  ) : null}
                </div>
              ))}
            </div>
          )}

          {tab === "artists" && (
            selectedArtist ? (
              <div className="mx-auto w-full max-w-3xl space-y-2">
                <div className="mb-1 flex items-center justify-between rounded-xl border border-[#4a4458] bg-[#2b2930] px-3 py-2">
                  <span className="truncate text-sm font-semibold text-[#f5eff7]">{selectedArtist}</span>
                  <button
                    className="rounded-full border border-[#4a4458] bg-[#1f1b24] px-3 py-1 text-xs text-[#e6e0e9]"
                    onClick={() => setSelectedArtist(null)}
                  >
                    Zur Liste
                  </button>
                </div>
                {artistTracks.map((track, idx) => (
                  <button
                    key={track.id}
                    className="flex w-full items-center justify-between rounded-xl border border-[#4a4458] bg-[#2b2930] px-3 py-2 text-left hover:bg-[#36303e]"
                    onClick={() => play(sortedTracks.findIndex((t) => t.id === track.id) >= 0 ? sortedTracks.findIndex((t) => t.id === track.id) : idx)}
                  >
                    <span className="min-w-0 truncate text-sm text-[#f5eff7]">{track.title}</span>
                    <span className="shrink-0 text-xs text-[#938f99]">{track.duration_sec}s</span>
                  </button>
                ))}
              </div>
            ) : (
              artists.map((artist) => (
                <button
                  key={artist.name}
                  className="mx-auto flex w-full max-w-3xl items-center gap-3 rounded-xl border border-[#4a4458] bg-[#2b2930] px-3 py-2 text-left hover:bg-[#36303e]"
                  onClick={() => openArtistPage(artist.name)}
                >
                  <img
                    src={artist.coverTrackId ? murl(`/media/track/${artist.coverTrackId}/cover`) : undefined}
                    alt=""
                    className="h-10 w-10 rounded-full border border-[#4a4458] bg-[#1f1b24] object-cover"
                    style={{ visibility: artist.coverTrackId ? "visible" : "hidden" }}
                  />
                  <span className="truncate text-sm text-[#f5eff7]">{artist.name}</span>
                </button>
              ))
            )
          )}
          {tab === "albums" && (
            selectedAlbum ? (
              <div className="mx-auto w-full max-w-3xl space-y-2">
                <div className="mb-1 flex items-center justify-between rounded-xl border border-[#4a4458] bg-[#2b2930] px-3 py-2">
                  <span className="truncate text-sm font-semibold text-[#f5eff7]">{selectedAlbum}</span>
                  <button
                    className="rounded-full border border-[#4a4458] bg-[#1f1b24] px-3 py-1 text-xs text-[#e6e0e9]"
                    onClick={() => setSelectedAlbum(null)}
                  >
                    Zur Liste
                  </button>
                </div>
                {albumTracks.map((track, idx) => (
                  <button
                    key={track.id}
                    className="flex w-full items-center justify-between rounded-xl border border-[#4a4458] bg-[#2b2930] px-3 py-2 text-left hover:bg-[#36303e]"
                    onClick={() => play(sortedTracks.findIndex((t) => t.id === track.id) >= 0 ? sortedTracks.findIndex((t) => t.id === track.id) : idx)}
                  >
                    <span className="min-w-0 truncate text-sm text-[#f5eff7]">{track.title}</span>
                    <span className="shrink-0 text-xs text-[#938f99]">{track.duration_sec}s</span>
                  </button>
                ))}
              </div>
            ) : (
              albums.map((album) => (
                <button
                  key={album.name}
                  className="mx-auto flex w-full max-w-3xl items-center gap-3 rounded-xl border border-[#4a4458] bg-[#2b2930] px-3 py-2 text-left hover:bg-[#36303e]"
                  onClick={() => openAlbumPage(album.name)}
                >
                  <img
                    src={album.coverTrackId ? murl(`/media/track/${album.coverTrackId}/cover`) : undefined}
                    alt=""
                    className="h-10 w-10 rounded-lg border border-[#4a4458] bg-[#1f1b24] object-cover"
                    style={{ visibility: album.coverTrackId ? "visible" : "hidden" }}
                  />
                  <span className="truncate text-sm text-[#f5eff7]">{album.name}</span>
                </button>
              ))
            )
          )}
          {tab === "playlists" && (
            <div className="mx-auto w-full max-w-3xl space-y-3">
              <div className="grid grid-cols-1 gap-2 sm:flex">
                <input
                  className="flex-1 rounded-2xl border border-[#4a4458] bg-[#2b2930] px-4 py-2 text-sm text-[#e6e0e9] placeholder:text-[#938f99] outline-none focus:border-[#d0bcff]"
                  value={playlistName}
                  onChange={(e) => setPlaylistName(e.target.value)}
                  placeholder="Neue Playlist"
                />
                <button className="rounded-full bg-[#7d5260] px-4 py-2 text-sm font-medium text-[#f5eff7]" onClick={createPlaylistFromSelection}>
                  Aus Auswahl erstellen
                </button>
              </div>
              {playlists.map((playlist) => (
                <div key={playlist.id} className="flex items-center justify-between rounded-2xl border border-[#4a4458] bg-[#2b2930] p-3 text-[#f5eff7]">
                  <span>{playlist.name}</span>
                  <button
                    className="rounded-full border border-[#4a4458] bg-[#1f1b24] px-3 py-1 text-xs text-[#e6e0e9]"
                    onClick={() => deletePlaylist(playlist.id)}
                  >
                    Delete
                  </button>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      <footer className="fixed inset-x-2 bottom-3 z-30 rounded-[20px] border border-white/15 bg-white/8 p-2 pb-[calc(0.75rem+env(safe-area-inset-bottom))] shadow-2xl backdrop-blur-2xl sm:inset-x-4 sm:bottom-5 sm:rounded-[24px] sm:p-3 md:inset-x-6">
        <div className="grid gap-2 sm:grid-cols-[auto_1fr_auto] sm:items-center">
          <button className="flex items-center gap-3 text-left" onClick={() => setIsPlayerExpanded(true)}>
            <img
              src={activeTrack?.cover_path ? murl(`/media/track/${activeTrack.id}/cover`) : undefined}
              alt=""
              className={`h-11 w-11 rounded-xl border border-[#4a4458] bg-gradient-to-br from-[#d0bcff] via-[#7d5260] to-[#4f378b] object-cover sm:h-14 sm:w-14 sm:rounded-2xl ${
                isPlaying ? "animate-pulse" : ""
              }`}
              style={{ visibility: activeTrack?.cover_path ? "visible" : "hidden" }}
            />
            <div className="min-w-0">
              <div className="truncate text-sm font-semibold text-[#f5eff7]">{activeTrack?.title ?? "Nichts abgespielt"}</div>
              <div className="truncate text-xs text-[#cac4d0]">{activeTrack?.artist ?? "Kein Artist"}</div>
            </div>
          </button>

          <div className="space-y-1 md:min-w-0">
            <div
              role="slider"
              aria-label="Song progress"
              aria-valuemin={0}
              aria-valuemax={Math.floor(duration > 0 ? duration : (activeTrack?.duration_sec ?? 0))}
              aria-valuenow={Math.floor(currentTime)}
                    className="relative h-10 w-full cursor-pointer select-none overflow-hidden rounded-2xl border border-[#4a4458] bg-[#1f1b24] px-2 py-1 sm:h-11"
              onClick={(e) => {
                const rect = e.currentTarget.getBoundingClientRect();
                const ratio = (e.clientX - rect.left) / rect.width;
                seekTo(Math.max(0, Math.min(1, ratio)));
              }}
              onPointerDown={(e) => {
                      const el = e.currentTarget;
                      const applySeek = (clientX: number) => {
                        const rect = el.getBoundingClientRect();
                        const ratio = (clientX - rect.left) / rect.width;
                        seekTo(Math.max(0, Math.min(1, ratio)));
                      };
                      applySeek(e.clientX);
                      el.setPointerCapture(e.pointerId);
                      const onMove = (ev: PointerEvent) => applySeek(ev.clientX);
                      const onUp = (ev: PointerEvent) => {
                        applySeek(ev.clientX);
                        el.releasePointerCapture(e.pointerId);
                        el.removeEventListener("pointermove", onMove);
                        el.removeEventListener("pointerup", onUp);
                        el.removeEventListener("pointercancel", onUp);
                      };
                      el.addEventListener("pointermove", onMove);
                      el.addEventListener("pointerup", onUp);
                      el.addEventListener("pointercancel", onUp);
              }}
            >
              <div className="absolute inset-y-0 left-0 rounded-r-xl bg-gradient-to-r from-[#d0bcff2b] to-[#7d526033]" style={{ width: `${progressRatio * 100}%` }} />
              <div className="grid h-full grid-flow-col auto-cols-fr items-end gap-[2px]">
                {waveBars.map((bar) => {
                  const barRatio = bar / (waveBars.length - 1);
                  const isPassed = barRatio <= progressRatio;
                  const staticShape = Math.sin((bar / waveBars.length) * Math.PI * 3.2);
                  const baseHeight = 8 + Math.max(0, staticShape) * 10;
                  return (
                    <span
                      key={bar}
                      className={`wave-bar ${isPlaying && isPassed ? "wave-animate" : ""} ${isPassed ? "wave-passed" : "wave-pending"}`}
                      style={{
                        height: `${baseHeight}px`,
                        animationDelay: `${bar * 26}ms`
                      }}
                    />
                  );
                })}
              </div>
            </div>
            <div className="flex items-center justify-between text-[11px] text-[#938f99]">
              <span>{formatTime(currentTime)}</span>
              <span>{formatTime(duration)}</span>
            </div>
          </div>

          <div className="flex flex-wrap items-center justify-center gap-2 md:justify-end">
            <IconButton title="Previous" onClick={previous}>
              <IconBase>
                <path d="M6 6v12" />
                <path d="M9 12l9 6V6z" />
              </IconBase>
            </IconButton>
            <IconButton title="-10 seconds" onClick={() => skip(-10)}>
              <IconBase>
                <path d="M10 4L6 8l4 4" />
                <path d="M6 8h5a7 7 0 1 1-6.6 9.3" />
              </IconBase>
            </IconButton>
            <IconButton title="Play/Pause" onClick={() => (isPlaying ? pause() : resumePlayback())} primary>
              {isPlaying ? (
                <IconBase>
                  <path d="M8 6v12" />
                  <path d="M16 6v12" />
                </IconBase>
              ) : (
                <IconBase>
                  <path d="M8 5v14l11-7z" />
                </IconBase>
              )}
            </IconButton>
            <IconButton title="Stop" onClick={stop}>
              <IconBase>
                <rect x="7" y="7" width="10" height="10" />
              </IconBase>
            </IconButton>
            <IconButton title="+10 seconds" onClick={() => skip(10)}>
              <IconBase>
                <path d="M14 4l4 4-4 4" />
                <path d="M18 8h-5a7 7 0 1 0 6.6 9.3" />
              </IconBase>
            </IconButton>
            <IconButton title="Next" onClick={next}>
              <IconBase>
                <path d="M18 6v12" />
                <path d="M15 12L6 6v12z" />
              </IconBase>
            </IconButton>
            <IconButton title="Shuffle" onClick={() => queue.toggleShuffle()}>
              <IconBase>
                <path d="M3 7h3a4 4 0 0 1 3.2 1.6l5.6 6.8A4 4 0 0 0 18 17h3" />
                <path d="M21 7h-3a4 4 0 0 0-3.2 1.6l-1 1.2" />
                <path d="M3 17h3a4 4 0 0 0 3.2-1.6l1-1.2" />
              </IconBase>
            </IconButton>
          </div>
        </div>
        <audio ref={audioRef} className="hidden" crossOrigin="anonymous" preload="auto" />
        {authMessage ? <div className="mt-2 text-xs text-[#ffb4ab]">{authMessage}</div> : null}
        {playbackDebug ? (
          <pre className="mt-2 max-h-36 overflow-auto rounded-xl border border-[#4a445866] bg-[#17141f] px-3 py-2 text-[10px] text-[#d7cfe3]">
            {playbackDebug}
          </pre>
        ) : null}
      </footer>

      {isPlayerExpanded && (
        <div
          className="player-morph-shell fixed inset-0 z-40 overflow-hidden bg-[#0d0a12]"
          style={
            {
              "--accent-a": accentA,
              "--accent-b": accentB,
              "--accent-c": accentC,
              "--music-energy": (isBeatReactive ? audioEnergy : 0.22).toString()
            } as React.CSSProperties
          }
        >
          {playerViewMode === "gradient" ? (
            <div className="player-gradient-layer player-layer-visible">
              <div className="player-gradient-blob player-gradient-blob-a" style={{ backgroundColor: accentA }} />
              <div className="player-gradient-blob player-gradient-blob-b" style={{ backgroundColor: accentB }} />
              <div className="player-gradient-blob player-gradient-blob-c" style={{ backgroundColor: accentC }} />
              <div className={`gradient-visualizer-full ${isPlaying ? "gradient-visualizer-active" : ""}`}>
                <div className="gradient-aurora gradient-aurora-a" />
                <div className="gradient-aurora gradient-aurora-b" />
                <div className="gradient-aurora gradient-aurora-c" />
                {auroraOrbs.map((orb, idx) => (
                  <span
                    key={orb.id}
                    className="gradient-orb"
                    style={
                      {
                        "--orb-left": orb.left,
                        "--orb-top": orb.top,
                        "--orb-size": orb.size,
                        "--orb-duration": orb.duration,
                        "--orb-delay": orb.delay,
                        "--orb-color": idx % 3 === 0 ? accentA : idx % 3 === 1 ? accentB : accentC
                      } as React.CSSProperties
                    }
                  />
                ))}
              </div>
            </div>
          ) : (
            <div className="player-visual-layer player-layer-visible">
              <canvas ref={canvasRef} className="h-full w-full" />
            </div>
          )}
          <div className={`player-overlay-layer absolute inset-0 ${playerViewMode === "visualizer" ? "bg-[#09070b55]" : "bg-[#0d0a1270]"}`} />

          <button
            className="player-btn absolute right-4 top-4 z-30 px-3 sm:right-5 sm:top-5 md:right-6 md:top-6"
            aria-label="Vollbildplayer schliessen"
            onClick={() => {
              setIsPlayerExpanded(false);
              setIsLyricsOpen(false);
              setIsFullscreenMenuOpen(false);
            }}
          >
            <IconBase>
              <path d="M6 6l12 12" />
              <path d="M18 6L6 18" />
            </IconBase>
          </button>

          <div className="relative z-10 mx-auto grid h-full max-w-6xl gap-4 overflow-y-auto px-3 pb-[calc(1.25rem+env(safe-area-inset-bottom))] pt-[72px] min-[560px]:grid-cols-[minmax(160px,240px)_1fr] min-[560px]:items-center min-[560px]:gap-4 min-[560px]:overflow-hidden min-[560px]:px-3 min-[560px]:pb-3 min-[560px]:pt-[80px] md:gap-5 md:px-4 md:pb-4 md:pt-[88px] lg:grid-cols-[minmax(220px,320px)_1fr] lg:gap-8 lg:p-8">
            <section className="flex min-h-0 flex-col overflow-hidden rounded-[24px] border border-white/15 bg-white/5 p-3 backdrop-blur-2xl min-[560px]:rounded-[24px] min-[560px]:p-3 md:rounded-[28px] md:p-3.5 lg:p-4">
              <img
                src={activeTrack?.cover_path ? murl(`/media/track/${activeTrack.id}/cover`) : undefined}
                alt=""
                className="mx-auto aspect-square w-full max-w-full max-h-[calc(100%-5.75rem)] rounded-[20px] border border-[#8f7ec555] bg-gradient-to-br from-[#d0bcff] via-[#7d5260] to-[#4f378b] object-cover shadow-2xl"
                style={{ visibility: activeTrack?.cover_path ? "visible" : "hidden" }}
              />
              <div className="mt-3 flex min-h-[4.75rem] min-w-0 flex-1 flex-col justify-center overflow-hidden px-1">
                <div className="truncate text-center text-xl font-semibold text-[#f5eff7]">{activeTrack?.title ?? "Nichts abgespielt"}</div>
                <button
                  className="mx-auto mt-0.5 block max-w-full truncate px-1 text-center text-sm text-[#d1c9dc] underline-offset-2 hover:underline"
                  onClick={() => {
                    if (activeTrack?.artist) openArtistPage(activeTrack.artist);
                    setIsPlayerExpanded(false);
                  }}
                >
                  {activeTrack?.artist ?? "Kein Artist"}
                </button>
              </div>
            </section>

            <section className="relative -translate-y-1 flex min-h-0 flex-col rounded-[24px] border border-white/15 bg-white/5 p-3 backdrop-blur-2xl min-[560px]:translate-y-0 min-[560px]:max-h-[72vh] min-[560px]:overflow-y-auto min-[560px]:rounded-[24px] min-[560px]:p-3 md:max-h-[70vh] md:rounded-[28px] md:p-4 lg:max-h-[78vh]">
              <div className="flex h-full min-h-0 flex-col gap-2.5 md:gap-3">
              <div className="space-y-1.5 min-[560px]:space-y-2">
                <div
                  role="slider"
                  aria-label="Song progress expanded"
                  aria-valuemin={0}
                  aria-valuemax={Math.floor(duration > 0 ? duration : (activeTrack?.duration_sec ?? 0))}
                  aria-valuenow={Math.floor(currentTime)}
                  className="glass-progress relative h-[clamp(2.75rem,8vh,4.75rem)] w-full cursor-pointer select-none overflow-hidden rounded-2xl border border-white/15 bg-white/5 px-2 py-1 backdrop-blur-2xl sm:h-[clamp(3rem,7vh,4.75rem)]"
                  onClick={(e) => {
                    const rect = e.currentTarget.getBoundingClientRect();
                    const ratio = (e.clientX - rect.left) / rect.width;
                    seekTo(Math.max(0, Math.min(1, ratio)));
                  }}
                >
                  <div className="absolute inset-y-0 left-0 rounded-r-xl bg-white/8 backdrop-blur-xl" style={{ width: `${progressRatio * 100}%` }} />
                  <div className="grid h-full grid-flow-col auto-cols-fr items-end gap-[2px]">
                    {waveBars.map((bar) => {
                      const barRatio = bar / (waveBars.length - 1);
                      const isPassed = barRatio <= progressRatio;
                      const staticShape = Math.sin((bar / waveBars.length) * Math.PI * 3.2);
                      const baseHeight = 8 + Math.max(0, staticShape) * 10;
                      return (
                        <span
                          key={`expanded-${bar}`}
                          className={`wave-bar ${isPlaying && isPassed ? "wave-animate" : ""} ${isPassed ? "wave-passed" : "wave-pending"}`}
                          style={{
                            height: `${baseHeight}px`,
                            animationDelay: `${bar * 26}ms`
                          }}
                        />
                      );
                    })}
                  </div>
                </div>
                <div className="flex items-center justify-between text-xs text-[#b7afc2]">
                  <span>{formatTime(currentTime)}</span>
                  <span>{formatTime(duration)}</span>
                </div>
              </div>

              <div className="relative flex flex-wrap items-center justify-center gap-1.5 min-[560px]:gap-2">
                <IconButton title="Previous" onClick={previous}>
                  <IconBase>
                    <path d="M6 6v12" />
                    <path d="M9 12l9 6V6z" />
                  </IconBase>
                </IconButton>
                <IconButton title="Play/Pause" onClick={() => (isPlaying ? pause() : resumePlayback())} primary>
                  {isPlaying ? (
                    <IconBase>
                      <path d="M8 6v12" />
                      <path d="M16 6v12" />
                    </IconBase>
                  ) : (
                    <IconBase>
                      <path d="M8 5v14l11-7z" />
                    </IconBase>
                  )}
                </IconButton>
                <IconButton title="Next" onClick={next}>
                  <IconBase>
                    <path d="M18 6v12" />
                    <path d="M15 12L6 6v12z" />
                  </IconBase>
                </IconButton>
                <button
                  ref={moreMenuTriggerRef}
                  className="player-btn px-3"
                  title="Mehr Optionen"
                  aria-label="Mehr Optionen"
                  onClick={() => setIsFullscreenMenuOpen((v) => !v)}
                >
                  <IconBase>
                    <circle cx="6" cy="12" r="1.6" />
                    <circle cx="12" cy="12" r="1.6" />
                    <circle cx="18" cy="12" r="1.6" />
                  </IconBase>
                </button>

                {isFullscreenMenuOpen ? (
                  <div
                    ref={moreMenuRef}
                    className="fullscreen-more-menu absolute bottom-full left-1/2 z-40 mb-2 w-fit min-w-[142px] -translate-x-1/2 overflow-hidden rounded-2xl p-2 sm:bottom-auto sm:top-full sm:mb-0 sm:mt-2"
                  >
                    <span
                      aria-hidden
                      className="pointer-events-none absolute inset-0"
                      style={{
                        background:
                          "radial-gradient(circle at 20% 20%, color-mix(in srgb, var(--accent-a) 30%, transparent) 0%, transparent 62%), radial-gradient(circle at 80% 70%, color-mix(in srgb, var(--accent-b) 26%, transparent) 0%, transparent 64%), radial-gradient(circle at 50% 50%, color-mix(in srgb, var(--accent-c) 18%, transparent) 0%, transparent 70%)",
                        filter: "blur(16px)",
                        opacity: 0.52
                      }}
                    />
                    <span aria-hidden className="fullscreen-more-frost pointer-events-none absolute inset-0" />
                    <div className="mb-1.5 flex items-center justify-center gap-1.5">
                      <button
                        className="fullscreen-more-btn relative h-9 min-w-9 rounded-full px-2 text-[#f5eff7]"
                        title={playerViewMode === "gradient" ? "Visualizer anzeigen" : "Gradient anzeigen"}
                        aria-label={playerViewMode === "gradient" ? "Visualizer anzeigen" : "Gradient anzeigen"}
                        onClick={() => {
                          setPlayerViewMode((current) => (current === "gradient" ? "visualizer" : "gradient"));
                          setIsFullscreenMenuOpen(false);
                        }}
                      >
                        <IconBase>
                          <path d="M4 6h16v12H4z" />
                          <path d="M8 10h2v4H8zM12 8h2v8h-2zM16 11h2v2h-2z" />
                        </IconBase>
                      </button>
                      <button
                        className="fullscreen-more-btn relative h-9 min-w-9 rounded-full px-2 text-[#f5eff7]"
                        title="Lyrics"
                        aria-label="Lyrics"
                        onClick={() => {
                          setIsLyricsOpen(true);
                          setIsFullscreenMenuOpen(false);
                        }}
                      >
                        <IconBase>
                          <path d="M6 4h12" />
                          <path d="M6 9h12" />
                          <path d="M6 14h7" />
                          <path d="M6 19h5" />
                        </IconBase>
                      </button>
                      <button
                        className={`fullscreen-more-btn relative h-9 min-w-9 rounded-full px-2 text-[#f5eff7] ${
                          isBeatReactive ? "fullscreen-more-btn-active" : ""
                        }`}
                        title={isBeatReactive ? "Beat FX deaktivieren" : "Beat FX aktivieren"}
                        aria-label={isBeatReactive ? "Beat FX deaktivieren" : "Beat FX aktivieren"}
                        disabled={playerViewMode === "visualizer"}
                        onClick={() => {
                          if (playerViewMode === "visualizer") return;
                          setIsBeatReactive((v) => !v);
                        }}
                      >
                        <IconBase>
                          <path d="M4 13h3l2-6 3 12 2-6h6" />
                        </IconBase>
                      </button>
                    </div>

                    {playerViewMode === "visualizer" ? (
                      <select
                        value={preset}
                        onChange={(e) => setPreset(e.target.value)}
                        className="fullscreen-preset-select w-full min-w-0 max-w-full appearance-none rounded-xl border border-white/20 bg-white/10 px-2.5 py-1.5 pr-8 text-xs text-[#e6e0e9] backdrop-blur-xl"
                        style={{ colorScheme: "dark" }}
                      >
                        {visualPresets.length === 0 && (
                          <option value="" style={{ backgroundColor: "#1a1622", color: "#f5eff7" }}>
                            Keine Presets in visual/ gefunden
                          </option>
                        )}
                        {visualPresets.map((name) => (
                          <option key={name} value={name} style={{ backgroundColor: "#1a1622", color: "#f5eff7" }}>
                            {name.replace(/\.(milk|json|preset)$/i, "")}
                          </option>
                        ))}
                      </select>
                    ) : null}
                  </div>
                ) : null}
              </div>
              </div>
            </section>
          </div>

          {isLyricsOpen ? (
            <div className="absolute inset-0 z-20 grid place-items-center bg-[#07060bcc] p-4">
              <div className="w-full max-w-2xl rounded-[24px] border border-[#4a4458] bg-[#211f26f2] p-5 shadow-2xl">
                <div className="mb-3 flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-[#f5eff7]">Lyrics</h3>
                  <button className="rounded-full border border-[#4a4458] bg-[#2b2930] px-4 py-2 text-sm text-[#e6e0e9]" onClick={() => setIsLyricsOpen(false)}>
                    Schliessen
                  </button>
                </div>
                <pre className="max-h-[58vh] overflow-auto whitespace-pre-wrap rounded-xl border border-[#4a4458] bg-[#17141e] p-4 text-sm text-[#e6e0e9]">
                  {activeTrack?.lyrics?.trim() || "Keine eingebetteten Lyrics in dieser Datei gefunden."}
                </pre>
              </div>
            </div>
          ) : null}
        </div>
      )}
    </AppShell>
  );
}
