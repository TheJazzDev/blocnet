"use client";

import { Loader2, ShieldCheck, Smartphone } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { AdminTwoFactorEnrollmentStartResponse } from "@/lib/api-client";

type AdminTwoFactorEnrollmentPanelProps = {
  twoFactorEnabled: boolean;
  twoFactorSaving: boolean;
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
  onStartEnrollment: () => Promise<void>;
  onConfirmEnrollment: () => Promise<void>;
  onRegenerateRecoveryCodes: () => Promise<void>;
  onDisableTwoFactor: () => Promise<void>;
};

export function AdminTwoFactorEnrollmentPanel({
  twoFactorEnabled,
  twoFactorSaving,
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
  onStartEnrollment,
  onConfirmEnrollment,
  onRegenerateRecoveryCodes,
  onDisableTwoFactor,
}: AdminTwoFactorEnrollmentPanelProps) {
  return (
    <div className="space-y-3 rounded-md border border-border/70 p-3">
      <p className="text-sm font-medium">Authenticator Enrollment</p>
      {!twoFactorEnabled && !enrollment && (
        <Button
          size="sm"
          onClick={() => void onStartEnrollment()}
          disabled={twoFactorSaving}
        >
          {twoFactorSaving ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Smartphone className="h-4 w-4" />
          )}
          Start Enrollment
        </Button>
      )}

      {enrollment && (
        <div className="space-y-3">
          {qrCodeDataUrl ? (
            <div className="space-y-1">
              <Label>Scan QR Code</Label>
              <div className="flex justify-center rounded-md border border-border p-3">
                <img
                  src={qrCodeDataUrl}
                  alt="TOTP enrollment QR code"
                  width={220}
                  height={220}
                />
              </div>
            </div>
          ) : null}
          {qrCodeError ? (
            <p className="text-xs text-muted-foreground">{qrCodeError}</p>
          ) : null}
          <Button
            size="sm"
            variant="ghost"
            onClick={() => {
              const next = !showManualSetup;
              setShowManualSetup(next);
              if (!next) {
                setShowAdvancedOtpUri(false);
              }
            }}
            disabled={twoFactorSaving}
          >
            {showManualSetup ? "Hide Manual Setup" : "Use Manual Setup Instead"}
          </Button>
          {showManualSetup && (
            <div className="space-y-3 rounded-md border border-border p-3">
              <div className="space-y-1">
                <Label>Secret Key</Label>
                <Input value={enrollment.secret} readOnly />
              </div>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => setShowAdvancedOtpUri(!showAdvancedOtpUri)}
                disabled={twoFactorSaving}
              >
                {showAdvancedOtpUri ? "Hide Advanced URI" : "Show Advanced URI"}
              </Button>
              {showAdvancedOtpUri && (
                <div className="space-y-1">
                  <Label>OTPAuth URI</Label>
                  <Input value={enrollment.otpAuthUrl} readOnly />
                </div>
              )}
            </div>
          )}
          <div className="space-y-1">
            <Label>Confirm Authenticator Code</Label>
            <Input
              value={confirmCode}
              onChange={(event) => setConfirmCode(event.target.value)}
              placeholder="123456"
              disabled={twoFactorSaving}
            />
          </div>
          <Button
            size="sm"
            onClick={() => void onConfirmEnrollment()}
            disabled={twoFactorSaving}
          >
            {twoFactorSaving ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <ShieldCheck className="h-4 w-4" />
            )}
            Confirm Enrollment
          </Button>
        </div>
      )}

      {twoFactorEnabled && (
        <div className="grid gap-3 rounded-md border border-border/70 p-3 xl:grid-cols-[1fr_auto_auto]">
          <div className="space-y-2">
            <p className="text-sm font-medium">2FA Actions</p>
            <div className="grid gap-2 sm:grid-cols-2">
              <Input
                placeholder="Authenticator code (123456)"
                value={actionCode}
                onChange={(event) => setActionCode(event.target.value)}
                disabled={twoFactorSaving}
              />
              <Input
                placeholder="or recovery code"
                value={actionRecoveryCode}
                onChange={(event) => setActionRecoveryCode(event.target.value)}
                disabled={twoFactorSaving}
              />
            </div>
          </div>
          <Button
            variant="outline"
            onClick={() => void onRegenerateRecoveryCodes()}
            disabled={twoFactorSaving}
          >
            {twoFactorSaving ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              "Regenerate Codes"
            )}
          </Button>
          <Button
            variant="destructive"
            onClick={() => void onDisableTwoFactor()}
            disabled={twoFactorSaving}
          >
            {twoFactorSaving ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              "Disable 2FA"
            )}
          </Button>
        </div>
      )}
    </div>
  );
}
