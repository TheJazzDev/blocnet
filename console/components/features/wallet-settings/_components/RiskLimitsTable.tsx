'use client';

import { Loader2, Save } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import type { WalletRiskLimit } from '@/lib/api-client';

export type RiskDraft = {
  description: string;
  requiresKyc: boolean;
  maxWithdrawalPerTx: string;
  maxWithdrawalPerDay: string;
  maxInternalTransferPerDay: string;
};

export function RiskLimitsTable({
  loading,
  canMutate,
  riskLimits,
  riskDrafts,
  savingRiskTier,
  onDraftChange,
  onSaveTier,
}: {
  loading: boolean;
  canMutate: boolean;
  riskLimits: WalletRiskLimit[];
  riskDrafts: Record<string, RiskDraft>;
  savingRiskTier: string | null;
  onDraftChange: (tier: string, draft: Partial<RiskDraft>) => void;
  onSaveTier: (tier: string) => void;
}) {
  if (loading) {
    return <p className="text-sm text-muted-foreground py-10">Loading...</p>;
  }

  if (riskLimits.length === 0) {
    return <p className="text-sm text-muted-foreground">No risk tiers configured.</p>;
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Tier</TableHead>
          <TableHead>Requires KYC</TableHead>
          <TableHead>Per Tx</TableHead>
          <TableHead>Per Day</TableHead>
          <TableHead>Internal/Day</TableHead>
          <TableHead className="w-[130px]" />
        </TableRow>
      </TableHeader>
      <TableBody>
        {riskLimits.map((row) => {
          const draft = riskDrafts[row.tier];
          if (!draft) return null;
          return (
            <TableRow key={row.id}>
              <TableCell>
                <Badge variant="secondary">{row.tier}</Badge>
              </TableCell>
              <TableCell>
                <Select
                  value={draft.requiresKyc ? 'true' : 'false'}
                  onValueChange={(next) => onDraftChange(row.tier, { requiresKyc: next === 'true' })}
                  disabled={!canMutate}
                >
                  <SelectTrigger className="w-[110px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="true">Yes</SelectItem>
                    <SelectItem value="false">No</SelectItem>
                  </SelectContent>
                </Select>
              </TableCell>
              <TableCell>
                <Input
                  value={draft.maxWithdrawalPerTx}
                  onChange={(e) => onDraftChange(row.tier, { maxWithdrawalPerTx: e.target.value })}
                  disabled={!canMutate}
                />
              </TableCell>
              <TableCell>
                <Input
                  value={draft.maxWithdrawalPerDay}
                  onChange={(e) => onDraftChange(row.tier, { maxWithdrawalPerDay: e.target.value })}
                  disabled={!canMutate}
                />
              </TableCell>
              <TableCell>
                <Input
                  value={draft.maxInternalTransferPerDay}
                  onChange={(e) => onDraftChange(row.tier, { maxInternalTransferPerDay: e.target.value })}
                  disabled={!canMutate}
                />
              </TableCell>
              <TableCell>
                <Button size="sm" onClick={() => onSaveTier(row.tier)} disabled={!canMutate || savingRiskTier === row.tier}>
                  {savingRiskTier === row.tier ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
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

