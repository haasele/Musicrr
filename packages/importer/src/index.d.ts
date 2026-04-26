export type ImportedTrack = {
    filePath: string;
    hash: string;
    title: string;
    artist: string;
    album?: string;
    durationSec: number;
};
export type ImportProgress = {
    processed: number;
    total: number;
    currentFile?: string;
};
export declare function importFolderRecursive(dir: string, onProgress?: (progress: ImportProgress) => void): Promise<ImportedTrack[]>;
