import { Fragment } from "react";
import type { Copy } from "../i18n";

/** One status-bar-like line, the same capsule as the app's footer, with key caps like the app's KeyCap. */
export function Keys({ copy }: { copy: Copy }) {
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

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render } = await import("@testing-library/react");
  const { copy } = await import("../i18n");

  describe("Keys", () => {
    it("gives each key its own cap", () => {
      const { container } = render(<Keys copy={copy.en} />);
      const combos = [...container.querySelectorAll(".combo")].map((combo) => [...combo.querySelectorAll("kbd")].map((kbd) => kbd.textContent));
      expect(combos).toEqual([
        ["⌘", "O"],
        ["⌘", "V"],
        ["⌘", "⇧", "C"],
      ]);
    });

    it("labels the shortcuts in the page's language and ends with the wv command", () => {
      const { container } = render(<Keys copy={copy.ja} />);
      const items = [...container.querySelectorAll(".keys > span:not(.sep)")].map((item) => item.textContent);
      expect(items).toEqual(["⌘O 開く", "⌘V 貼り付け", "⌘⇧C 全部コピー", "wv file"]);
    });

    it("hides the separators from screen readers", () => {
      const { container } = render(<Keys copy={copy.ja} />);
      const separators = [...container.querySelectorAll(".sep")];
      expect(separators).toHaveLength(3);
      expect(separators.every((separator) => separator.getAttribute("aria-hidden") === "true")).toBe(true);
    });
  });
}
