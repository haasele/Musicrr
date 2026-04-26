const textEncoder = new TextEncoder();
const textDecoder = new TextDecoder();

export type EncryptedPayload = {
  iv: string;
  cipherText: string;
};

function toBase64(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary);
}

function fromBase64(value: string): Uint8Array {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

async function deriveAesKey(seed: string, salt: string): Promise<CryptoKey> {
  const material = await crypto.subtle.importKey("raw", textEncoder.encode(seed), "PBKDF2", false, ["deriveKey"]);
  return crypto.subtle.deriveKey(
    { name: "PBKDF2", hash: "SHA-256", iterations: 200_000, salt: textEncoder.encode(salt) },
    material,
    { name: "AES-GCM", length: 256 },
    false,
    ["encrypt", "decrypt"]
  );
}

export async function encryptJson(seed: string, payload: unknown, salt = "music-web-v1"): Promise<EncryptedPayload> {
  const key = await deriveAesKey(seed, salt);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const plain = textEncoder.encode(JSON.stringify(payload));
  const encrypted = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, plain);
  return {
    iv: toBase64(iv),
    cipherText: toBase64(new Uint8Array(encrypted))
  };
}

export async function decryptJson<T>(seed: string, encrypted: EncryptedPayload, salt = "music-web-v1"): Promise<T> {
  const key = await deriveAesKey(seed, salt);
  const result = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: fromBase64(encrypted.iv) as BufferSource },
    key,
    fromBase64(encrypted.cipherText) as BufferSource
  );
  return JSON.parse(textDecoder.decode(result)) as T;
}

export async function createRecoveryEnvelope(seed: string): Promise<EncryptedPayload> {
  const deviceTransferSecret = crypto.randomUUID();
  return encryptJson(seed, { deviceTransferSecret, createdAt: Date.now() }, "recovery-v1");
}
