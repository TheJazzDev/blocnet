'use client';

import { Loader2, RefreshCw } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import type {
  AdminWalletDepositReprocessResponse,
  WalletAssetCode,
} from '@/lib/api-client';
import { boolBadge, formatInteger } from './utils';

export function ManualReprocess({
  canMutate,
  availableChainEnvironments,
  manualTxHash,
  setManualTxHash,
  manualChainEnvironment,
  setManualChainEnvironment,
  manualAsset,
  setManualAsset,
  manualReprocessLoading,
  manualReprocessStatus,
  manualReprocessResult,
  onRun,
}: {
  canMutate: boolean;
  availableChainEnvironments: ('testnet' | 'mainnet')[];
  manualTxHash: string;
  setManualTxHash: (v: string) => void;
  manualChainEnvironment: 'testnet' | 'mainnet';
  setManualChainEnvironment: (v: 'testnet' | 'mainnet') => void;
  manualAsset: 'all' | WalletAssetCode;
  setManualAsset: (v: 'all' | WalletAssetCode) => void;
  manualReprocessLoading: boolean;
  manualReprocessStatus: string | null;
  manualReprocessResult: AdminWalletDepositReprocessResponse | null;
  onRun: () => void;
}) {
  return (
    <Card>
      <CardHeader className='flex flex-row items-center justify-between space-y-0'>
        <CardTitle className='text-base'>Manual Deposit Reprocess</CardTitle>
        <Button
          size='sm'
          onClick={onRun}
          disabled={
            !canMutate || manualReprocessLoading || !manualTxHash.trim()
          }>
          {manualReprocessLoading ? (
            <Loader2 className='h-4 w-4 animate-spin' />
          ) : (
            <RefreshCw className='h-4 w-4' />
          )}
          Reprocess Tx
        </Button>
      </CardHeader>
      <CardContent className='space-y-4'>
        <p className='text-sm text-muted-foreground'>
          Replay one on-chain transaction through the deposit indexer and credit
          path without changing runtime scan windows.
        </p>
        <div className='grid gap-3 md:grid-cols-3'>
          <div className='space-y-1.5 md:col-span-2'>
            <p className='text-xs uppercase tracking-wide text-muted-foreground'>
              Transaction Hash
            </p>
            <Input
              placeholder='0x...'
              value={manualTxHash}
              onChange={(e) => setManualTxHash(e.target.value)}
              disabled={!canMutate || manualReprocessLoading}
            />
          </div>
          <div className='space-y-1.5'>
            <p className='text-xs uppercase tracking-wide text-muted-foreground'>
              Chain Environment
            </p>
            <Select
              value={manualChainEnvironment}
              onValueChange={(v: 'testnet' | 'mainnet') =>
                setManualChainEnvironment(v)
              }
              disabled={!canMutate || manualReprocessLoading}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {availableChainEnvironments.map((env) => (
                  <SelectItem key={env} value={env}>
                    {env.toUpperCase()}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <div className='space-y-1.5'>
          <p className='text-xs uppercase tracking-wide text-muted-foreground'>
            Asset Filter
          </p>
          <Select
            value={manualAsset}
            onValueChange={(v: 'all' | WalletAssetCode) => setManualAsset(v)}
            disabled={!canMutate || manualReprocessLoading}>
            <SelectTrigger className='max-w-[220px]'>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value='all'>All assets</SelectItem>
              <SelectItem value='BNT'>BNT</SelectItem>
              <SelectItem value='BNB'>BNB</SelectItem>
              <SelectItem value='USDT'>USDT</SelectItem>
            </SelectContent>
          </Select>
        </div>

        {manualReprocessStatus ? (
          <p className='text-xs text-muted-foreground'>
            {manualReprocessStatus}
          </p>
        ) : null}

        {manualReprocessResult ? (
          <div className='space-y-3 rounded-lg border p-3'>
            <div className='flex flex-wrap items-center gap-2 text-xs text-muted-foreground'>
              <Badge variant='outline'>{manualReprocessResult.txHash}</Badge>
              <Badge variant='secondary'>
                {manualReprocessResult.chainEnvironment.toUpperCase()}
              </Badge>
              <span>
                Tx Block: {formatInteger(manualReprocessResult.txBlockNumber)} |
                Head: {formatInteger(manualReprocessResult.headBlockNumber)}
              </span>
            </div>
            <div className='grid gap-3 md:grid-cols-3'>
              <div className='rounded border p-2 text-xs'>
                <p className='text-muted-foreground'>Matched Assets</p>
                <p className='font-medium'>
                  {formatInteger(manualReprocessResult.summary.matchedAssets)}
                </p>
              </div>
              <div className='rounded border p-2 text-xs'>
                <p className='text-muted-foreground'>Detected Deposits</p>
                <p className='font-medium'>
                  {formatInteger(
                    manualReprocessResult.summary.detectedDeposits,
                  )}
                </p>
              </div>
              <div className='rounded border p-2 text-xs'>
                <p className='text-muted-foreground'>Credited Deposits</p>
                <p className='font-medium'>
                  {formatInteger(
                    manualReprocessResult.summary.creditedDeposits,
                  )}
                </p>
              </div>
            </div>
            <div className='space-y-2'>
              {manualReprocessResult.networkResults.map((row) => (
                <div
                  key={row.asset}
                  className='rounded border p-2 text-xs text-muted-foreground'>
                  <div className='flex flex-wrap items-center gap-2'>
                    <Badge variant='secondary'>{row.asset}</Badge>
                    {boolBadge(row.matched, 'Matched', 'No Match')}
                    <span>Detected: {formatInteger(row.detectedCount)}</span>
                    <span>Credited: {formatInteger(row.creditedCount)}</span>
                  </div>
                  {row.reason ? <p className='mt-1'>{row.reason}</p> : null}
                  {row.depositIds.length > 0 ? (
                    <p className='mt-1 break-all'>
                      Deposit IDs: {row.depositIds.join(', ')}
                    </p>
                  ) : null}
                </div>
              ))}
            </div>
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
}
