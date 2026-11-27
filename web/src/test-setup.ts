// Testing Library only cleans up on its own when Vitest's globals are on; they're off here, so unmount after each test (https://testing-library.com/docs/react-testing-library/setup).
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

afterEach(() => {
  cleanup();
});
