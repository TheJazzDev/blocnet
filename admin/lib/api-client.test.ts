import { afterEach, describe, expect, it, vi } from "vitest";
import { apiFetch } from "./api-client";

describe("apiFetch", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("redirects on 401 without attempting an explicit refresh endpoint call", async () => {
    const location = {
      pathname: "/dashboard",
      href: "",
    };
    vi.stubGlobal("window", { location });

    const fetchMock = vi.fn().mockResolvedValue(
      new Response("Unauthorized", {
        status: 401,
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await expect(apiFetch("/me")).rejects.toThrow("Unauthorized");

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock).toHaveBeenCalledWith(
      "/api/proxy/me",
      expect.objectContaining({ headers: expect.any(Object) }),
    );
    expect(location.href).toBe("/signin?next=%2Fdashboard");
  });
});
