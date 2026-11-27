/** The red, yellow and green window buttons, for the Finder and Wavi windows in the showcase. */
export function TrafficLights() {
  return (
    <>
      <span className="dot red" />
      <span className="dot yellow" />
      <span className="dot green" />
    </>
  );
}

if (import.meta.vitest) {
  const { describe, expect, it } = import.meta.vitest;
  const { render } = await import("@testing-library/react");

  describe("TrafficLights", () => {
    it("draws red, yellow and green, in macOS order", () => {
      const { container } = render(<TrafficLights />);
      expect([...container.querySelectorAll(".dot")].map((dot) => dot.className)).toEqual(["dot red", "dot yellow", "dot green"]);
    });
  });
}
