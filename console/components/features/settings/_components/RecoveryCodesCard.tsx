"use client";

import { Check, Copy } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";

type RecoveryCodesCardProps = {
  generatedRecoveryCodes: string[];
  twoFactorSaving: boolean;
  recoveryCopyStatus: string | null;
  lastCopiedRecoveryCode: string | null;
  onCopyAllRecoveryCodes: () => Promise<void>;
  onCopyRecoveryCode: (code: string) => Promise<void>;
};

export function RecoveryCodesCard({
  generatedRecoveryCodes,
  twoFactorSaving,
  recoveryCopyStatus,
  lastCopiedRecoveryCode,
  onCopyAllRecoveryCodes,
  onCopyRecoveryCode,
}: RecoveryCodesCardProps) {
  if (generatedRecoveryCodes.length === 0) {
    return null;
  }

  return (
    <Card className="border-amber-500/30 bg-amber-500/5">
      <CardHeader>
        <CardTitle className="text-base">Recovery Codes (Save Now)</CardTitle>
        <CardDescription>
          Each code can be used once. Store them in a secure location.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Button
          variant="outline"
          size="sm"
          className="mb-3"
          onClick={() => void onCopyAllRecoveryCodes()}
          disabled={twoFactorSaving || generatedRecoveryCodes.length === 0}
        >
          <Copy className="h-4 w-4" />
          Copy All Codes
        </Button>
        <div className="grid gap-2 sm:grid-cols-2">
          {generatedRecoveryCodes.map((code) => (
            <div
              key={code}
              className="flex items-center justify-between rounded-md border border-border/70 bg-background/80 px-2 py-1"
            >
              <code className="text-xs">{code}</code>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => void onCopyRecoveryCode(code)}
                disabled={twoFactorSaving}
              >
                {lastCopiedRecoveryCode === code ? (
                  <Check className="h-4 w-4" />
                ) : (
                  <Copy className="h-4 w-4" />
                )}
                {lastCopiedRecoveryCode === code ? "Copied" : "Copy"}
              </Button>
            </div>
          ))}
        </div>
        {recoveryCopyStatus ? (
          <p className="mt-2 text-xs text-muted-foreground">{recoveryCopyStatus}</p>
        ) : null}
      </CardContent>
    </Card>
  );
}
