import { MarkGithubIcon } from "@primer/octicons-react";
import type { Copy } from "../i18n";
import { repository } from "../site";
import { LanguageLink } from "./LanguageLink";
import { Logo } from "./Logo";
import { ThemeToggle } from "./ThemeToggle";

/** Icon + "Wavi" on the left; the GitHub link, the language link and the light/dark toggle on the right, as 32px icon buttons. Every UI icon is a 16px Octicon, GitHub's own set, so the GitHub mark and the rest match. */
export function Header({ copy, otherLanguageHref }: { copy: Copy; otherLanguageHref: string }) {
  return (
    <header className="header">
      <a className="logo" href="#top">
        <Logo size={32} />
        <span>Wavi</span>
      </a>
      <div className="header-end">
        {/* GitHub's mark, in the page's ink, as GitHub's logo guidelines allow for a link to GitHub: https://brand.github.com/foundations/logo */}
        <a className="icon-button" href={repository} aria-label="GitHub" title="GitHub">
          <MarkGithubIcon size={16} aria-hidden="true" />
        </a>
        <LanguageLink copy={copy} href={otherLanguageHref} />
        <ThemeToggle copy={copy} />
      </div>
    </header>
  );
}

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render, screen } = await import("@testing-library/react");
  const { copy } = await import("../i18n");

  describe("Header", () => {
    it("links the name to the top of the page", () => {
      render(<Header copy={copy.ja} otherLanguageHref="/en/" />);
      expect(screen.getByRole("link", { name: "Wavi" }).getAttribute("href")).toBe("#top");
    });

    it("links to the repository, the other language and has the theme toggle, in that order", () => {
      render(<Header copy={copy.ja} otherLanguageHref="/en/" />);
      const links = screen.getAllByRole("link");
      expect(links.map((link) => link.getAttribute("aria-label"))).toEqual([null, "GitHub", "English"]);
      expect(screen.getByRole("link", { name: "GitHub" }).getAttribute("href")).toBe(repository);
      expect(screen.getByRole("button", { hidden: true }).getAttribute("aria-label")).toBe(copy.ja.darkMode);
    });
  });
}
