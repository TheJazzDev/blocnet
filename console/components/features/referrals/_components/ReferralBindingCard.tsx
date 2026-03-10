"use client";

import { Loader2, Save, UserPlus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type ReferralBindingCardProps = {
  canMutate: boolean;
  userIdOrEmail: string;
  setUserIdOrEmail: (value: string) => void;
  referralCode: string;
  setReferralCode: (value: string) => void;
  saving: boolean;
  error: string | null;
  success: string | null;
  referralLookup: {
    loading: boolean;
    valid: boolean;
    ownerEmail: string | null;
    ownerName: string | null;
    ownerId: string | null;
  };
  onBind: () => Promise<void>;
};

export function ReferralBindingCard({
  canMutate,
  userIdOrEmail,
  setUserIdOrEmail,
  referralCode,
  setReferralCode,
  saving,
  error,
  success,
  referralLookup,
  onBind,
}: ReferralBindingCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <UserPlus className="h-4 w-4 sm:h-5 sm:w-5" />
          Bind User to Referral Code
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-xs sm:text-sm text-muted-foreground">
          Use this tool when a user signed up without entering a referral code, or needs their
          referral corrected. Enter the user's ID or email and the referral code they should be
          bound to.
        </p>
        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <Label htmlFor="userIdOrEmail">User ID or Email</Label>
            <Input
              id="userIdOrEmail"
              placeholder="user UUID or user@email.com"
              value={userIdOrEmail}
              onChange={(e) => setUserIdOrEmail(e.target.value)}
              disabled={!canMutate || saving}
            />
            <p className="text-xs text-muted-foreground">
              The user who should be bound to the referral
            </p>
          </div>
          <div className="space-y-2">
            <Label htmlFor="referralCode">Referral Code</Label>
            <Input
              id="referralCode"
              placeholder="AB12CD34"
              value={referralCode}
              onChange={(e) => setReferralCode(e.target.value.toUpperCase())}
              disabled={!canMutate || saving}
            />
            {referralLookup.loading ? (
              <p className="text-xs text-muted-foreground">Looking up referral owner...</p>
            ) : referralCode.trim() ? (
              referralLookup.valid ? (
                <p className="text-xs text-emerald-500">
                  ✓ Owner:{" "}
                  {referralLookup.ownerName ?? referralLookup.ownerEmail ?? "Unknown"} (
                  {referralLookup.ownerEmail ?? "no email"}) · {referralLookup.ownerId}
                </p>
              ) : (
                <p className="text-xs text-destructive">✗ Referral code not found.</p>
              )
            ) : (
              <p className="text-xs text-muted-foreground">
                The referral code owner (8 characters)
              </p>
            )}
          </div>
        </div>
        {error ? <p className="text-sm text-destructive">{error}</p> : null}
        {success ? (
          <div className="rounded-md bg-emerald-500/10 border border-emerald-500/30 p-3">
            <p className="text-sm text-emerald-500">{success}</p>
          </div>
        ) : null}
        <div className="flex justify-end">
          <Button onClick={() => void onBind()} disabled={!canMutate || saving}>
            {saving ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Save className="h-4 w-4" />
            )}
            Bind Referral
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
