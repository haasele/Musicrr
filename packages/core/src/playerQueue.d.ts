export type QueueState = {
    trackIds: string[];
    currentIndex: number;
    shuffle: boolean;
    repeatMode: "off" | "all" | "one";
};
export declare class PlayerQueue {
    private state;
    load(trackIds: string[], startIndex?: number): QueueState;
    toggleShuffle(): QueueState;
    next(): number;
    previous(): number;
    setRepeat(mode: QueueState["repeatMode"]): QueueState;
    getState(): QueueState;
    private shuffled;
}
