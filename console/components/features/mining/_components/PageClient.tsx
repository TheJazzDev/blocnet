"use client";

import Link from "next/link";
import { Loader2, RefreshCw, Trophy } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { AccessDeniedCard } from "@/components/shared/AccessDeniedCard";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateMining, canViewMining, canViewMiningHistory } from "@/lib/rbac";
import { useMiningAdmin } from "../_hooks/use-mining-admin";
import { MiningConfigCard } from "./MiningConfigCard";
import { MiningConfigHistoryCard } from "./MiningConfigHistoryCard";
import { MiningMetricsCard } from "./MiningMetricsCard";

const TITLE = "Mining";
const DESCRIPTION = "Tune cycle economics and review mining engagement metrics.";

export default function MiningPageClient() {
  const session = useAdminSession();
  const canView = canViewMining(session.effectiveRoles);
  const canMutate = canMutateMining(session.effectiveRoles);
  const canViewHistory = canViewMiningHistory(session.effectiveRoles);
  const state = useMiningAdmin({ enabled: canView });

  if (!canView) {
    return (
      <AccessDeniedCard
        title={TITLE}
        description={DESCRIPTION}
        requirement="Owner, dev or admin role is required to view mining configuration."
      />
    );
  }

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader title={TITLE} description={DESCRIPTION}>
        <Button variant="outline" asChild>
          <Link href="/mining/leaderboard">
            <Trophy className="h-4 w-4" />
            Open Leaderboard
          </Link>
        </Button>
        <Button
          variant="outline"
          onClick={() => void state.refresh()}
          disabled={state.refreshing || state.saving}
        >
          {state.refreshing ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <RefreshCw className="h-4 w-4" />
          )}
          Refresh
        </Button>
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-4 text-xs text-amber-200 sm:pt-6 sm:text-sm">
            Read-only mode. Your role can view mining config but not change it.
          </CardContent>
        </Card>
      )}

      {state.error && (
        <Card className="border-destructive/35 bg-destructive/10">
          <CardContent className="pt-4 text-xs text-destructive sm:pt-6 sm:text-sm">
            {state.error}
          </CardContent>
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
            changedFields={state.changedFields}
            canMutate={canMutate}
            saving={state.saving}
            onFieldChange={state.setField}
            onReset={state.reset}
            onSave={state.save}
          />
          {canViewHistory && <MiningConfigHistoryCard />}
          <MiningMetricsCard metrics={state.metrics} />
        </>
      )}
    </div>
  );
}
