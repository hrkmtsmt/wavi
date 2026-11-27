/// <reference types="vitest/config" />
// Tests live next to the code they test, in an `if (import.meta.vitest)` block at the end of each file (https://vitest.dev/guide/in-source). getViteConfig applies astro.config.mjs, so tests see the same React setup as the build (https://docs.astro.build/en/guides/testing/).
import { getViteConfig } from "astro/config";

export default getViteConfig({
  test: {
    includeSource: ["src/**/*.{ts,tsx}"],
    // Components render into a DOM so tests can query them by role and name, the way a reader or a screen reader meets them.
    environment: "jsdom",
    setupFiles: ["src/test-setup.ts"],
  },
});
