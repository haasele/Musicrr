import type { Playlist, PlaylistItem } from "./types";

export function createPlaylist(ownerUserId: string, name: string): Playlist {
  const now = Date.now();
  return {
    id: crypto.randomUUID(),
    ownerUserId,
    name,
    createdAt: now,
    updatedAt: now
  };
}

export function reorderPlaylistItems(trackIds: string[], playlistId: string): PlaylistItem[] {
  return trackIds.map((trackId, order) => ({ playlistId, trackId, order }));
}
