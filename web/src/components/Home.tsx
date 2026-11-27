import { Fragment } from "react";
import type { Copy } from "../i18n";
import { Logo } from "./Logo";
import { Showcase } from "./Showcase";

/** The adopted design's "ホームページ（左寄せ）" and SPEC 8: these sections only, in this order. */
export function Home({ copy, otherLanguageHref }: { copy: Copy; otherLanguageHref: string }) {
  return (
    <>
      <Header copy={copy} otherLanguageHref={otherLanguageHref} />
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

/** Icon + "Wavi" on the left; the GitHub link, the language link and the light/dark toggle on the right. */
function Header({ copy, otherLanguageHref }: { copy: Copy; otherLanguageHref: string }) {
  return (
    <header className="header">
      <a className="logo" href="#top">
        <Logo size={32} />
        <span>Wavi</span>
      </a>
      <div className="header-end">
        <a className="header-link" href={repository}>
          GitHub
        </a>
        <LanguageLink copy={copy} href={otherLanguageHref} />
        <ThemeToggle copy={copy} />
      </div>
    </header>
  );
}

/** A globe that goes to the other language's page. Its name is that language written in itself ("English" on the Japanese page), so readers of either language can find it. */
function LanguageLink({ copy, href }: { copy: Copy; href: string }) {
  const other = copy.lang === "ja" ? "en" : "ja";
  return (
    <a className="icon-button" href={href} hrefLang={other} lang={other} aria-label={copy.otherLanguage} title={copy.otherLanguage}>
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <circle cx="12" cy="12" r="9" />
        <path d="M3 12h18" />
        <path d="M12 3c2.5 2.5 3.8 5.5 3.8 9s-1.3 6.5-3.8 9c-2.5-2.5-3.8-5.5-3.8-9S9.5 5.5 12 3z" />
      </svg>
    </a>
  );
}

/** Switches light and dark. It ships hidden; the script in Page.astro shows it and keeps aria-pressed (dark or not) in sync. */
function ThemeToggle({ copy }: { copy: Copy }) {
  return (
    <button type="button" className="icon-button theme-toggle" aria-label={copy.darkMode} aria-pressed="false" hidden>
      <svg className="moon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z" />
      </svg>
      <svg className="sun" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <circle cx="12" cy="12" r="4" />
        <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
      </svg>
    </button>
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
