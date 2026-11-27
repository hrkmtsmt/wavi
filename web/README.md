# Wavi website

The homepage for Wavi, built with [Astro](https://astro.build/) and React components. Every page is static HTML: no component uses a `client:` directive. The only JavaScript is two small inline scripts in `src/layouts/Page.astro` for the light/dark toggle.

- Japanese at `/`, English at `/en/`. All wording is in `src/i18n.ts`.
- Light and dark follow the OS until the visitor picks one with the header toggle; the choice is kept in `localStorage`. The dark colors are the app's provisional ones, since the design has no dark mode yet.
- The favicons (`/favicon.ico`, `/favicon.svg`, `/apple-touch-icon.png`) and the social preview image (`/og.png`) are drawn at build time from the `Logo` component by `src/images.ts`, with satori and sharp.
- The page follows the adopted design's left-aligned homepage and SPEC 8.

## Develop

Run these in this folder (`web/`). The Node version is in `.node-version`.

```sh
npm ci
npm run dev      # http://localhost:4321
npm run build    # writes dist/
npx astro check  # type check
npm test         # component tests
```

Each component is one file in `src/components/`, and its tests sit at the end of the same file in an `if (import.meta.vitest)` block ([Vitest in-source testing](https://vitest.dev/guide/in-source)). They render the component into jsdom with Testing Library. The build defines `import.meta.vitest` as `undefined` (`astro.config.mjs`), so the tests never reach the site.

## Deploy

`.github/workflows/web.yml` type-checks, tests and builds the site on every pull request that touches `web/`, and on `main` deploys `dist/` to Cloudflare Workers static assets at https://wavi.hrkmtsmt.dev (`wrangler.jsonc`, a Workers custom domain on the `hrkmtsmt.dev` zone). The first deploy creates the domain's DNS record and certificate.

The workflow needs two repository secrets: `CLOUDFLARE_API_TOKEN`, a token allowed to deploy Workers and their custom domains, and `CLOUDFLARE_ACCOUNT_ID`.

To deploy by hand from this folder after `npm run build`: `npx wrangler@4.168.0 deploy`.

Redirecting `/` by the browser's language is planned as a Cloudflare redirect rule on `http.request.accepted_languages`.
