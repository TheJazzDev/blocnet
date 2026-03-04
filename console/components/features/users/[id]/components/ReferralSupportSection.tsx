"use client";

import { useEffect, useState } from "react";
import { Loader2, Save, UserPlus } from "lucide-react";
import { apiFetch, clientApi, type AdminUserDetail } from "@/lib/api-client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type ReferralSupportSectionProps = {
  user: AdminUserDetail;
  canManage: boolean;
  onBound?: () => Promise<void> | void;
};

export function ReferralSupportSection({
  user,
  canManage,
  onBound,
}: ReferralSupportSectionProps) {
  const [referralCode, setReferralCode] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [lookup, setLookup] = useState<{
    loading: boolean;
    valid: boolean;
    ownerEmail: string | null;
    ownerName: string | null;
    ownerId: string | null;
  }>({
    loading: false,
    valid: false,
    ownerEmail: null,
    ownerName: null,
    ownerId: null,
  });

  useEffect(() => {
    const code = referralCode.trim().toUpperCase();
    if (!code || !/^[A-Z0-9]{8}$/.test(code)) {
      setLookup({
        loading: false,
        valid: false,
        ownerEmail: null,
        ownerName: null,
        ownerId: null,
      });
      return;
    }

    const timer = setTimeout(async () => {
      setLookup((prev) => ({ ...prev, loading: true }));
      try {
        const result = await apiFetch<{
          valid: boolean;
          referrer: { id: string; email: string | null; displayName: string | null } | null;
        }>(`/referrals/validate?code=${encodeURIComponent(code)}`);
        setLookup({
          loading: false,
          valid: result.valid,
          ownerEmail: result.referrer?.email ?? null,
          ownerName: result.referrer?.displayName ?? null,
          ownerId: result.referrer?.id ?? null,
        });
      } catch {
        setLookup({
          loading: false,
          valid: false,
          ownerEmail: null,
          ownerName: null,
          ownerId: null,
        });
      }
    }, 250);

    return () => clearTimeout(timer);
  }, [referralCode]);

  async function bindReferral() {
    if (!canManage) {
      return;
    }
    if (user.referredBy) {
      setError("This member already has a referrer linked.");
      setSuccess(null);
      return;
    }

    const code = referralCode.trim().toUpperCase();
    if (!code) {
      setError("Enter a referral code.");
      setSuccess(null);
      return;
    }

    setSaving(true);
    setError(null);
    setSuccess(null);
    try {
      const result = await clientApi.adminBindReferralForUser(user.id, { code });
      setSuccess(
        `Bound ${result.targetUser.email} to ${result.referrer.code ?? "UNKNOWN"} (${result.referrer.email}).`,
      );
      setReferralCode("");
      await onBound?.();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to bind referral for member");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <UserPlus className="h-4 w-4 sm:h-5 sm:w-5" />
          Referral Support
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-xs sm:text-sm text-muted-foreground">
          Referral linking is account-level and managed from Member records.
        </p>

        <div className="rounded-md border p-3 bg-muted/20 text-xs sm:text-sm">
          {user.referredBy ? (
            <p className="text-muted-foreground">
              Linked to{" "}
              <span className="font-medium text-foreground">
                {user.referredBy.displayName ?? user.referredBy.email}
              </span>
              {user.referredAt ? ` on ${new Date(user.referredAt).toLocaleString()}` : ""}.
            </p>
          ) : (
            <p className="text-muted-foreground">No referral is linked to this member yet.</p>
          )}
        </div>

        {!canManage ? (
          <p className="text-xs text-muted-foreground">
            Owner/Admin role is required to bind referrals.
          </p>
        ) : (
          <>
            <div className="space-y-2">
              <Label htmlFor="memberReferralCode">Referral Code</Label>
              <Input
                id="memberReferralCode"
                placeholder="AB12CD34"
                value={referralCode}
                onChange={(e) => setReferralCode(e.target.value.toUpperCase())}
                disabled={saving || Boolean(user.referredBy)}
              />
              {lookup.loading ? (
                <p className="text-xs text-muted-foreground">Looking up referral owner...</p>
              ) : referralCode.trim() ? (
                lookup.valid ? (
                  <p className="text-xs text-emerald-500">
                    Owner: {lookup.ownerName ?? lookup.ownerEmail ?? "Unknown"} (
                    {lookup.ownerEmail ?? "no email"}) · {lookup.ownerId}
                  </p>
                ) : (
                  <p className="text-xs text-destructive">Referral code not found.</p>
                )
              ) : null}
            </div>

            {error ? <p className="text-sm text-destructive">{error}</p> : null}
            {success ? <p className="text-sm text-emerald-500">{success}</p> : null}

            <div className="flex justify-end">
              <Button
                onClick={() => void bindReferral()}
                disabled={saving || Boolean(user.referredBy)}
              >
                {saving ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <Save className="h-4 w-4" />
                )}
                Bind Referral
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
