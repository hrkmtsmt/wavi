import type { Copy } from "../i18n";

/** The name's note on the left; the other language and the copyright on the right. */
export function Footer({ copy, otherLanguageHref }: { copy: Copy; otherLanguageHref: string }) {
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

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render, screen } = await import("@testing-library/react");
  const { copy } = await import("../i18n");

  describe("Footer", () => {
    it("links to the other language, written in that language", () => {
      render(<Footer copy={copy.en} otherLanguageHref="/" />);
      const link = screen.getByRole("link", { name: "日本語" });
      expect(link.getAttribute("href")).toBe("/");
      expect(link.getAttribute("hreflang")).toBe("ja");
      expect(link.getAttribute("lang")).toBe("ja");
    });

    it("shows the note on the name and the copyright", () => {
      render(<Footer copy={copy.ja} otherLanguageHref="/en/" />);
      expect(screen.getByRole("contentinfo").textContent).toBe(`${copy.ja.footerNote}${copy.ja.otherLanguage}© 2026 hrkmtsmt`);
    });
  });
}
