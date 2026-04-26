import { createHash } from "node:crypto";
import { readdir, readFile, stat } from "node:fs/promises";
import { join } from "node:path";
import { parseBuffer } from "music-metadata";
const AUDIO_EXT = new Set([".mp3", ".flac", ".wav", ".ogg", ".m4a", ".aac"]);
function extension(file) {
    const idx = file.lastIndexOf(".");
    return idx < 0 ? "" : file.slice(idx).toLowerCase();
}
async function* walk(dir) {
    const entries = await readdir(dir);
    for (const entry of entries) {
        const full = join(dir, entry);
        const s = await stat(full);
        if (s.isDirectory()) {
            yield* walk(full);
        }
        else if (AUDIO_EXT.has(extension(entry))) {
            yield full;
        }
    }
}
export async function importFolderRecursive(dir, onProgress) {
    const files = [];
    for await (const file of walk(dir))
        files.push(file);
    const dedupe = new Set();
    const tracks = [];
    let processed = 0;
    for (const filePath of files) {
        const bytes = await readFile(filePath);
        const hash = createHash("sha256").update(bytes).digest("hex");
        processed += 1;
        onProgress?.({ processed, total: files.length, currentFile: filePath });
        if (dedupe.has(hash))
            continue;
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
