import { createHash } from "node:crypto";
import { readdir, readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { parseBuffer } from "music-metadata";

const AUDIO_EXT = new Set([".mp3", ".flac", ".wav", ".ogg", ".m4a", ".aac"]);

export type ImportedTrack = {
  filePath: string;
  hash: string;
  title: string;
  artist: string;
  album?: string;
  durationSec: number;
};

export type ImportProgress = {
  processed: number;
  total: number;
  currentFile?: string;
};

function extension(file: string): string {
  const idx = file.lastIndexOf(".");
  return idx < 0 ? "" : file.slice(idx).toLowerCase();
}

async function* walk(dir: string): AsyncGenerator<string> {
  const entries = await readdir(dir);
  for (const entry of entries) {
    const full = join(dir, entry);
    const s = await stat(full);
    if (s.isDirectory()) {
      yield* walk(full);
    } else if (AUDIO_EXT.has(extension(entry))) {
      yield full;
    }
  }
}

export async function importFolderRecursive(
  dir: string,
  onProgress?: (progress: ImportProgress) => void
): Promise<ImportedTrack[]> {
  const files: string[] = [];
  for await (const file of walk(dir)) files.push(file);
  const dedupe = new Set<string>();
  const tracks: ImportedTrack[] = [];
  let processed = 0;

  for (const filePath of files) {
    const bytes = await readFile(filePath);
    const hash = createHash("sha256").update(bytes).digest("hex");
    processed += 1;
    onProgress?.({ processed, total: files.length, currentFile: filePath });
    if (dedupe.has(hash)) continue;
    dedupe.add(hash);

    const meta = await parseBuffer(bytes, extension(filePath).slice(1));
    tracks.push({
      filePath,
      hash,
      title: meta.common.title ?? filePath.split("/").pop() ?? "Unknown",
      artist: meta.common.artist ?? "Unknown Artist",
      album: meta.common.album,
      durationSec: Math.floor(meta.format.duration ?? 0)
    });
  }

  return tracks;
}
