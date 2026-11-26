import { Fragment } from "react";
import type { Copy } from "../i18n";
import { Showcase } from "./Showcase";

/** The adopted design's "ホームページ（左寄せ）" and SPEC 8: these sections only, in this order. */
export function Home({ copy, otherLanguageHref }: { copy: Copy; otherLanguageHref: string }) {
  return (
    <>
      <Header />
      <main>
        <Hero copy={copy} />
        {/* A still for now; SPEC 8 swaps it for a short screen recording of the real app later. */}
        <section className="showcase-wrap">
          <Showcase copy={copy} />
        </section>
        <Keys copy={copy} />
      </main>
      <Footer copy={copy} otherLanguageHref={otherLanguageHref} />
    </>
  );
}

const repository = "https://github.com/hrkmtsmt/wavi";

/** Icon + "Wavi", and only a GitHub link on the right. */
function Header() {
  return (
    <header className="header">
      <a className="logo" href="#top">
        <Logo />
        <span>Wavi</span>
      </a>
      <a className="header-link" href={repository}>
        GitHub
      </a>
    </header>
  );
}

function Logo() {
  return (
    <svg width="32" height="32" viewBox="0 0 100 100" aria-hidden="true">
      <defs>
        <linearGradient id="logo-bg" gradientUnits="userSpaceOnUse" x1="35" y1="10" x2="65" y2="90">
          <stop offset="0" stopColor="#FFFFFF" />
          <stop offset="1" stopColor="#E4E8ED" />
        </linearGradient>
        <linearGradient id="logo-body" x1="0" y1="1" x2="1" y2="0">
          <stop offset="0" stopColor="#DCDFE3" />
          <stop offset="1" stopColor="#ACB2BA" />
        </linearGradient>
      </defs>
      <rect x="6" y="6" width="88" height="88" rx="20" fill="url(#logo-bg)" stroke="#000000" strokeOpacity="0.1" strokeWidth="1.2" />
      <path
        d="M24 74 V51 C24 42 28.5 37.5 34 37.5 C39.5 37.5 40.5 44 46 44 C51.5 44 52.5 35 59 35 C65.5 35 67.5 41.5 72 41.5 C75 41.5 76 45 76 51 V74 C76 76.8 73.8 79 71 79 H29 C26.2 79 24 76.8 24 74 Z"
        fill="url(#logo-body)"
      />
      <circle cx="41" cy="58" r="4.4" fill="url(#logo-bg)" />
      <circle cx="59" cy="58" r="4.4" fill="url(#logo-bg)" />
    </svg>
  );
}

/** Heading, description and the one download button, all on the left edge. */
function Hero({ copy }: { copy: Copy }) {
  return (
    <section id="top" className="hero">
      <h1>
        {copy.headline[0]}
        <br />
        {copy.headline[1]}
      </h1>
      <p>
        {copy.lead[0]}
        <br />
        {copy.lead[1]}
      </p>
      {/* Always the latest release's Wavi.zip; release.yml attaches it under this name every time. */}
      <a className="download" href={`${repository}/releases/latest/download/Wavi.zip`}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M12 4v11" />
          <path d="M7.5 10.5L12 15l4.5-4.5" />
          <path d="M5 19h14" />
        </svg>
        {copy.download}
      </a>
    </section>
  );
}

/** One status-bar-like line, the same capsule as the app's footer, with key caps like the app's KeyCap. */
function Keys({ copy }: { copy: Copy }) {
  const items: [string[], string][] = [
    [["⌘", "O"], copy.keys.open],
    [["⌘", "V"], copy.keys.paste],
    [["⌘", "⇧", "C"], copy.keys.copyAll],
  ];
  return (
    <section className="keys-wrap">
      <div className="keys">
        {items.map(([keys, label]) => (
          <Fragment key={label}>
            <span>
              <span className="combo">
                {keys.map((key) => (
                  <kbd key={key}>{key}</kbd>
                ))}
              </span>{" "}
              {label}
            </span>
            <span className="sep" aria-hidden="true">
              ／
            </span>
          </Fragment>
        ))}
        <span>
          <b>wv</b> file
        </span>
      </div>
    </section>
  );
}

function Footer({ copy, otherLanguageHref }: { copy: Copy; otherLanguageHref: string }) {
  return (
    <footer className="footer">
      <div>
        <span>{copy.footerNote}</span>
        <span className="footer-end">
          <a href={otherLanguageHref} hrefLang={copy.lang === "ja" ? "en" : "ja"} lang={copy.lang === "ja" ? "en" : "ja"}>
            {copy.otherLanguage}
          </a>
          <span>© 2026 hrkmtsmt</span>
        </span>
      </div>
    </footer>
  );
}
