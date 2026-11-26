// @ts-check
import react from "@astrojs/react";
import { defineConfig } from "astro/config";

// The site is static: every page is HTML at build time, and the React components ship no JavaScript (none uses a client: directive).
export default defineConfig({
  // Served from the root of its own domain on Cloudflare (wrangler.jsonc); `site` makes the language alternates full URLs.
  site: "https://wavi.hrkmtsmt.dev",
  integrations: [react()],
  i18n: {
    // Japanese at /, English at /en/.
    defaultLocale: "ja",
    locales: ["ja", "en"],
    routing: { prefixDefaultLocale: false },
  },
});
