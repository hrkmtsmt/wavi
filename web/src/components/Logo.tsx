/** The app icon. The header, the favicons and the social preview image (src/images.ts) all draw it from here. */
export function Logo({ size }: { size: number }) {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 100 100" aria-hidden="true">
      <defs>
        <linearGradient id="logo-bg" gradientUnits="userSpaceOnUse" x1="35" y1="10" x2="65" y2="90">
          <stop offset="0" stopColor="#FFFFFF" />
          <stop offset="1" stopColor="#E4E8ED" />
        </linearGradient>
        <linearGradient id="logo-body" x1="0" y1="1" x2="1" y2="0">
          <stop offset="0" stopColor="#DCDFE3" />
          <stop offset="1" stopColor="#ACB2BA" />
        </linearGradient>
      </defs>
      <rect x="6" y="6" width="88" height="88" rx="20" fill="url(#logo-bg)" stroke="#000000" strokeOpacity="0.1" strokeWidth="1.2" />
      <path
        d="M24 74 V51 C24 42 28.5 37.5 34 37.5 C39.5 37.5 40.5 44 46 44 C51.5 44 52.5 35 59 35 C65.5 35 67.5 41.5 72 41.5 C75 41.5 76 45 76 51 V74 C76 76.8 73.8 79 71 79 H29 C26.2 79 24 76.8 24 74 Z"
        fill="url(#logo-body)"
      />
      <circle cx="41" cy="58" r="4.4" fill="url(#logo-bg)" />
      <circle cx="59" cy="58" r="4.4" fill="url(#logo-bg)" />
    </svg>
  );
}

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render } = await import("@testing-library/react");

  describe("Logo", () => {
    it.each([16, 32, 180])("draws at %ipx, hidden from screen readers", (size) => {
      const { container } = render(<Logo size={size} />);
      const svg = container.querySelector("svg");
      expect(svg?.getAttribute("width")).toBe(String(size));
      expect(svg?.getAttribute("height")).toBe(String(size));
      expect(svg?.getAttribute("aria-hidden")).toBe("true");
    });

    it("stands alone as an SVG file, for the favicon", () => {
      const { container } = render(<Logo size={32} />);
      expect(container.querySelector("svg")?.getAttribute("xmlns")).toBe("http://www.w3.org/2000/svg");
    });
  });
}
