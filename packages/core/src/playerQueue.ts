export type QueueState = {
  trackIds: string[];
  currentIndex: number;
  shuffle: boolean;
  repeatMode: "off" | "all" | "one";
};

export class PlayerQueue {
  private state: QueueState = {
    trackIds: [],
    currentIndex: 0,
    shuffle: false,
    repeatMode: "off"
  };

  load(trackIds: string[], startIndex = 0): QueueState {
    this.state.trackIds = [...trackIds];
    this.state.currentIndex = Math.max(0, Math.min(startIndex, trackIds.length - 1));
    return this.getState();
  }

  toggleShuffle(): QueueState {
    this.state.shuffle = !this.state.shuffle;
    if (this.state.shuffle) this.state.trackIds = this.shuffled(this.state.trackIds);
    return this.getState();
  }

  next(): number {
    if (this.state.repeatMode === "one") return this.state.currentIndex;
    if (this.state.currentIndex + 1 < this.state.trackIds.length) {
      this.state.currentIndex += 1;
      return this.state.currentIndex;
    }
    if (this.state.repeatMode === "all" && this.state.trackIds.length > 0) {
      this.state.currentIndex = 0;
    }
    return this.state.currentIndex;
  }

  previous(): number {
    this.state.currentIndex = Math.max(0, this.state.currentIndex - 1);
    return this.state.currentIndex;
  }

  setRepeat(mode: QueueState["repeatMode"]): QueueState {
    this.state.repeatMode = mode;
    return this.getState();
  }

  getState(): QueueState {
    return { ...this.state, trackIds: [...this.state.trackIds] };
  }

  private shuffled(values: string[]): string[] {
    const clone = [...values];
    for (let i = clone.length - 1; i > 0; i -= 1) {
      const j = Math.floor(Math.random() * (i + 1));
      [clone[i], clone[j]] = [clone[j], clone[i]];
    }
    return clone;
  }
}
