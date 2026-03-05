"use client";

import { Loader2, RefreshCw } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";
import { useTipSettings } from "../_hooks/use-tip-settings";
import { ActiveTipCurrencyCard } from "./ActiveTipCurrencyCard";
import { TipCurrencyCard } from "./TipCurrencyCard";

export default function TipSettingsPageClient() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);
  const state = useTipSettings();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Tip Settings"
        description="Manage active tipping currency, sender fee policy, and fee vault balances."
      >
        <Button variant="outline" onClick={() => void state.load()} disabled={state.loading}>
          {state.loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          Refresh
        </Button>
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Read-only access. Owner/Admin roles are required to update tipping settings.
          </CardContent>
        </Card>
      )}

      {state.error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{state.error}</CardContent>
        </Card>
      )}

      <ActiveTipCurrencyCard
        loading={state.loading}
        canMutate={canMutate}
        settings={state.settings}
        activeCurrencyCode={state.activeCurrencyCode}
        setActiveCurrencyCode={state.setActiveCurrencyCode}
        activating={state.activating}
        onActivate={state.activateCurrency}
      />

      {state.loading ? (
        <Card>
          <CardContent className="pt-6">
            <LoadingSpinner className="py-10" />
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4">
          {state.currencies.map((row) => {
            const draft = state.drafts[row.code];
            if (!draft) return null;
            return (
              <TipCurrencyCard
                key={row.code}
                row={row}
                draft={draft}
                canMutate={canMutate}
                saving={state.savingCode === row.code}
                onDraftChange={(patch) => state.updateDraft(row.code, patch)}
                onSave={() => state.saveCurrency(row.code)}
              />
            );
          })}
        </div>
      )}
    </div>
  );
}
