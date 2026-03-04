'use client';

import { PageHeader } from '@/components/page-header';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import { useAdminSession } from '@/components/admin-shell';
import { canMutateWallet } from '@/lib/rbac';
import { RuntimeControls } from './RuntimeControls';
import { ManualReprocess } from './ManualReprocess';
import { WalletHealth } from './WalletHealth';
import { RiskLimitsTable } from './RiskLimitsTable';
import { FeeConfigsTable } from './FeeConfigsTable';
import { AssetPriceTable } from './AssetPriceTable';
import { useWalletSettings } from '../_hooks/use-wallet-settings';

export default function WalletSettingsPageClient() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);
  const state = useWalletSettings();

  return (
    <div className='space-y-6'>
      <PageHeader
        title='Wallet Settings'
        description='Manage withdrawal limits, fee policies, and wallet operations health.'
      />

      {!canMutate && (
        <Card className='border-amber-500/30 bg-amber-500/5'>
          <CardContent className='pt-6 text-sm text-amber-200'>
            Read-only access. Owner/Admin roles are required to mutate wallet settings.
          </CardContent>
        </Card>
      )}

      <RuntimeControls
        canMutate={canMutate}
        loading={state.loading}
        runtimeConfig={state.runtimeConfig}
        savingRuntimeConfig={state.savingRuntimeConfig}
        runtimeStatus={state.runtimeStatus}
        onSaveRuntime={() => void state.saveRuntime()}
        setRuntimeConfig={state.setRuntimeConfig}
        onToggleWithdrawalAsset={state.toggleWithdrawalAsset}
      />

      <ManualReprocess
        canMutate={canMutate}
        availableChainEnvironments={state.availableChainEnvironments}
        manualTxHash={state.manualTxHash}
        setManualTxHash={state.setManualTxHash}
        manualChainEnvironment={state.manualChainEnvironment}
        setManualChainEnvironment={state.setManualChainEnvironment}
        manualAsset={state.manualAsset}
        setManualAsset={state.setManualAsset}
        manualReprocessLoading={state.manualReprocessLoading}
        manualReprocessStatus={state.manualReprocessStatus}
        manualReprocessResult={state.manualReprocessResult}
        onRun={() => void state.runManualDepositReprocess()}
      />

      <WalletHealth
        healthLoading={state.healthLoading}
        healthError={state.healthError}
        walletHealth={state.walletHealth}
        onRefresh={() => void state.loadWalletHealth()}
      />

      {state.error && (
        <Card>
          <CardContent className='pt-6 text-sm text-destructive'>
            {state.error}
          </CardContent>
        </Card>
      )}

      {!state.hasData && state.loading ? (
        <Card>
          <CardContent className='pt-6'>
            <LoadingSpinner className='py-10' />
          </CardContent>
        </Card>
      ) : (
        <>
          <Card>
            <CardHeader>
              <CardTitle className='text-base'>Risk Limits</CardTitle>
            </CardHeader>
            <CardContent>
              <RiskLimitsTable
                loading={state.loading}
                canMutate={canMutate}
                riskLimits={state.riskLimits}
                riskDrafts={state.riskDrafts}
                savingRiskTier={state.savingRiskTier}
                onDraftChange={state.onRiskDraftChange}
                onSaveTier={(tier) => void state.saveRisk(tier)}
              />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className='text-base'>Fee Configs</CardTitle>
            </CardHeader>
            <CardContent>
              <FeeConfigsTable
                loading={state.loading}
                canMutate={canMutate}
                feeConfigs={state.feeConfigs}
                feeDrafts={state.feeDrafts}
                savingFeeKey={state.savingFeeKey}
                onDraftChange={state.onFeeDraftChange}
                onSaveKey={(key) => void state.saveFee(key)}
              />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className='text-base'>Asset Price Fallbacks</CardTitle>
            </CardHeader>
            <CardContent>
              <AssetPriceTable
                loading={state.loading}
                canMutate={canMutate}
                assetPriceConfigs={state.assetPriceConfigs}
                assetPriceDrafts={state.assetPriceDrafts}
                savingPriceAsset={state.savingPriceAsset}
                onDraftChange={state.onAssetPriceDraftChange}
                onSaveAsset={(asset) => void state.saveAssetPrice(asset)}
              />
            </CardContent>
          </Card>
        </>
      )}
    </div>
  );
}
