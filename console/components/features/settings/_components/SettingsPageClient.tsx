"use client";

import { LogOut } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateSettings } from "@/lib/rbac";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { RuntimeFeatureFlagsCard } from "./RuntimeFeatureFlagsCard";
import { AdminTwoFactorCard } from "./AdminTwoFactorCard";
import { RecoveryCodesCard } from "./RecoveryCodesCard";
import { SystemDiagnosticsGrid } from "./SystemDiagnosticsGrid";
import { useRuntimeFeatureFlags } from "../_hooks/use-runtime-feature-flags";
import { useAdminTwoFactor } from "../_hooks/use-admin-two-factor";

export default function SettingsPageClient() {
  const session = useAdminSession();
  const canMutate = canMutateSettings(session.effectiveRoles);
  const isOwner = session.realRoles.includes("owner");

  const runtimeFlagsState = useRuntimeFeatureFlags();
  const twoFactorState = useAdminTwoFactor(isOwner);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Settings"
        description="Admin panel configuration and environment diagnostics."
      >
        <form action="/signout" method="post">
          <Button variant="destructive" type="submit">
            <LogOut className="h-4 w-4" />
            Sign Out
          </Button>
        </form>
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Settings mutations are restricted to owner/dev/admin roles.
          </CardContent>
        </Card>
      )}

      <RuntimeFeatureFlagsCard
        canMutate={canMutate}
        runtimeFlags={runtimeFlagsState.runtimeFlags}
        runtimeFlagsLoading={runtimeFlagsState.runtimeFlagsLoading}
        runtimeFlagsSaving={runtimeFlagsState.runtimeFlagsSaving}
        runtimeFlagsStatus={runtimeFlagsState.runtimeFlagsStatus}
        closedAlphaEmails={runtimeFlagsState.closedAlphaEmails}
        closedAlphaTotal={runtimeFlagsState.closedAlphaTotal}
        closedAlphaLoading={runtimeFlagsState.closedAlphaLoading}
        closedAlphaMutating={runtimeFlagsState.closedAlphaMutating}
        closedAlphaStatus={runtimeFlagsState.closedAlphaStatus}
        onSave={runtimeFlagsState.saveRuntimeFlags}
        onSetFlag={runtimeFlagsState.setRuntimeFlag}
        onAddEmail={runtimeFlagsState.addClosedAlphaEmail}
        onToggleEmailActive={runtimeFlagsState.setClosedAlphaEmailActive}
        onRemoveEmail={runtimeFlagsState.removeClosedAlphaEmail}
      />

      <AdminTwoFactorCard
        isOwner={isOwner}
        twoFactorLoading={twoFactorState.twoFactorLoading}
        twoFactorSaving={twoFactorState.twoFactorSaving}
        twoFactorStatus={twoFactorState.twoFactorStatus}
        twoFactorPreflight={twoFactorState.twoFactorPreflight}
        twoFactorPolicy={twoFactorState.twoFactorPolicy}
        policyDraft={twoFactorState.policyDraft}
        setPolicyDraft={twoFactorState.setPolicyDraft}
        enrollment={twoFactorState.enrollment}
        confirmCode={twoFactorState.confirmCode}
        setConfirmCode={twoFactorState.setConfirmCode}
        actionCode={twoFactorState.actionCode}
        setActionCode={twoFactorState.setActionCode}
        actionRecoveryCode={twoFactorState.actionRecoveryCode}
        setActionRecoveryCode={twoFactorState.setActionRecoveryCode}
        showManualSetup={twoFactorState.showManualSetup}
        setShowManualSetup={twoFactorState.setShowManualSetup}
        showAdvancedOtpUri={twoFactorState.showAdvancedOtpUri}
        setShowAdvancedOtpUri={twoFactorState.setShowAdvancedOtpUri}
        qrCodeDataUrl={twoFactorState.qrCodeDataUrl}
        qrCodeError={twoFactorState.qrCodeError}
        onRefresh={twoFactorState.loadTwoFactorState}
        onStartEnrollment={twoFactorState.startEnrollment}
        onConfirmEnrollment={twoFactorState.confirmEnrollment}
        onSavePolicy={twoFactorState.savePolicy}
        onRegenerateRecoveryCodes={twoFactorState.regenerateRecoveryCodes}
        onDisableTwoFactor={twoFactorState.disableTwoFactor}
      />

      <RecoveryCodesCard
        generatedRecoveryCodes={twoFactorState.generatedRecoveryCodes}
        twoFactorSaving={twoFactorState.twoFactorSaving}
        recoveryCopyStatus={twoFactorState.recoveryCopyStatus}
        lastCopiedRecoveryCode={twoFactorState.lastCopiedRecoveryCode}
        onCopyAllRecoveryCodes={twoFactorState.copyAllRecoveryCodes}
        onCopyRecoveryCode={twoFactorState.copyRecoveryCode}
      />

      <SystemDiagnosticsGrid />
    </div>
  );
}
