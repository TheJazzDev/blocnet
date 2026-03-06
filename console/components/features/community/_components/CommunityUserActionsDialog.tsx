"use client";

import { useEffect, useMemo, useState } from "react";
import { Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  useApplyCommunityMuteMutation,
  useApplyCommunityRestrictionsMutation,
  useApplyCommunitySuspensionMutation,
  useClearCommunityRestrictionsMutation,
  useCommunityModerationUserStateQuery,
  useIssueCommunityWarningMutation,
} from "@/lib/hooks/queries";

function formatDate(value: string | null) {
  if (!value) return "—";
  return new Date(value).toLocaleString();
}

type CommunityUserActionsDialogProps = {
  open: boolean;
  onOpenChange: (value: boolean) => void;
  userId: string | null;
  reportId?: string | null;
  canEscalate: boolean;
};

export function CommunityUserActionsDialog({
  open,
  onOpenChange,
  userId,
  reportId,
  canEscalate,
}: CommunityUserActionsDialogProps) {
  const { data, isLoading, error } = useCommunityModerationUserStateQuery(userId, {
    enabled: open && Boolean(userId),
  });

  const warningMutation = useIssueCommunityWarningMutation();
  const muteMutation = useApplyCommunityMuteMutation();
  const suspensionMutation = useApplyCommunitySuspensionMutation();
  const restrictionsMutation = useApplyCommunityRestrictionsMutation();
  const clearRestrictionsMutation = useClearCommunityRestrictionsMutation();

  const [warningReason, setWarningReason] = useState("");
  const [muteHours, setMuteHours] = useState("24");
  const [muteReason, setMuteReason] = useState("");
  const [suspensionHours, setSuspensionHours] = useState("24");
  const [suspensionReason, setSuspensionReason] = useState("");
  const [postingHours, setPostingHours] = useState("");
  const [commentingHours, setCommentingHours] = useState("");
  const [restrictionReason, setRestrictionReason] = useState("");
  const [clearReason, setClearReason] = useState("");
  const [actionError, setActionError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    setWarningReason("");
    setMuteReason("");
    setSuspensionReason("");
    setRestrictionReason("");
    setClearReason("");
    setActionError(null);
  }, [open, userId]);

  const busy =
    warningMutation.isPending ||
    muteMutation.isPending ||
    suspensionMutation.isPending ||
    restrictionsMutation.isPending ||
    clearRestrictionsMutation.isPending;

  const activeRestrictions = useMemo(() => {
    if (!data) return [];
    const entries: Array<{ label: string; value: string | null }> = [
      { label: "Muted Until", value: data.communityMutedUntil },
      { label: "Suspended Until", value: data.communitySuspendedUntil },
      { label: "Posting Restricted Until", value: data.communityPostingRestrictedUntil },
      {
        label: "Commenting Restricted Until",
        value: data.communityCommentingRestrictedUntil,
      },
    ];
    return entries.filter((entry) => entry.value);
  }, [data]);

  async function runAction(action: () => Promise<void>) {
    setActionError(null);
    try {
      await action();
    } catch (e: unknown) {
      setActionError(e instanceof Error ? e.message : "Action failed");
    }
  }

  function parseHours(raw: string): number | undefined {
    const parsed = Number(raw);
    if (!Number.isFinite(parsed) || parsed <= 0) return undefined;
    return Math.floor(parsed);
  }

  async function submitWarning() {
    if (!userId) return;
    const reason = warningReason.trim();
    if (reason.length < 3) {
      setActionError("Warning reason must be at least 3 characters.");
      return;
    }
    await runAction(async () => {
      await warningMutation.mutateAsync({ userId, reason, reportId: reportId ?? undefined });
      setWarningReason("");
    });
  }

  async function submitMute() {
    if (!userId) return;
    const durationHours = parseHours(muteHours);
    const reason = muteReason.trim();
    if (!durationHours) {
      setActionError("Mute duration must be a positive number.");
      return;
    }
    if (reason.length < 3) {
      setActionError("Mute reason must be at least 3 characters.");
      return;
    }
    await runAction(async () => {
      await muteMutation.mutateAsync({
        userId,
        durationHours,
        reason,
        reportId: reportId ?? undefined,
      });
      setMuteReason("");
    });
  }

  async function submitSuspension() {
    if (!userId || !canEscalate) return;
    const durationHours = parseHours(suspensionHours);
    const reason = suspensionReason.trim();
    if (!durationHours) {
      setActionError("Suspension duration must be a positive number.");
      return;
    }
    if (reason.length < 3) {
      setActionError("Suspension reason must be at least 3 characters.");
      return;
    }
    await runAction(async () => {
      await suspensionMutation.mutateAsync({
        userId,
        durationHours,
        reason,
        reportId: reportId ?? undefined,
      });
      setSuspensionReason("");
    });
  }

  async function submitRestrictions() {
    if (!userId || !canEscalate) return;
    const reason = restrictionReason.trim();
    const posting = parseHours(postingHours);
    const commenting = parseHours(commentingHours);
    if (!posting && !commenting) {
      setActionError("Provide posting and/or commenting duration.");
      return;
    }
    if (reason.length < 3) {
      setActionError("Restriction reason must be at least 3 characters.");
      return;
    }
    await runAction(async () => {
      await restrictionsMutation.mutateAsync({
        userId,
        postingHours: posting,
        commentingHours: commenting,
        reason,
        reportId: reportId ?? undefined,
      });
      setRestrictionReason("");
    });
  }

  async function submitClearRestrictions() {
    if (!userId || !canEscalate) return;
    const reason = clearReason.trim();
    if (reason.length < 3) {
      setActionError("Clear reason must be at least 3 characters.");
      return;
    }
    await runAction(async () => {
      await clearRestrictionsMutation.mutateAsync({
        userId,
        reason,
        reportId: reportId ?? undefined,
      });
      setClearReason("");
    });
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Community User Actions</DialogTitle>
          <DialogDescription>
            Apply warnings or restrictions with audit-traceable reasons.
          </DialogDescription>
        </DialogHeader>

        {!userId ? (
          <p className="text-sm text-muted-foreground">No target user selected.</p>
        ) : isLoading ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="h-5 w-5 animate-spin" />
          </div>
        ) : error ? (
          <p className="text-sm text-destructive">
            {error instanceof Error ? error.message : "Failed to load user moderation state."}
          </p>
        ) : data ? (
          <div className="space-y-6">
            <div className="rounded-md border border-border/70 bg-muted/20 p-3">
              <p className="text-sm font-medium">
                {data.displayName ?? data.username ?? data.email}
              </p>
              <p className="text-xs text-muted-foreground">{data.email}</p>
              <p className="mt-2 text-xs text-muted-foreground">
                Warn count: <span className="font-medium text-foreground">{data.communityWarnCount}</span>
              </p>
              <p className="text-xs text-muted-foreground">
                Last warned: {formatDate(data.communityLastWarnedAt)}
              </p>
              {activeRestrictions.length > 0 ? (
                <div className="mt-2 space-y-1">
                  {activeRestrictions.map((entry) => (
                    <p key={entry.label} className="text-xs text-amber-300">
                      {entry.label}: {formatDate(entry.value)}
                    </p>
                  ))}
                </div>
              ) : (
                <p className="mt-2 text-xs text-emerald-300">No active restrictions.</p>
              )}
            </div>

            <section className="space-y-3 rounded-md border border-border/70 p-3">
              <h4 className="text-sm font-semibold">Issue Warning</h4>
              <Textarea
                rows={3}
                value={warningReason}
                onChange={(e) => setWarningReason(e.target.value)}
                placeholder="Reason for warning"
              />
              <Button size="sm" onClick={() => void submitWarning()} disabled={busy}>
                {warningMutation.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                Issue Warning
              </Button>
            </section>

            <section className="space-y-3 rounded-md border border-border/70 p-3">
              <h4 className="text-sm font-semibold">Apply Mute</h4>
              <div className="grid gap-3 md:grid-cols-2">
                <div className="space-y-2">
                  <Label>Duration (hours)</Label>
                  <Input
                    type="number"
                    min={1}
                    value={muteHours}
                    onChange={(e) => setMuteHours(e.target.value)}
                  />
                </div>
              </div>
              <Textarea
                rows={3}
                value={muteReason}
                onChange={(e) => setMuteReason(e.target.value)}
                placeholder="Reason for mute"
              />
              <Button size="sm" onClick={() => void submitMute()} disabled={busy}>
                {muteMutation.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                Apply Mute
              </Button>
            </section>

            {canEscalate ? (
              <>
                <section className="space-y-3 rounded-md border border-border/70 p-3">
                  <h4 className="text-sm font-semibold">Apply Suspension</h4>
                  <div className="grid gap-3 md:grid-cols-2">
                    <div className="space-y-2">
                      <Label>Duration (hours)</Label>
                      <Input
                        type="number"
                        min={1}
                        value={suspensionHours}
                        onChange={(e) => setSuspensionHours(e.target.value)}
                      />
                    </div>
                  </div>
                  <Textarea
                    rows={3}
                    value={suspensionReason}
                    onChange={(e) => setSuspensionReason(e.target.value)}
                    placeholder="Reason for suspension"
                  />
                  <Button
                    size="sm"
                    onClick={() => void submitSuspension()}
                    disabled={busy}
                  >
                    {suspensionMutation.isPending ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : null}
                    Apply Suspension
                  </Button>
                </section>

                <section className="space-y-3 rounded-md border border-border/70 p-3">
                  <h4 className="text-sm font-semibold">Apply Posting/Comment Restrictions</h4>
                  <div className="grid gap-3 md:grid-cols-2">
                    <div className="space-y-2">
                      <Label>Posting restriction (hours)</Label>
                      <Input
                        type="number"
                        min={1}
                        value={postingHours}
                        onChange={(e) => setPostingHours(e.target.value)}
                        placeholder="Optional"
                      />
                    </div>
                    <div className="space-y-2">
                      <Label>Comment restriction (hours)</Label>
                      <Input
                        type="number"
                        min={1}
                        value={commentingHours}
                        onChange={(e) => setCommentingHours(e.target.value)}
                        placeholder="Optional"
                      />
                    </div>
                  </div>
                  <Textarea
                    rows={3}
                    value={restrictionReason}
                    onChange={(e) => setRestrictionReason(e.target.value)}
                    placeholder="Reason for restrictions"
                  />
                  <Button
                    size="sm"
                    onClick={() => void submitRestrictions()}
                    disabled={busy}
                  >
                    {restrictionsMutation.isPending ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : null}
                    Apply Restrictions
                  </Button>
                </section>

                <section className="space-y-3 rounded-md border border-border/70 p-3">
                  <h4 className="text-sm font-semibold">Clear Restrictions</h4>
                  <Textarea
                    rows={3}
                    value={clearReason}
                    onChange={(e) => setClearReason(e.target.value)}
                    placeholder="Reason for clearing restrictions"
                  />
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => void submitClearRestrictions()}
                    disabled={busy}
                  >
                    {clearRestrictionsMutation.isPending ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : null}
                    Clear Restrictions
                  </Button>
                </section>
              </>
            ) : (
              <p className="text-xs text-muted-foreground">
                Your role can issue warnings and mutes. Suspension and restriction controls are
                available to community admins and governance roles only.
              </p>
            )}

            {actionError ? <p className="text-sm text-destructive">{actionError}</p> : null}
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  );
}
