import { describe, expect, it } from "vitest";
import { filterViewAuditEvents, isViewAuditEvent } from "./audit-events";

const events = [
  { id: "1", action: "edge.feed.view" },
  { id: "2", action: "project.update" },
  { id: "3", action: "edge.brief.view" },
  { id: "4", action: "user.review" },
];

describe("audit-events", () => {
  it("recognises *.view actions only", () => {
    expect(isViewAuditEvent("edge.feed.view")).toBe(true);
    expect(isViewAuditEvent("project.view")).toBe(true);
    expect(isViewAuditEvent("project.review")).toBe(false);
    expect(isViewAuditEvent("viewer.create")).toBe(false);
  });

  it("hides view events by default and reports how many were hidden", () => {
    const result = filterViewAuditEvents(events, false);
    expect(result.visible.map((e) => e.id)).toEqual(["2", "4"]);
    expect(result.hiddenViewCount).toBe(2);
  });

  it("passes everything through when views are included", () => {
    const result = filterViewAuditEvents(events, true);
    expect(result.visible).toHaveLength(4);
    expect(result.hiddenViewCount).toBe(0);
  });
});
