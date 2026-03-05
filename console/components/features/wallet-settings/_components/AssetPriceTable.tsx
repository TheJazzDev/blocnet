'use client';

import { Loader2, Save } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import type { WalletAssetCode, WalletAssetPriceConfig } from '@/lib/api-client';

export type AssetPriceDraft = {
  providerId: string;
  fallbackUsdPrice: string;
  isActive: boolean;
};

export function AssetPriceTable({
  loading,
  canMutate,
  assetPriceConfigs,
  assetPriceDrafts,
  savingPriceAsset,
  onDraftChange,
  onSaveAsset,
}: {
  loading: boolean;
  canMutate: boolean;
  assetPriceConfigs: WalletAssetPriceConfig[];
  assetPriceDrafts: Record<string, AssetPriceDraft>;
  savingPriceAsset: WalletAssetCode | null;
  onDraftChange: (asset: WalletAssetCode, draft: Partial<AssetPriceDraft>) => void;
  onSaveAsset: (asset: WalletAssetCode) => void;
}) {
  if (loading) {
    return <p className="text-sm text-muted-foreground py-10">Loading...</p>;
  }

  if (assetPriceConfigs.length === 0) {
    return <p className="text-sm text-muted-foreground">No asset price configs configured.</p>;
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Asset</TableHead>
          <TableHead>Provider ID</TableHead>
          <TableHead>Fallback USD</TableHead>
          <TableHead>Active</TableHead>
          <TableHead className="w-[130px]" />
        </TableRow>
      </TableHeader>
      <TableBody>
        {assetPriceConfigs.map((row) => {
          const draft = assetPriceDrafts[row.asset];
          if (!draft) return null;
          return (
            <TableRow key={row.id}>
              <TableCell>
                <Badge variant="secondary">{row.asset}</Badge>
              </TableCell>
              <TableCell>
                <Input
                  value={draft.providerId}
                  onChange={(e) => onDraftChange(row.asset, { providerId: e.target.value })}
                  placeholder="coingecko id"
                  disabled={!canMutate}
                />
              </TableCell>
              <TableCell>
                <Input
                  value={draft.fallbackUsdPrice}
                  onChange={(e) => onDraftChange(row.asset, { fallbackUsdPrice: e.target.value })}
                  disabled={!canMutate}
                />
              </TableCell>
              <TableCell>
                <Select
                  value={draft.isActive ? 'true' : 'false'}
                  onValueChange={(next) => onDraftChange(row.asset, { isActive: next === 'true' })}
                  disabled={!canMutate}
                >
                  <SelectTrigger className="w-[90px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Yes</SelectItem>
                    <SelectItem value="false">No</SelectItem>
                  </SelectContent>
                </Select>
              </TableCell>
              <TableCell>
                <Button
                  size="sm"
                  onClick={() => onSaveAsset(row.asset)}
                  disabled={!canMutate || savingPriceAsset === row.asset}
                >
                  {savingPriceAsset === row.asset ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : (
                    <Save className="h-4 w-4" />
                  )}
                  Save
                </Button>
              </TableCell>
            </TableRow>
          );
        })}
      </TableBody>
    </Table>
  );
}

