// declarations.d.ts

import 'vitest';
import { AxeResults } from 'axe-core';

declare module '*.png' {
    const value: string;
    export default value;
}

declare module '*.jpg' {
    const value: string;
    export default value;
}

declare module '*.svg' {
    const value: string;
    export default value;
}

declare module 'vitest' {
    interface Assertion<T = any> {
        // Preserve other matchers and add jest-axe
        toHaveNoViolations(): T;
    }
}


