// src/types/jest-axe.d.ts

declare module 'jest-axe' {
    import { AxeResults } from 'axe-core';
    import { MatcherFunction } from 'expect';

    export function axe(container: HTMLElement): Promise<AxeResults>;

    export const toHaveNoViolations: MatcherFunction;
}
