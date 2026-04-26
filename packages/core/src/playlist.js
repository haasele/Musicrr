export function createPlaylist(ownerUserId, name) {
    const now = Date.now();
    return {
        id: crypto.randomUUID(),
        ownerUserId,
        name,
        createdAt: now,
        updatedAt: now
    };
}
export function reorderPlaylistItems(trackIds, playlistId) {
    return trackIds.map((trackId, order) => ({ playlistId, trackId, order }));
}
