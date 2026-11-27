import { MoonIcon, SunIcon } from "@primer/octicons-react";
import type { Copy } from "../i18n";

/** Switches light and dark. It ships hidden; the script in Page.astro shows it and keeps aria-pressed (dark or not) in sync. */
export function ThemeToggle({ copy }: { copy: Copy }) {
  return (
    <button type="button" className="icon-button theme-toggle" aria-label={copy.darkMode} aria-pressed="false" hidden>
      <MoonIcon className="moon" size={16} aria-hidden="true" />
      <SunIcon className="sun" size={16} aria-hidden="true" />
    </button>
  );
}

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render, screen } = await import("@testing-library/react");
  const { copy } = await import("../i18n");

  // A hidden element has no accessible name, so these find the button by role alone and read its label.
  describe("ThemeToggle", () => {
    it("ships hidden, so a page without JavaScript has no dead button", () => {
      render(<ThemeToggle copy={copy.ja} />);
      expect(screen.queryByRole("button")).toBeNull();
      const button = screen.getByRole("button", { hidden: true });
      expect(button.hidden).toBe(true);
      expect(button.getAttribute("aria-label")).toBe("ダークモード");
    });

    it("starts not pressed and holds both icons for the script to swap", () => {
      render(<ThemeToggle copy={copy.en} />);
      const button = screen.getByRole("button", { hidden: true });
      expect(button.getAttribute("type")).toBe("button");
      expect(button.getAttribute("aria-label")).toBe("Dark mode");
      expect(button.getAttribute("aria-pressed")).toBe("false");
      expect(button.querySelector("svg.moon")).not.toBeNull();
      expect(button.querySelector("svg.sun")).not.toBeNull();
    });
  });
}
