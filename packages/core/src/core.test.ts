import { describe, expect, it } from "bun:test";
import { generateUserSeed, isValidSeed, PlayerQueue } from "./index";

describe("seed", () => {
  it("generates a 12 digit seed", () => {
    const seed = generateUserSeed();
    expect(seed.length).toBe(12);
    expect(isValidSeed(seed)).toBe(true);
  });
});

describe("player queue", () => {
  it("moves next with repeat-all", () => {
    const queue = new PlayerQueue();
    queue.load(["a", "b"], 1);
    queue.setRepeat("all");
    expect(queue.next()).toBe(0);
  });
});
