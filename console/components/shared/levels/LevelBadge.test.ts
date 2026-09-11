import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { LevelBadge, formatLevelLabel, resolveBadgeImage } from "./LevelBadge";

function render(props: Parameters<typeof LevelBadge>[0]) {
  return renderToStaticMarkup(createElement(LevelBadge, props));
}

describe("resolveBadgeImage", () => {
  it("returns the trimmed url when present", () => {
    expect(resolveBadgeImage(" /images/levels/1.svg ", null)).toBe("/images/levels/1.svg");
  });

  it("returns null for empty, whitespace, null or undefined urls", () => {
    expect(resolveBadgeImage("", null)).toBeNull();
    expect(resolveBadgeImage("   ", null)).toBeNull();
    expect(resolveBadgeImage(null, null)).toBeNull();
    expect(resolveBadgeImage(undefined, null)).toBeNull();
  });

  it("returns null once that url has failed to load", () => {
    expect(resolveBadgeImage("/bad.svg", "/bad.svg")).toBeNull();
    expect(resolveBadgeImage("/other.svg", "/bad.svg")).toBe("/other.svg");
  });
});

describe("formatLevelLabel", () => {
  it("formats level and name, and a no-level state", () => {
    expect(formatLevelLabel({ level: 4, name: "Jade I" })).toBe("Level 4 · Jade I");
    expect(formatLevelLabel({ level: 4 })).toBe("Level 4");
    expect(formatLevelLabel(null)).toBe("No level");
  });
});

describe("LevelBadge", () => {
  it("renders the icon with object-contain and no cropping when iconUrl is set", () => {
    const html = render({ level: { level: 7, name: "Amethyst I", iconUrl: "/levels/7.svg" } });
    expect(html).toContain('<img src="/levels/7.svg"');
    expect(html).toContain("object-contain");
    expect(html).not.toContain("object-cover");
    expect(html).not.toContain("data-level-fallback");
  });

  it("falls back to the level number tinted with the level colour when iconUrl is empty", () => {
    const html = render({ level: { level: 7, name: "Amethyst I", iconUrl: "", color: "#8B5CF6" } });
    expect(html).not.toContain("<img");
    expect(html).toContain("data-level-fallback");
    expect(html).toContain(">7</span>");
    expect(html).toContain("#8B5CF6");
  });

  it("uses the tier colour for the fallback when the level has no colour", () => {
    const html = render({ level: { level: 11, iconUrl: null, color: null } });
    expect(html).toContain("data-level-fallback");
    expect(html).toContain("#F0B429");
  });

  it("renders a placeholder for a null level", () => {
    const html = render({ level: null, label: true });
    expect(html).toContain('aria-label="No level"');
    expect(html).toContain("No level");
    expect(html).not.toContain("<img");
  });

  it("supports sizes and optional labels", () => {
    expect(render({ level: { level: 1 }, size: "sm" })).toContain('data-level-badge-size="sm"');
    expect(render({ level: { level: 1 }, size: "lg" })).toContain('data-level-badge-size="lg"');
    expect(render({ level: { level: 2, name: "Iron II" }, label: true })).toContain(
      "Level 2 · Iron II",
    );
    expect(render({ level: { level: 2 }, label: "Custom" })).toContain("Custom");
    expect(render({ level: { level: 2, name: "Iron II" } })).not.toContain("Iron II</span>");
  });
});
