import { ArrowDownTrayIcon, GlobeAltIcon, MoonIcon, SunIcon } from "@heroicons/react/16/solid";
import { MarkGithubIcon } from "@primer/octicons-react";
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

/** Icon + "Wavi" on the left; the GitHub link, the language link and the light/dark toggle on the right, as 32px icon buttons. UI icons are Heroicons' 16px "micro" set, drawn for that size. */
function Header({ copy, otherLanguageHref }: { copy: Copy; otherLanguageHref: string }) {
  return (
    <header className="header">
      <a className="logo" href="#top">
        <Logo size={32} />
        <span>Wavi</span>
      </a>
      <div className="header-end">
        {/* GitHub's own mark from Octicons, in the page's ink, as GitHub's logo guidelines allow for a link to GitHub: https://brand.github.com/foundations/logo */}
        <a className="icon-button" href={repository} aria-label="GitHub" title="GitHub">
          <MarkGithubIcon size={16} aria-hidden="true" />
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
      <GlobeAltIcon width={16} height={16} />
    </a>
  );
}

/** Switches light and dark. It ships hidden; the script in Page.astro shows it and keeps aria-pressed (dark or not) in sync. */
function ThemeToggle({ copy }: { copy: Copy }) {
  return (
    <button type="button" className="icon-button theme-toggle" aria-label={copy.darkMode} aria-pressed="false" hidden>
      <MoonIcon className="moon" width={16} height={16} />
      <SunIcon className="sun" width={16} height={16} />
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
        <ArrowDownTrayIcon width={16} height={16} />
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
