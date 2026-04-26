export type EncryptedPayload = {
    iv: string;
    cipherText: string;
};
export declare function encryptJson(seed: string, payload: unknown, salt?: string): Promise<EncryptedPayload>;
export declare function decryptJson<T>(seed: string, encrypted: EncryptedPayload, salt?: string): Promise<T>;
export declare function createRecoveryEnvelope(seed: string): Promise<EncryptedPayload>;
