import { describe, expect, it } from "bun:test";
import { decryptJson, encryptJson } from "./index";

describe("crypto", () => {
  it("encrypts and decrypts payload", async () => {
    const payload = { hello: "world", now: Date.now() };
    const encrypted = await encryptJson("123456789012", payload);
    const decrypted = await decryptJson<typeof payload>("123456789012", encrypted);
    expect(decrypted.hello).toBe("world");
  });
});
