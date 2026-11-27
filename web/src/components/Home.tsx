import type { Copy } from "../i18n";
import { Footer } from "./Footer";
import { Header } from "./Header";
import { Hero } from "./Hero";
import { Keys } from "./Keys";
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

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render, screen } = await import("@testing-library/react");
  const { copy } = await import("../i18n");

  describe("Home", () => {
    it("has a header, one main and a footer, in that order", () => {
      const { container } = render(<Home copy={copy.ja} otherLanguageHref="/en/" />);
      expect([...container.children].map((element) => element.tagName)).toEqual(["HEADER", "MAIN", "FOOTER"]);
      expect(screen.getAllByRole("main")).toHaveLength(1);
    });

    it("has one heading, the headline", () => {
      render(<Home copy={copy.en} otherLanguageHref="/" />);
      expect(screen.getAllByRole("heading")).toHaveLength(1);
      expect(screen.getByRole("heading", { level: 1 }).textContent).toBe(copy.en.headline.join(""));
    });
  });
}
