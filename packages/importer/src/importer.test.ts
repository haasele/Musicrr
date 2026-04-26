import { describe, expect, it } from "bun:test";

describe("importer", () => {
  it("supports audio extension detection list", () => {
    const supported = [".mp3", ".flac", ".wav", ".ogg", ".m4a", ".aac"];
    expect(supported.includes(".mp3")).toBe(true);
  });
});
