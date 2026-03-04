"use client";

import { Loader2, Save, ShieldCheck } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import type {
  AdminTwoFactorEnrollmentStartResponse,
  AdminTwoFactorPolicy,
  AdminTwoFactorPreflight,
} from "@/lib/api-client";
import { AdminTwoFactorEnrollmentPanel } from "./AdminTwoFactorEnrollmentPanel";

type AdminTwoFactorCardProps = {
  isOwner: boolean;
  twoFactorLoading: boolean;
  twoFactorSaving: boolean;
  twoFactorStatus: string | null;
  twoFactorPreflight: AdminTwoFactorPreflight | null;
  twoFactorPolicy: AdminTwoFactorPolicy | null;
  policyDraft: "true" | "false";
  setPolicyDraft: (value: "true" | "false") => void;
  enrollment: AdminTwoFactorEnrollmentStartResponse | null;
  confirmCode: string;
  setConfirmCode: (value: string) => void;
  actionCode: string;
  setActionCode: (value: string) => void;
  actionRecoveryCode: string;
  setActionRecoveryCode: (value: string) => void;
  showManualSetup: boolean;
  setShowManualSetup: (value: boolean) => void;
  showAdvancedOtpUri: boolean;
  setShowAdvancedOtpUri: (value: boolean) => void;
  qrCodeDataUrl: string | null;
  qrCodeError: string | null;
  onRefresh: () => Promise<void>;
  onStartEnrollment: () => Promise<void>;
  onConfirmEnrollment: () => Promise<void>;
  onSavePolicy: () => Promise<void>;
  onRegenerateRecoveryCodes: () => Promise<void>;
  onDisableTwoFactor: () => Promise<void>;
};

export function AdminTwoFactorCard({
  isOwner,
  twoFactorLoading,
  twoFactorSaving,
  twoFactorStatus,
  twoFactorPreflight,
  twoFactorPolicy,
  policyDraft,
  setPolicyDraft,
  enrollment,
  confirmCode,
  setConfirmCode,
  actionCode,
  setActionCode,
  actionRecoveryCode,
  setActionRecoveryCode,
  showManualSetup,
  setShowManualSetup,
  showAdvancedOtpUri,
  setShowAdvancedOtpUri,
  qrCodeDataUrl,
  qrCodeError,
  onRefresh,
  onStartEnrollment,
  onConfirmEnrollment,
  onSavePolicy,
  onRegenerateRecoveryCodes,
  onDisableTwoFactor,
}: AdminTwoFactorCardProps) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0">
        <div>
          <CardTitle className="flex items-center gap-2 text-base">
            <ShieldCheck className="h-4 w-4" />
            Admin Panel 2FA
          </CardTitle>
          <CardDescription>
            Google Authenticator TOTP, recovery codes, and owner-enforced policy.
          </CardDescription>
        </div>
        <Button
          variant="outline"
          size="sm"
          onClick={() => void onRefresh()}
          disabled={twoFactorLoading || twoFactorSaving}
        >
          {twoFactorLoading ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            "Refresh"
          )}
        </Button>
      </CardHeader>
      <CardContent className="space-y-4">
        {twoFactorLoading ? (
          <LoadingSpinner className="py-6" />
        ) : !twoFactorPreflight || !twoFactorPolicy ? (
          <p className="text-sm text-muted-foreground">
            Admin 2FA state unavailable.
          </p>
        ) : (
          <>
            <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
              <div className="rounded-md border border-border/70 p-3">
                <p className="text-xs text-muted-foreground">Account 2FA</p>
                <p className="mt-1 text-sm font-medium">
                  {twoFactorPreflight.totpEnabled ? "Enabled" : "Disabled"}
                </p>
              </div>
              <div className="rounded-md border border-border/70 p-3">
                <p className="text-xs text-muted-foreground">Recovery Codes Left</p>
                <p className="mt-1 text-sm font-medium">
                  {twoFactorPreflight.recoveryCodesRemaining}
                </p>
              </div>
              <div className="rounded-md border border-border/70 p-3">
                <p className="text-xs text-muted-foreground">Policy Enforcement</p>
                <p className="mt-1 text-sm font-medium">
                  {twoFactorPolicy.require2faForAdminPanel ? "Required" : "Optional"}
                </p>
              </div>
              <div className="rounded-md border border-border/70 p-3">
                <p className="text-xs text-muted-foreground">Eligible / Enabled</p>
                <p className="mt-1 text-sm font-medium">
                  {twoFactorPolicy.summary.enabledUsers}/
                  {twoFactorPolicy.summary.eligibleUsers}
                </p>
              </div>
            </div>

            <div className="grid gap-4 xl:grid-cols-2">
              <div className="space-y-3 rounded-md border border-border/70 p-3">
                <p className="text-sm font-medium">Owner Policy</p>
                <div className="space-y-1.5">
                  <Label>Require 2FA for Owner/Admin/Moderator panel access</Label>
                  <Select
                    value={policyDraft}
                    onValueChange={(value) =>
                      setPolicyDraft(value === "true" ? "true" : "false")
                    }
                    disabled={!isOwner || twoFactorSaving}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="false">Optional</SelectItem>
                      <SelectItem value="true">Required</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <Button
                  size="sm"
                  onClick={() => void onSavePolicy()}
                  disabled={!isOwner || twoFactorSaving}
                >
                  {twoFactorSaving ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  Save 2FA Policy
                </Button>
              </div>

              <AdminTwoFactorEnrollmentPanel
                twoFactorEnabled={twoFactorPreflight.totpEnabled}
                twoFactorSaving={twoFactorSaving}
                enrollment={enrollment}
                confirmCode={confirmCode}
                setConfirmCode={setConfirmCode}
                actionCode={actionCode}
                setActionCode={setActionCode}
                actionRecoveryCode={actionRecoveryCode}
                setActionRecoveryCode={setActionRecoveryCode}
                showManualSetup={showManualSetup}
                setShowManualSetup={setShowManualSetup}
                showAdvancedOtpUri={showAdvancedOtpUri}
                setShowAdvancedOtpUri={setShowAdvancedOtpUri}
                qrCodeDataUrl={qrCodeDataUrl}
                qrCodeError={qrCodeError}
                onStartEnrollment={onStartEnrollment}
                onConfirmEnrollment={onConfirmEnrollment}
                onRegenerateRecoveryCodes={onRegenerateRecoveryCodes}
                onDisableTwoFactor={onDisableTwoFactor}
              />
            </div>
          </>
        )}

        {twoFactorStatus ? (
          <p className="text-xs text-muted-foreground">{twoFactorStatus}</p>
        ) : null}
      </CardContent>
    </Card>
  );
}
