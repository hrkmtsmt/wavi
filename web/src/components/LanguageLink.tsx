import { GlobeIcon } from "@primer/octicons-react";
import type { Copy } from "../i18n";

/** A globe that goes to the other language's page. Its name is that language written in itself ("English" on the Japanese page), so readers of either language can find it. */
export function LanguageLink({ copy, href }: { copy: Copy; href: string }) {
  const other = copy.lang === "ja" ? "en" : "ja";
  return (
    <a className="icon-button" href={href} hrefLang={other} lang={other} aria-label={copy.otherLanguage} title={copy.otherLanguage}>
      <GlobeIcon size={16} aria-hidden="true" />
    </a>
  );
}

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render, screen } = await import("@testing-library/react");
  const { copy } = await import("../i18n");

  describe("LanguageLink", () => {
    it.each([
      { from: "ja", to: "en", name: "English", href: "/en/" },
      { from: "en", to: "ja", name: "日本語", href: "/" },
    ] as const)("goes from $from to $to, named in $to", ({ from, to, name, href }) => {
      render(<LanguageLink copy={copy[from]} href={href} />);
      const link = screen.getByRole("link", { name });
      expect(link.getAttribute("href")).toBe(href);
      expect(link.getAttribute("hreflang")).toBe(to);
      expect(link.getAttribute("lang")).toBe(to);
    });
  });
}
