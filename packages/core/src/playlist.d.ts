import type { Playlist, PlaylistItem } from "./types";
export declare function createPlaylist(ownerUserId: string, name: string): Playlist;
export declare function reorderPlaylistItems(trackIds: string[], playlistId: string): PlaylistItem[];
