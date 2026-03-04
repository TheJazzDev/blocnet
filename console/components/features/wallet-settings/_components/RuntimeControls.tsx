'use client';

import { Loader2, Save } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import type { WalletAssetCode, WalletRuntimeConfig } from '@/lib/api-client';

export function RuntimeControls({
  canMutate,
  loading,
  runtimeConfig,
  savingRuntimeConfig,
  runtimeStatus,
  onSaveRuntime,
  setRuntimeConfig,
  onToggleWithdrawalAsset,
}: {
  canMutate: boolean;
  loading: boolean;
  runtimeConfig: WalletRuntimeConfig | null;
  savingRuntimeConfig: boolean;
  runtimeStatus: string | null;
  onSaveRuntime: () => void;
  setRuntimeConfig: React.Dispatch<React.SetStateAction<WalletRuntimeConfig | null>>;
  onToggleWithdrawalAsset: (asset: WalletAssetCode) => void;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between space-y-0">
        <CardTitle className="text-base">Runtime Wallet Controls</CardTitle>
        <Button size="sm" onClick={onSaveRuntime} disabled={!canMutate || !runtimeConfig || savingRuntimeConfig || loading}>
          {savingRuntimeConfig ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          Save Runtime Config
        </Button>
      </CardHeader>
      <CardContent className="space-y-4">
        {!runtimeConfig ? (
          loading ? (
            <p className="text-sm text-muted-foreground">Loading...</p>
          ) : (
            <p className="text-sm text-muted-foreground">Runtime wallet config unavailable.</p>
          )
        ) : (
          <>
            <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Wallet</p>
                <Select
                  value={runtimeConfig.walletEnabled ? 'true' : 'false'}
                  onValueChange={(value) => setRuntimeConfig((prev) => (prev ? { ...prev, walletEnabled: value === 'true' } : prev))}
                  disabled={!canMutate || savingRuntimeConfig}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Deposits</p>
                <Select
                  value={runtimeConfig.depositsEnabled ? 'true' : 'false'}
                  onValueChange={(value) => setRuntimeConfig((prev) => (prev ? { ...prev, depositsEnabled: value === 'true' } : prev))}
                  disabled={!canMutate || savingRuntimeConfig}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Withdrawals</p>
                <Select
                  value={runtimeConfig.withdrawalsEnabled ? 'true' : 'false'}
                  onValueChange={(value) => setRuntimeConfig((prev) => (prev ? { ...prev, withdrawalsEnabled: value === 'true' } : prev))}
                  disabled={!canMutate || savingRuntimeConfig}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Realtime Deposits</p>
                <Select
                  value={runtimeConfig.depositRealtimeEnabled ? 'true' : 'false'}
                  onValueChange={(value) =>
                    setRuntimeConfig((prev) => (prev ? { ...prev, depositRealtimeEnabled: value === 'true' } : prev))
                  }
                  disabled={!canMutate || savingRuntimeConfig}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Enabled</SelectItem>
                    <SelectItem value="false">Disabled</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid gap-3 md:grid-cols-2">
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Deposit Confirmations</p>
                <Input
                  type="number"
                  min={1}
                  max={400}
                  value={runtimeConfig.depositConfirmations}
                  onChange={(event) => {
                    const next = Number(event.target.value);
                    setRuntimeConfig((prev) =>
                      prev
                        ? {
                            ...prev,
                            depositConfirmations: Number.isFinite(next) ? Math.min(Math.max(Math.floor(next), 1), 400) : prev.depositConfirmations,
                          }
                        : prev,
                    );
                  }}
                  disabled={!canMutate || savingRuntimeConfig}
                />
              </div>
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Withdrawal Confirmations</p>
                <Input
                  type="number"
                  min={1}
                  max={400}
                  value={runtimeConfig.withdrawalConfirmations}
                  onChange={(event) => {
                    const next = Number(event.target.value);
                    setRuntimeConfig((prev) =>
                      prev
                        ? {
                            ...prev,
                            withdrawalConfirmations: Number.isFinite(next)
                              ? Math.min(Math.max(Math.floor(next), 1), 400)
                              : prev.withdrawalConfirmations,
                          }
                        : prev,
                    );
                  }}
                  disabled={!canMutate || savingRuntimeConfig}
                />
              </div>
            </div>

            <div className="grid gap-3 md:grid-cols-2">
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">BSC RPC URL</p>
                <Input
                  placeholder="https://..."
                  value={runtimeConfig.bscRpcUrl ?? ''}
                  onChange={(event) => setRuntimeConfig((prev) => (prev ? { ...prev, bscRpcUrl: event.target.value } : prev))}
                  disabled={!canMutate || savingRuntimeConfig}
                />
              </div>
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">BSC RPC WS URL</p>
                <Input
                  placeholder="wss://..."
                  value={runtimeConfig.bscRpcWsUrl ?? ''}
                  onChange={(event) => setRuntimeConfig((prev) => (prev ? { ...prev, bscRpcWsUrl: event.target.value } : prev))}
                  disabled={!canMutate || savingRuntimeConfig}
                />
              </div>
            </div>

            <div className="grid gap-3 md:grid-cols-2">
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Enabled Assets</p>
                <div className="flex flex-wrap gap-2">
                  {(['BNT', 'BNB', 'USDT'] as WalletAssetCode[]).map((asset) => {
                    const selected = asset === 'BNT' ? runtimeConfig.walletAssetBntEnabled : asset === 'BNB' ? runtimeConfig.walletAssetBnbEnabled : runtimeConfig.walletAssetUsdtEnabled;
                    return (
                      <Button
                        key={asset}
                        type="button"
                        size="sm"
                        variant={selected ? 'default' : 'outline'}
                        disabled={!canMutate || savingRuntimeConfig}
                        onClick={() =>
                          setRuntimeConfig((prev) => {
                            if (!prev) return prev;
                            if (asset === 'BNT') return { ...prev, walletAssetBntEnabled: !prev.walletAssetBntEnabled };
                            if (asset === 'BNB') return { ...prev, walletAssetBnbEnabled: !prev.walletAssetBnbEnabled };
                            return { ...prev, walletAssetUsdtEnabled: !prev.walletAssetUsdtEnabled };
                          })
                        }
                      >
                        {asset}
                      </Button>
                    );
                  })}
                </div>
              </div>
              <div className="space-y-1.5">
                <p className="text-xs uppercase tracking-wide text-muted-foreground">Transfer/Withdrawal Assets</p>
                <div className="flex flex-wrap gap-2">
                  {(['BNT', 'BNB', 'USDT'] as WalletAssetCode[]).map((asset) => (
                    <Button
                      key={asset}
                      type="button"
                      size="sm"
                      variant={runtimeConfig.withdrawalEnabledAssets.includes(asset) ? 'default' : 'outline'}
                      disabled={!canMutate || savingRuntimeConfig}
                      onClick={() => onToggleWithdrawalAsset(asset)}
                    >
                      {asset}
                    </Button>
                  ))}
                </div>
              </div>
            </div>

            <p className="text-xs text-muted-foreground">Last updated: {new Date(runtimeConfig.updatedAt).toLocaleString()}</p>
          </>
        )}

        {runtimeStatus ? <p className="text-xs text-muted-foreground">{runtimeStatus}</p> : null}
      </CardContent>
    </Card>
  );
}

