import type { Copy } from "../i18n";
import { Gear } from "./Gear";
import { TrafficLights } from "./TrafficLights";

const files = [
  { name: "webhook-event.json", size: "18.6 KB", picked: true },
  { name: "memo.md", size: "412 B" },
  { name: "server.pem", size: "1.2 KB" },
  { name: "export.csv", size: "86 KB" },
  { name: "build.log", size: "2.4 MB" },
];

/** Dragging webhook-event.json from Finder onto Wavi, drawn to scale with cqw units (see .showcase in global.css). */
export function Showcase({ copy }: { copy: Copy }) {
  return (
    <div className="showcase" role="img" aria-label={copy.showcaseLabel}>
      <div className="finder" aria-hidden="true">
        <div className="finder-bar">
          <TrafficLights />
          <span className="finder-title">{copy.finder.title}</span>
        </div>
        <div className="finder-body">
          <div className="finder-side">
            <span>{copy.finder.recents}</span>
            <span className="selected">{copy.finder.downloads}</span>
            <span>{copy.finder.documents}</span>
            <span>{copy.finder.desktop}</span>
          </div>
          <div className="finder-files">
            {files.map((file) => (
              <div key={file.name} className={file.picked ? "picked" : undefined}>
                <span>{file.name}</span>
                <span>{file.size}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="wavi" aria-hidden="true">
        <div className="wavi-lights">
          <TrafficLights />
        </div>
        <div className="wavi-tabs">
          <span className="glass-track">
            <span className="preview-tab">
              webhook-event.json<b>18.6 KB</b>
            </span>
          </span>
          <span className="glass-round">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round">
              <path d="M12 5v14M5 12h14" />
            </svg>
          </span>
        </div>
        <div className="wavi-release">
          <b>{copy.releaseToOpen}</b>
        </div>
        <div className="wavi-status">
          <span className="status-pill">
            <span className="muted">TEXT</span>
            <b className="size">0 B</b>
            <span className="muted">{copy.zeroLines}</span>
            <span className="muted">UTF-8</span>
            <span className="copy">{copy.copy}</span>
          </span>
          <span className="status-round">?</span>
          <span className="status-round">
            <Gear />
          </span>
        </div>
        <div className="wavi-drop" />
      </div>

      <div className="drag-file" aria-hidden="true">
        <svg viewBox="0 0 18 22">
          <path d="M1 1h10l6 6v14H1z" fill="#FFFFFF" stroke="#8E8E93" strokeWidth="1" />
          <path d="M11 1v6h6" fill="none" stroke="#8E8E93" strokeWidth="1" />
        </svg>
        webhook-event.json
      </div>
      <svg className="cursor" aria-hidden="true" viewBox="0 0 18 26">
        <path d="M2 2v19l5-4.6 3.4 7.6 3.2-1.4-3.4-7.4H17z" fill="#FFFFFF" stroke="#1C1C1E" strokeWidth="1.3" strokeLinejoin="round" />
      </svg>
    </div>
  );
}

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render, screen } = await import("@testing-library/react");
  const { copy } = await import("../i18n");

  describe("Showcase", () => {
    it("is one picture, described by its label", () => {
      render(<Showcase copy={copy.ja} />);
      expect(screen.getByRole("img").getAttribute("aria-label")).toBe(copy.ja.showcaseLabel);
    });

    it("hides the drawing inside from screen readers", () => {
      const { container } = render(<Showcase copy={copy.en} />);
      const parts = [...container.querySelectorAll(".showcase > *")];
      expect(parts.length).toBeGreaterThan(0);
      expect(parts.every((part) => part.getAttribute("aria-hidden") === "true")).toBe(true);
    });

    it("shows webhook-event.json picked in Finder and Wavi asking to release it", () => {
      const { container } = render(<Showcase copy={copy.en} />);
      expect(container.querySelector(".finder-files .picked")?.textContent).toBe("webhook-event.json18.6 KB");
      expect(container.querySelector(".wavi-release")?.textContent).toBe("Release to open");
    });
  });
}
