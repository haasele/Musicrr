import Redis from "ioredis";
import postgres from "postgres";

const POSTGRES_URL = process.env.POSTGRES_URL ?? "postgresql://musicrr:musicrr@localhost:5432/musicrr";
const DRAGONFLY_URL = process.env.DRAGONFLY_URL ?? "redis://localhost:6379";

export const sql = postgres(POSTGRES_URL, {
  max: 10,
  idle_timeout: 20
});

export const cache = new Redis(DRAGONFLY_URL, {
  maxRetriesPerRequest: 2,
  lazyConnect: true
});

export async function initPersistence(): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE,
      password_hash TEXT,
      display_name TEXT,
      is_admin BOOLEAN NOT NULL DEFAULT FALSE,
      created_at BIGINT NOT NULL
    );
  `;
  await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS email TEXT;`;
  await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash TEXT;`;
  await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name TEXT;`;
  await sql`ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;`;
  // Legacy: only if a "seed" column still exists (older schemas), allow NULL.
  const hasSeedCol = await sql`
    SELECT 1 as ok
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'seed'
    LIMIT 1
  `;
  if (hasSeedCol[0]) {
    await sql`ALTER TABLE users ALTER COLUMN seed DROP NOT NULL`;
  }
  await sql`CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users (email) WHERE email IS NOT NULL;`;

  await sql`
    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at BIGINT NOT NULL
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS encrypted_blobs (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      payload TEXT NOT NULL,
      created_at BIGINT NOT NULL
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS tracks (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      artist TEXT NOT NULL,
      album TEXT,
      title TEXT NOT NULL,
      file_path TEXT NOT NULL,
      cover_path TEXT,
      lyrics TEXT,
      hash TEXT NOT NULL UNIQUE,
      duration_sec INTEGER NOT NULL,
      added_at BIGINT NOT NULL,
      metadata_json JSONB DEFAULT '{}'::jsonb
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS playlists (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      created_at BIGINT NOT NULL,
      updated_at BIGINT NOT NULL
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS playlist_items (
      playlist_id TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
      track_id TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
      item_order INTEGER NOT NULL,
      PRIMARY KEY (playlist_id, item_order)
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS favorites (
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      track_id TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
      created_at BIGINT NOT NULL,
      PRIMARY KEY (user_id, track_id)
    );
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS shared_tracks (
      token TEXT PRIMARY KEY,
      track_id TEXT NOT NULL REFERENCES tracks(id) ON DELETE CASCADE,
      created_by_user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      created_at BIGINT NOT NULL
    );
  `;

  await sql`CREATE INDEX IF NOT EXISTS idx_tracks_user_added ON tracks(user_id, added_at DESC);`;
  await sql`CREATE INDEX IF NOT EXISTS idx_tracks_hash ON tracks(hash);`;
  await sql`CREATE INDEX IF NOT EXISTS idx_playlists_user_updated ON playlists(user_id, updated_at DESC);`;
  await sql`CREATE INDEX IF NOT EXISTS idx_playlist_items_playlist ON playlist_items(playlist_id, item_order);`;
  await sql`CREATE INDEX IF NOT EXISTS idx_shared_tracks_track ON shared_tracks(track_id);`;

  await sql`ALTER TABLE tracks ADD COLUMN IF NOT EXISTS search_doc tsvector;`;
  await sql`
    UPDATE tracks
    SET search_doc = to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(artist, '') || ' ' || coalesce(album, ''))
    WHERE search_doc IS NULL;
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_tracks_search_doc ON tracks USING GIN(search_doc);`;

  const adminEmail = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const adminPassword = process.env.ADMIN_PASSWORD?.trim();
  const adminName = process.env.ADMIN_NAME?.trim() || "Admin";
  if (adminEmail && adminPassword) {
    const existing = await sql`SELECT id FROM users WHERE email = ${adminEmail} LIMIT 1`;
    if (!existing[0]) {
      const passwordHash = await Bun.password.hash(adminPassword);
      await sql`
        INSERT INTO users (id, email, password_hash, display_name, is_admin, created_at)
        VALUES (${crypto.randomUUID()}, ${adminEmail}, ${passwordHash}, ${adminName}, ${true}, ${Date.now()})
      `;
    }
  }
}
