"use client";

import Link from "next/link";
import { Loader2, RefreshCw, Trophy } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";
import { useMiningAdmin } from "../_hooks/use-mining-admin";
import { MiningConfigCard } from "./MiningConfigCard";
import { MiningMetricsCard } from "./MiningMetricsCard";
import { ReferralSupportCard } from "./ReferralSupportCard";

export default function MiningPageClient() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);
  const state = useMiningAdmin();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Mining"
        description="Tune cycle economics and review referral engagement metrics."
      >
        <Button variant="outline" asChild>
          <Link href="/mining/leaderboard">
            <Trophy className="h-4 w-4" />
            Open Leaderboard
          </Link>
        </Button>
        <Button
          variant="outline"
          onClick={() => void state.load()}
          disabled={state.loading || state.saving}
        >
          {state.loading ? (
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
            Read-only mode. Owner/Admin roles are required to update mining config.
          </CardContent>
        </Card>
      )}

      {state.error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{state.error}</CardContent>
        </Card>
      )}

      {state.loading ? (
        <Card>
          <CardContent className="pt-6">
            <LoadingSpinner className="py-10" />
          </CardContent>
        </Card>
      ) : (
        <>
          <MiningConfigCard
            config={state.config}
            canMutate={canMutate}
            saving={state.saving}
            onChange={state.setConfig}
            onSave={state.save}
          />
          <MiningMetricsCard metrics={state.metrics} />
          <ReferralSupportCard
            canMutate={canMutate}
            supportUserIdOrEmail={state.supportUserIdOrEmail}
            setSupportUserIdOrEmail={state.setSupportUserIdOrEmail}
            supportReferralCode={state.supportReferralCode}
            setSupportReferralCode={state.setSupportReferralCode}
            supportSaving={state.supportSaving}
            supportError={state.supportError}
            supportSuccess={state.supportSuccess}
            supportReferralLookup={state.supportReferralLookup}
            onBind={state.bindReferralBySupport}
          />
        </>
      )}
    </div>
  );
}
