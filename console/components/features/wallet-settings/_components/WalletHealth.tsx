'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Loader2, RefreshCw } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import type { AdminWalletHealth } from '@/lib/api-client';
import { boolBadge, formatAmount, formatInteger, renderCountGroup } from './utils';

export function WalletHealth({
  healthLoading,
  healthError,
  walletHealth,
  onRefresh,
}: {
  healthLoading: boolean;
  healthError: string | null;
  walletHealth: AdminWalletHealth | null;
  onRefresh: () => void;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0">
        <CardTitle className="text-base">Wallet Health</CardTitle>
        <Button variant="outline" size="sm" onClick={onRefresh} disabled={healthLoading}>
          {healthLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
          Refresh
        </Button>
      </CardHeader>
      <CardContent className="space-y-4">
        {healthLoading ? (
          <p className="text-sm text-muted-foreground">Loading...</p>
        ) : healthError ? (
          <p className="text-sm text-destructive">{healthError}</p>
        ) : !walletHealth ? (
          <p className="text-sm text-muted-foreground">No wallet health data available.</p>
        ) : (
          <>
            <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
              <span>Last check: {new Date(walletHealth.timestamp).toLocaleString()}</span>
              {boolBadge(walletHealth.flags.walletEnabled, 'Wallet On', 'Wallet Off')}
              {boolBadge(walletHealth.flags.depositsEnabled, 'Deposits On', 'Deposits Off')}
              {boolBadge(walletHealth.flags.withdrawalsEnabled, 'Withdrawals On', 'Withdrawals Off')}
              <Badge variant="outline">{walletHealth.flags.turnkeyExecutionMode}</Badge>
            </div>

            <div className="rounded-lg border p-3">
              <p className="text-sm font-medium">Turnkey Provider</p>
              <div className="mt-2 flex flex-wrap items-center gap-2 text-xs">
                {boolBadge(walletHealth.turnkey.connectivity.ok, 'Connected', 'Disconnected')}
                {boolBadge(walletHealth.turnkey.connectivity.simulated, 'Simulated', 'Live')}
                {boolBadge(walletHealth.turnkey.configured.organizationId, 'Org ID', 'Org Missing')}
                {boolBadge(walletHealth.turnkey.configured.apiPublicKey, 'Public Key', 'Public Missing')}
                {boolBadge(walletHealth.turnkey.configured.apiPrivateKey, 'Private Key', 'Private Missing')}
                {boolBadge(walletHealth.turnkey.configured.apiKeyId, 'API Key ID', 'API Key ID Missing')}
              </div>
              {walletHealth.turnkey.connectivity.error ? (
                <p className="mt-2 text-xs text-destructive">{walletHealth.turnkey.connectivity.error}</p>
              ) : null}
            </div>

            <div className="grid gap-3 md:grid-cols-2">
              {walletHealth.networks.map((network) => (
                <div key={network.chainEnvironment} className="rounded-lg border p-3">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium">
                      {network.chainEnvironment.toUpperCase()} (Chain {formatInteger(network.chainId)})
                    </p>
                    {boolBadge(network.rpcReachable, 'RPC Reachable', 'RPC Down')}
                  </div>
                  <div className="mt-2 space-y-1 text-xs text-muted-foreground">
                    <p>Latest block: {network.latestBlock == null ? 'n/a' : formatInteger(network.latestBlock)}</p>
                    <p>Deposit start block: {network.depositStartBlock == null ? 'n/a' : formatInteger(network.depositStartBlock)}</p>
                    <p>Confirmations required: {formatInteger(network.confirmationsRequired)}</p>
                    <p>Token address configured: {network.tokenAddressConfigured ? 'yes' : 'no'}</p>
                    <p>Treasury wallet ID configured: {network.treasuryWalletIdConfigured ? 'yes' : 'no'}</p>
                    <p>Treasury sweep address configured: {network.treasurySweepAddressConfigured ? 'yes' : 'no'}</p>
                    {network.rpcError ? <p className="text-destructive">{network.rpcError}</p> : null}
                  </div>
                </div>
              ))}
            </div>

            <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
              {renderCountGroup('Wallets', walletHealth.counts.walletsByStatus)}
              {renderCountGroup('Deposits', walletHealth.counts.depositsByStatus)}
              {renderCountGroup('Sweeps', walletHealth.counts.sweepJobsByStatus)}
              {renderCountGroup('Withdrawals', walletHealth.counts.withdrawalsByStatus)}
            </div>

            <div className="space-y-3 rounded-lg border p-3">
              <p className="text-sm font-medium">Economy Snapshot</p>

              <div className="grid gap-3 md:grid-cols-2">
                <div className="space-y-2 rounded border p-2">
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">Wallet Asset Holdings</p>
                  {walletHealth.economy.walletAssetHoldings.length === 0 ? (
                    <p className="text-xs text-muted-foreground">No wallet balances found.</p>
                  ) : (
                    walletHealth.economy.walletAssetHoldings.map((row) => (
                      <div key={row.asset} className="rounded border p-2 text-xs text-muted-foreground">
                        <div className="flex items-center justify-between gap-2">
                          <Badge variant="secondary">{row.asset}</Badge>
                          <span className="font-medium text-foreground">{formatAmount(row.totalBalance)}</span>
                        </div>
                        <p className="mt-1">
                          Avail {formatAmount(row.totalAvailable)} | Pending {formatAmount(row.totalPending)} | Locked {formatAmount(row.totalLocked)}
                        </p>
                        <p>Accounts: {formatInteger(row.accounts)}</p>
                      </div>
                    ))
                  )}
                </div>

                <div className="space-y-2 rounded border p-2">
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">Credited Deposits (By Asset)</p>
                  {walletHealth.economy.creditedDepositsTotals.length === 0 ? (
                    <p className="text-xs text-muted-foreground">No credited deposits yet.</p>
                  ) : (
                    walletHealth.economy.creditedDepositsTotals.map((row) => (
                      <div key={row.asset} className="rounded border p-2 text-xs text-muted-foreground">
                        <div className="flex items-center justify-between gap-2">
                          <Badge variant="secondary">{row.asset}</Badge>
                          <span className="font-medium text-foreground">{formatAmount(row.totalAmount)}</span>
                        </div>
                        <p className="mt-1">Deposits: {formatInteger(row.count)}</p>
                      </div>
                    ))
                  )}
                </div>
              </div>

              <div className="space-y-2 rounded border p-2">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Tip Currency Totals</p>
                {walletHealth.economy.tipCurrencyTotals.length === 0 ? (
                  <p className="text-xs text-muted-foreground">No tip currency balances found.</p>
                ) : (
                  walletHealth.economy.tipCurrencyTotals.map((row) => (
                    <div key={row.currencyCode} className="rounded border p-2 text-xs text-muted-foreground">
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge variant="secondary">{row.currencyCode}</Badge>
                        <Badge variant="outline">{row.kind}</Badge>
                        <span>
                          Holders: {formatInteger(row.holders)} | Tx: {formatInteger(row.transactions)}
                        </span>
                      </div>
                      <p className="mt-1">
                        User balance: {formatAmount(row.totalUserBalance)} {row.symbol}
                      </p>
                      <p>
                        Tipped: {formatAmount(row.totalTipped)} {row.symbol} | Fees: {formatAmount(row.totalFees)} {row.symbol}
                      </p>
                    </div>
                  ))
                )}
              </div>

              <div className="grid gap-3 md:grid-cols-4">
                <div className="rounded border p-2 text-xs">
                  <p className="text-muted-foreground">Lifetime Mined (BNP)</p>
                  <p className="font-medium">{formatInteger(walletHealth.economy.mining.lifetimeMinedMcr)}</p>
                </div>
                <div className="rounded border p-2 text-xs">
                  <p className="text-muted-foreground">Lifetime Claimed (BNP)</p>
                  <p className="font-medium">
                    {formatInteger(walletHealth.economy.mining.lifetimeClaimedMcr)}
                  </p>
                </div>
                <div className="rounded border p-2 text-xs">
                  <p className="text-muted-foreground">Unclaimed (BNP)</p>
                  <p className="font-medium">
                    {formatInteger(walletHealth.economy.mining.lifetimeUnclaimedMcr)}
                  </p>
                </div>
                <div className="rounded border p-2 text-xs">
                  <p className="text-muted-foreground">Total Miners</p>
                  <p className="font-medium">{formatInteger(walletHealth.economy.mining.totalMiners)}</p>
                </div>
              </div>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}

