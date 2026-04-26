type ButterchurnVisualizer = {
  connectAudio: (node: AudioNode) => void;
  disconnectAudio: (node: AudioNode) => void;
  setRendererSize: (width: number, height: number, opts?: { meshWidth?: number; meshHeight?: number }) => void;
  loadPreset: (preset: object, blendTime?: number) => void;
  render: () => void;
};

function normalizeName(value: string): string {
  return value.toLowerCase().replace(/\.(milk|preset|json)$/i, "").replace(/[^a-z0-9]+/g, " ").trim();
}

function scoreMatch(target: string, candidate: string): number {
  if (target === candidate) return 1_000_000;
  const targetTokens = target.split(" ").filter(Boolean);
  const candidateTokens = candidate.split(" ").filter(Boolean);
  let score = 0;
  for (const token of targetTokens) {
    if (candidate.includes(token)) score += token.length * 4;
    if (candidateTokens.includes(token)) score += token.length * 7;
  }
  if (candidate.includes(target)) score += target.length * 8;
  return score;
}

export class MilkEngine {
  private visualizer: ButterchurnVisualizer | null = null;
  private audioNode: AudioNode | null = null;
  private animationFrame = 0;
  private allPresets: Record<string, unknown> = {};

  async init(canvas: HTMLCanvasElement, audioContext: AudioContext, sourceNode: AudioNode): Promise<void> {
    const butterchurnModule = await import("butterchurn");
    const presetModules = await Promise.all([
      import("butterchurn-presets"),
      import("butterchurn-presets/lib/butterchurnPresetsExtra.min.js"),
      import("butterchurn-presets/lib/butterchurnPresetsExtra2.min.js"),
      import("butterchurn-presets/lib/butterchurnPresetsMD1.min.js")
    ]);

    const butterchurn = (butterchurnModule as any).default?.createVisualizer
      ? (butterchurnModule as any).default
      : (butterchurnModule as any);

    const mapFromModule = (mod: unknown): Record<string, unknown> => {
      const candidate = (mod as any).default ?? mod;
      if (candidate && typeof candidate.getPresets === "function") return candidate.getPresets();
      if (candidate && typeof candidate === "object") return candidate as Record<string, unknown>;
      return {};
    };

    this.allPresets = {};
    for (const module of presetModules) {
      Object.assign(this.allPresets, mapFromModule(module));
    }

    this.visualizer = butterchurn.createVisualizer(audioContext, canvas, {
      width: Math.max(640, canvas.clientWidth || 640),
      height: Math.max(360, canvas.clientHeight || 360),
      meshWidth: 64,
      meshHeight: 48
    }) as ButterchurnVisualizer;

    this.audioNode = sourceNode;
    this.visualizer.connectAudio(sourceNode);
    this.resize(canvas);
    this.renderLoop();
  }

  resize(canvas: HTMLCanvasElement): void {
    if (!this.visualizer) return;
    const dpr = Math.max(1, window.devicePixelRatio || 1);
    const width = Math.max(320, Math.floor((canvas.clientWidth || canvas.width) * dpr));
    const height = Math.max(180, Math.floor((canvas.clientHeight || canvas.height) * dpr));
    canvas.width = width;
    canvas.height = height;
    this.visualizer.setRendererSize(width, height, { meshWidth: 64, meshHeight: 48 });
  }

  loadPresetByName(selectedName: string, milkContent?: string): boolean {
    if (!this.visualizer || !selectedName) return false;
    const target = normalizeName(selectedName.split("/").pop() ?? selectedName);
    const contentTokens = (milkContent ?? "")
      .toLowerCase()
      .match(/[a-z][a-z0-9_]{2,}/g) ?? [];
    const contentTokenSet = new Set(contentTokens.slice(0, 200));
    const entries = Object.entries(this.allPresets);
    if (entries.length === 0) return false;

    let bestKey = entries[0][0];
    let bestScore = -1;
    for (const [key] of entries) {
      const candidate = normalizeName(key);
      let score = scoreMatch(target, candidate);
      if (contentTokenSet.size > 0) {
        for (const token of contentTokenSet) {
          if (token.length < 4) continue;
          if (candidate.includes(token)) score += token.length;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestKey = key;
      }
    }

    const presetEntry = this.allPresets[bestKey];
    const preset = typeof presetEntry === "function" ? (presetEntry as () => object)() : (presetEntry as object);
    this.visualizer.loadPreset(preset, 2.4);
    return true;
  }

  private renderLoop(): void {
    if (!this.visualizer) return;
    this.visualizer.render();
    this.animationFrame = requestAnimationFrame(() => this.renderLoop());
  }

  dispose(): void {
    cancelAnimationFrame(this.animationFrame);
    if (this.visualizer && this.audioNode) this.visualizer.disconnectAudio(this.audioNode);
    this.visualizer = null;
    this.audioNode = null;
    this.allPresets = {};
  }
}
