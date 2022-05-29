export declare type ColorMode = "light" | "dark";
declare type UtilOptions = {
    preventTransition?: boolean;
};
export declare function getColorModeUtils(options?: UtilOptions): {
    setDataset: (value: ColorMode) => void;
    setClassName(dark: boolean): void;
    query(): MediaQueryList;
    getSystemTheme(fallback?: ColorMode | undefined): "dark" | "light";
    addListener(fn: (cm: ColorMode) => unknown): () => void;
    preventTransition(): () => void;
};
export {};
//# sourceMappingURL=color-mode.utils.d.ts.map