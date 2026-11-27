import { DownloadIcon } from "@primer/octicons-react";
import type { Copy } from "../i18n";
import { repository } from "../site";

/** Heading, description and the one download button, all on the left edge. */
export function Hero({ copy }: { copy: Copy }) {
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
        <DownloadIcon size={16} aria-hidden="true" />
        {copy.download}
      </a>
    </section>
  );
}

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render, screen } = await import("@testing-library/react");
  const { copy } = await import("../i18n");

  describe("Hero", () => {
    it("breaks the headline and the lead into their two lines", () => {
      const { container } = render(<Hero copy={copy.ja} />);
      expect(screen.getByRole("heading", { level: 1 }).innerHTML).toBe(copy.ja.headline.join("<br>"));
      expect(container.querySelector("p")?.innerHTML).toBe(copy.ja.lead.join("<br>"));
    });

    it("downloads the latest release's Wavi.zip from the one button", () => {
      render(<Hero copy={copy.en} />);
      expect(screen.getAllByRole("link")).toHaveLength(1);
      expect(screen.getByRole("link", { name: "Download for free" }).getAttribute("href")).toBe(
        "https://github.com/hrkmtsmt/wavi/releases/latest/download/Wavi.zip",
      );
    });

    it("is the #top the header's name links to", () => {
      const { container } = render(<Hero copy={copy.en} />);
      expect(container.querySelector("section")?.id).toBe("top");
    });
  });
}
