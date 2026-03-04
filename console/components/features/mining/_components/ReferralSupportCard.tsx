"use client";

import { Loader2, Save } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

type ReferralSupportCardProps = {
  canMutate: boolean;
  supportUserIdOrEmail: string;
  setSupportUserIdOrEmail: (value: string) => void;
  supportReferralCode: string;
  setSupportReferralCode: (value: string) => void;
  supportSaving: boolean;
  supportError: string | null;
  supportSuccess: string | null;
  supportReferralLookup: {
    loading: boolean;
    valid: boolean;
    ownerEmail: string | null;
    ownerName: string | null;
    ownerId: string | null;
  };
  onBind: () => Promise<void>;
};

export function ReferralSupportCard({
  canMutate,
  supportUserIdOrEmail,
  setSupportUserIdOrEmail,
  supportReferralCode,
  setSupportReferralCode,
  supportSaving,
  supportError,
  supportSuccess,
  supportReferralLookup,
  onBind,
}: ReferralSupportCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Referral Support</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <p className="text-sm text-muted-foreground">
          Use this when a user signed up without entering a referral code.
        </p>
        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <Label htmlFor="supportUserIdOrEmail">User ID or Email</Label>
            <Input
              id="supportUserIdOrEmail"
              placeholder="user UUID or user@email.com"
              value={supportUserIdOrEmail}
              onChange={(e) => setSupportUserIdOrEmail(e.target.value)}
              disabled={!canMutate || supportSaving}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="supportReferralCode">Referral Code</Label>
            <Input
              id="supportReferralCode"
              placeholder="AB12CD34"
              value={supportReferralCode}
              onChange={(e) => setSupportReferralCode(e.target.value.toUpperCase())}
              disabled={!canMutate || supportSaving}
            />
            {supportReferralLookup.loading ? (
              <p className="text-xs text-muted-foreground">Looking up referral owner...</p>
            ) : supportReferralCode.trim() ? (
              supportReferralLookup.valid ? (
                <p className="text-xs text-emerald-500">
                  Owner:{" "}
                  {supportReferralLookup.ownerName ?? supportReferralLookup.ownerEmail ?? "Unknown"} (
                  {supportReferralLookup.ownerEmail ?? "no email"}) ·{" "}
                  {supportReferralLookup.ownerId}
                </p>
              ) : (
                <p className="text-xs text-destructive">Referral code not found.</p>
              )
            ) : null}
          </div>
        </div>
        {supportError ? <p className="text-sm text-destructive">{supportError}</p> : null}
        {supportSuccess ? <p className="text-sm text-emerald-500">{supportSuccess}</p> : null}
        <div className="flex justify-end">
          <Button onClick={() => void onBind()} disabled={!canMutate || supportSaving}>
            {supportSaving ? (
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
