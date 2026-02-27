import { afterEach, describe, expect, it, vi } from "vitest";
import { resetRefreshTokenLockForTests, runRefreshWithTokenLock } from "./route";

function wait(ms: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}

describe("api proxy refresh lock", () => {
  afterEach(() => {
    resetRefreshTokenLockForTests();
  });

  it("reuses one in-flight refresh for the same refresh token", async () => {
    const refresher = vi.fn(async () => {
      await wait(25);
      return "new-access-token";
    });

    const [first, second, third] = await Promise.all([
      runRefreshWithTokenLock("refresh-token-a", refresher),
      runRefreshWithTokenLock("refresh-token-a", refresher),
      runRefreshWithTokenLock("refresh-token-a", refresher),
    ]);

    expect(first).toBe("new-access-token");
    expect(second).toBe("new-access-token");
    expect(third).toBe("new-access-token");
    expect(refresher).toHaveBeenCalledTimes(1);
  });

  it("does not share refresh work for different refresh tokens", async () => {
    const refresher = vi.fn(async (token: string) => {
      await wait(10);
      return `access:${token}`;
    });

    const [first, second] = await Promise.all([
      runRefreshWithTokenLock("refresh-token-a", () => refresher("refresh-token-a")),
      runRefreshWithTokenLock("refresh-token-b", () => refresher("refresh-token-b")),
    ]);

    expect(first).toBe("access:refresh-token-a");
    expect(second).toBe("access:refresh-token-b");
    expect(refresher).toHaveBeenCalledTimes(2);
  });
});
