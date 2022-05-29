import * as React from "react";
/**
 * React hook to persist any value between renders,
 * but keeps it up-to-date if it changes.
 *
 * @param fn the function to persist
 * @param deps the function dependency list
 */
export declare function useCallbackRef<T extends (...args: any[]) => any>(fn: T | undefined, deps?: React.DependencyList): T;
//# sourceMappingURL=use-callback-ref.d.ts.map