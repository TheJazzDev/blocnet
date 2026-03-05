'use client';

import { Loader2, Save } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import type { WalletFeeConfig } from '@/lib/api-client';

export type FeeDraft = {
  flatFee: string;
  percentFee: string;
  minFee: string;
  maxFee: string;
  isActive: boolean;
};

export function FeeConfigsTable({
  loading,
  canMutate,
  feeConfigs,
  feeDrafts,
  savingFeeKey,
  onDraftChange,
  onSaveKey,
}: {
  loading: boolean;
  canMutate: boolean;
  feeConfigs: WalletFeeConfig[];
  feeDrafts: Record<string, FeeDraft>;
  savingFeeKey: string | null;
  onDraftChange: (key: string, draft: Partial<FeeDraft>) => void;
  onSaveKey: (key: string) => void;
}) {
  if (loading) {
    return <p className="text-sm text-muted-foreground py-10">Loading...</p>;
  }

  if (feeConfigs.length === 0) {
    return <p className="text-sm text-muted-foreground">No fee configs configured.</p>;
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Key</TableHead>
          <TableHead>Flat</TableHead>
          <TableHead>Percent</TableHead>
          <TableHead>Min</TableHead>
          <TableHead>Max</TableHead>
          <TableHead>Active</TableHead>
          <TableHead className="w-[130px]" />
        </TableRow>
      </TableHeader>
      <TableBody>
        {feeConfigs.map((row) => {
          const draft = feeDrafts[row.key];
          if (!draft) return null;
          return (
            <TableRow key={row.id}>
              <TableCell>
                <Badge variant="secondary">{row.key}</Badge>
              </TableCell>
              <TableCell>
                <Input value={draft.flatFee} onChange={(e) => onDraftChange(row.key, { flatFee: e.target.value })} disabled={!canMutate} />
              </TableCell>
              <TableCell>
                <Input value={draft.percentFee} onChange={(e) => onDraftChange(row.key, { percentFee: e.target.value })} disabled={!canMutate} />
              </TableCell>
              <TableCell>
                <Input value={draft.minFee} onChange={(e) => onDraftChange(row.key, { minFee: e.target.value })} disabled={!canMutate} />
              </TableCell>
              <TableCell>
                <Input
                  value={draft.maxFee}
                  onChange={(e) => onDraftChange(row.key, { maxFee: e.target.value })}
                  placeholder="optional"
                  disabled={!canMutate}
                />
              </TableCell>
              <TableCell>
                <Select
                  value={draft.isActive ? 'true' : 'false'}
                  onValueChange={(next) => onDraftChange(row.key, { isActive: next === 'true' })}
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
                <Button size="sm" onClick={() => onSaveKey(row.key)} disabled={!canMutate || savingFeeKey === row.key}>
                  {savingFeeKey === row.key ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
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

