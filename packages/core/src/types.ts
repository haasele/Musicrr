export type User = {
  id: string;
  seed: string;
  createdAt: number;
};

export type Artist = {
  id: string;
  name: string;
};

export type Album = {
  id: string;
  artistId: string;
  title: string;
  year?: number;
  coverArtPath?: string;
};

export type Track = {
  id: string;
  artistId: string;
  albumId?: string;
  title: string;
  filePath: string;
  durationSec: number;
  genre?: string;
  disc?: number;
  trackNo?: number;
  addedAt: number;
};

export type Playlist = {
  id: string;
  ownerUserId: string;
  name: string;
  createdAt: number;
  updatedAt: number;
};

export type PlaylistItem = {
  playlistId: string;
  trackId: string;
  order: number;
};
