import { render, screen } from "@testing-library/react";
import { expect, test, vi } from "vitest";

import App from "./App";


test("renders workspace sections", async () => {
  vi.stubGlobal(
    "fetch",
    vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        status: "ok",
        wal_mode: "wal",
      }),
    }),
  );

  render(<App />);

  expect(screen.getByRole("heading", { name: "Virtual Project Manager" })).toBeInTheDocument();
  expect(screen.getByRole("button", { name: /board/i })).toBeInTheDocument();
  expect(screen.getByRole("button", { name: /inbox/i })).toBeInTheDocument();
});
