"use client";

import { Users, RefreshCw, Loader2 } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";
import { ReferralBindingCard } from "./ReferralBindingCard";
import { ReferralMetricsCard } from "./ReferralMetricsCard";
import { useReferralManagement } from "../_hooks/use-referral-management";

export default function ReferralsPageClient() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);
  const state = useReferralManagement();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Referrals"
        description="Manage referral codes and bind users to referrers for support cases."
      >
        <Button
          variant="outline"
          onClick={() => void state.loadMetrics()}
          disabled={state.metricsLoading}
        >
          {state.metricsLoading ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <RefreshCw className="h-4 w-4" />
          )}
          Refresh
        </Button>
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Read-only mode. Owner/Admin roles are required to bind referrals.
          </CardContent>
        </Card>
      )}

      <ReferralBindingCard
        canMutate={canMutate}
        userIdOrEmail={state.userIdOrEmail}
        setUserIdOrEmail={state.setUserIdOrEmail}
        referralCode={state.referralCode}
        setReferralCode={state.setReferralCode}
        saving={state.saving}
        error={state.error}
        success={state.success}
        referralLookup={state.referralLookup}
        onBind={state.bindReferral}
      />

      <ReferralMetricsCard
        metrics={state.metrics}
        loading={state.metricsLoading}
        error={state.metricsError}
      />
    </div>
  );
}
