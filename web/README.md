# Wavi website

The homepage for Wavi, built with [Astro](https://astro.build/) and React components. Every page is static HTML: no component uses a `client:` directive, so pages ship no JavaScript.

- Japanese at `/`, English at `/en/`. All wording is in `src/i18n.ts`.
- Light and dark follow the OS (`prefers-color-scheme`). The dark colors are the app's provisional ones, since the design has no dark mode yet.
- The page follows the adopted design's left-aligned homepage and SPEC 8.

## Develop

Run these in this folder (`web/`). The Node version is in `.node-version`.

```sh
npm ci
npm run dev      # http://localhost:4321
npm run build    # writes dist/
npx astro check  # type check
```

## Deploy

`.github/workflows/web.yml` builds the site on every pull request that touches `web/`, and on `main` deploys `dist/` to Cloudflare Workers static assets at https://wavi.hrkmtsmt.dev (`wrangler.jsonc`, a Workers custom domain on the `hrkmtsmt.dev` zone). The first deploy creates the domain's DNS record and certificate.

The workflow needs two repository secrets: `CLOUDFLARE_API_TOKEN`, a token allowed to deploy Workers and their custom domains, and `CLOUDFLARE_ACCOUNT_ID`.

To deploy by hand from this folder after `npm run build`: `npx wrangler@4.168.0 deploy`.

Redirecting `/` by the browser's language is planned as a Cloudflare redirect rule on `http.request.accepted_languages`.
