const SEED_LEN = 12;

export function generateUserSeed(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(SEED_LEN));
  return Array.from(bytes, (b) => String(b % 10)).join("");
}

export function isValidSeed(seed: string): boolean {
  return /^\d{12}$/.test(seed);
}
