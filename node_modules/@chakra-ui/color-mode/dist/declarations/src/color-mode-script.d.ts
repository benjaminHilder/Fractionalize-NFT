/// <reference types="react" />
export declare type ColorModeScriptProps = {
    type?: "localStorage" | "cookie";
    initialColorMode?: "light" | "dark" | "system";
    storageKey?: string;
};
export declare function getScriptSrc(props?: ColorModeScriptProps): string;
export declare function ColorModeScript(props?: ColorModeScriptProps): JSX.Element;
//# sourceMappingURL=color-mode-script.d.ts.map