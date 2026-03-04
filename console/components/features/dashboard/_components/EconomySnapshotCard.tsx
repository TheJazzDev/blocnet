'use client';

import { TrendingUp } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import type { AdminWalletHealth } from '@/lib/api-client';
import { formatTokenAmount } from './dashboard-utils';
import { MetricCell } from './MetricCell';

type EconomySnapshotCardProps = {
  loading: boolean;
  walletHealth: AdminWalletHealth | null;
};

export function EconomySnapshotCard({
  loading,
  walletHealth,
}: EconomySnapshotCardProps) {
  const walletAssetTotals = walletHealth?.economy.walletAssetHoldings ?? [];
  const tipCurrencyTotals = walletHealth?.economy.tipCurrencyTotals ?? [];
  const miningTotals = walletHealth?.economy.mining;

  const bntHolding = walletAssetTotals.find((row) => row.asset === 'BNT');
  const bnbHolding = walletAssetTotals.find((row) => row.asset === 'BNB');
  const usdtHolding = walletAssetTotals.find((row) => row.asset === 'USDT');

  const bnpTip = tipCurrencyTotals.find((row) => row.currencyCode === 'BNP');
  const bntTip = tipCurrencyTotals.find((row) => row.currencyCode === 'BNT');
  const questTotals = walletHealth?.economy.quests;

  const questShareOfClaimedPct =
    miningTotals && miningTotals.lifetimeClaimedMcr > 0
      ? ((questTotals?.rewardPointsTotal ?? 0) / miningTotals.lifetimeClaimedMcr) *
        100
      : 0;

  return (
    <Card>
      <CardHeader>
        <CardTitle className='flex items-center gap-2 text-base'>
          <TrendingUp className='h-4 w-4' />
          Economy Snapshot
        </CardTitle>
        <CardDescription>
          Live aggregate balances and mining totals for admin comms and reporting.
        </CardDescription>
      </CardHeader>
      <CardContent>
        {loading ? (
          <LoadingSpinner className='py-8' />
        ) : walletHealth ? (
          <div className='space-y-3'>
            <div className='grid gap-3 sm:grid-cols-2 xl:grid-cols-4'>
              <MetricCell
                label='Total BNT Held'
                value={formatTokenAmount(bntHolding?.totalBalance)}
                hint={`${bntHolding?.accounts ?? 0} wallets`}
              />
              <MetricCell
                label='Total BNB Held'
                value={formatTokenAmount(bnbHolding?.totalBalance)}
                hint={`${bnbHolding?.accounts ?? 0} wallets`}
              />
              <MetricCell
                label='Total USDT Held'
                value={formatTokenAmount(usdtHolding?.totalBalance)}
                hint={`${usdtHolding?.accounts ?? 0} wallets`}
              />
              <MetricCell
                label='Total BNP Mined'
                value={(miningTotals?.lifetimeMinedMcr ?? 0).toLocaleString()}
                hint={`${miningTotals?.totalMiners ?? 0} miners`}
              />
              <MetricCell
                label='Total BNP Claimed'
                value={(miningTotals?.lifetimeClaimedMcr ?? 0).toLocaleString()}
                hint='Lifetime'
              />
              <MetricCell
                label='Total BNP Unclaimed'
                value={(miningTotals?.lifetimeUnclaimedMcr ?? 0).toLocaleString()}
                hint='Lifetime outstanding'
              />
              <MetricCell
                label='BNP Tip Wallet Balance'
                value={formatTokenAmount(bnpTip?.totalUserBalance)}
                hint={`${bnpTip?.holders ?? 0} holders`}
              />
              <MetricCell
                label='BNT Tip Wallet Balance'
                value={formatTokenAmount(bntTip?.totalUserBalance)}
                hint={`${bntTip?.holders ?? 0} holders`}
              />
              <MetricCell
                label='Quest BNP Distributed'
                value={(questTotals?.rewardPointsTotal ?? 0).toLocaleString()}
                hint={`${(questTotals?.rewardedUsersTotal ?? 0).toLocaleString()} users rewarded`}
              />
              <MetricCell
                label='Quest Reward Events'
                value={(questTotals?.rewardEventsTotal ?? 0).toLocaleString()}
                hint={`${(questTotals?.completedUserQuestsTotal ?? 0).toLocaleString()} quest completions`}
              />
              <MetricCell
                label='Quest Share Of Claimed'
                value={`${questShareOfClaimedPct.toFixed(1)}%`}
                hint='Quest rewards / claimed BNP'
              />
              <MetricCell
                label='Quest Submissions'
                value={(questTotals?.submissions.total ?? 0).toLocaleString()}
                hint={`${(questTotals?.submissions.approved ?? 0).toLocaleString()} approved · ${(questTotals?.submissions.pending ?? 0).toLocaleString()} pending`}
              />
            </div>
            <p className='text-xs text-muted-foreground'>
              Wallet runtime currently tracks BNT, BNB, and USDT. USDC/BUSD are not yet enabled assets.
            </p>
          </div>
        ) : (
          <p className='text-sm text-muted-foreground'>
            Economy metrics are currently unavailable.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
