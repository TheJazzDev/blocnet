import { describe, expect, it } from "vitest";
import { toQuery } from "./api-client-http";

describe("toQuery", () => {
  it("serializes only defined query params", () => {
    expect(
      toQuery({
        q: "alice",
        limit: 25,
        offset: 0,
        role: "",
        status: null,
        topic: undefined,
      }),
    ).toBe("?q=alice&limit=25&offset=0");
  });

  it("returns empty string when all params are empty", () => {
    expect(
      toQuery({
        q: "",
        limit: undefined,
        offset: null,
      }),
    ).toBe("");
  });
});
