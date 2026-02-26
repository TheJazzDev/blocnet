"use client";

import { Wallet, CreditCard, FileCheck, ArrowDownToLine } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";

type WalletSectionProps = {
  user: AdminUserDetail;
};

function fmtDate(value: string | null) {
  if (!value) return "—";
  try {
    return new Date(value).toLocaleString();
  } catch {
    return "—";
  }
}

function formatAtomicAmount(amountAtomic: string, decimals: number) {
  const negative = amountAtomic.startsWith("-");
  const raw = negative ? amountAtomic.slice(1) : amountAtomic;
  const padded = raw.padStart(decimals + 1, "0");
  const splitAt = padded.length - decimals;
  const whole = padded.slice(0, splitAt);
  const fraction = padded.slice(splitAt).replace(/0+$/, "");
  const composed = fraction ? `${whole}.${fraction}` : whole;
  return negative ? `-${composed}` : composed;
}

function statusBadge(status: string) {
  switch (status.toLowerCase()) {
    case "active":
    case "verified":
    case "approved":
      return <Badge className="bg-emerald-500/15 text-emerald-300 text-xs">{ status}</Badge>;
    case "pending":
    case "submitted":
      return <Badge className="bg-amber-500/15 text-amber-300 text-xs">{status}</Badge>;
    case "rejected":
    case "failed":
      return <Badge className="bg-red-500/15 text-red-300 text-xs">{status}</Badge>;
    default:
      return <Badge variant="secondary" className="text-xs">{status}</Badge>;
  }
}

export function WalletSection({ user }: WalletSectionProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <Wallet className="h-4 w-4 sm:h-5 sm:w-5" />
          Wallet, KYC & Financial
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Wallet Info */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2 flex items-center gap-2">
            <Wallet className="h-4 w-4" />
            Wallet Information
          </h4>
          <div className="rounded-md border p-3 bg-muted/30">
            {user.wallet ? (
              <div className="space-y-2 text-xs sm:text-sm">
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Status:</span>
                  {statusBadge(user.wallet.status)}
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Chain ID:</span>
                  <span className="font-mono">{user.wallet.chainId}</span>
                </div>
                <div>
                  <span className="text-muted-foreground block mb-1">Address:</span>
                  <code className="text-xs break-all bg-background/50 p-2 rounded block">
                    {user.wallet.address}
                  </code>
                </div>
                {user.wallet.providerWalletId && (
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Provider Wallet ID:</span>
                    <span className="text-xs font-mono">{user.wallet.providerWalletId}</span>
                  </div>
                )}
              </div>
            ) : (
              <p className="text-xs sm:text-sm text-muted-foreground">No wallet connected</p>
            )}
          </div>
        </div>

        {/* KYC Info */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2 flex items-center gap-2">
            <FileCheck className="h-4 w-4" />
            KYC Status
          </h4>
          <div className="rounded-md border p-3 bg-muted/30">
            {user.kyc ? (
              <div className="space-y-2 text-xs sm:text-sm">
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Status:</span>
                  {statusBadge(user.kyc.status)}
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Tier:</span>
                  <Badge variant="outline" className="text-xs">
                    {user.kyc.tier}
                  </Badge>
                </div>
                {user.kyc.submittedAt && (
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Submitted:</span>
                    <span className="text-xs">{fmtDate(user.kyc.submittedAt)}</span>
                  </div>
                )}
                {user.kyc.reviewedAt && (
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Reviewed:</span>
                    <span className="text-xs">{fmtDate(user.kyc.reviewedAt)}</span>
                  </div>
                )}
              </div>
            ) : (
              <p className="text-xs sm:text-sm text-muted-foreground">
                KYC not submitted
              </p>
            )}
          </div>
        </div>

        {/* Tip Accounts */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2 flex items-center gap-2">
            <CreditCard className="h-4 w-4" />
            Ledger Accounts
          </h4>
          {user.tips.accounts.length === 0 ? (
            <div className="rounded-md border p-3 bg-muted/30">
              <p className="text-xs sm:text-sm text-muted-foreground">No tip accounts</p>
            </div>
          ) : (
            <div className="grid gap-2 sm:grid-cols-2">
              {user.tips.accounts.map((account) => (
                <div key={account.id} className="rounded-md border p-3 bg-muted/30">
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-medium text-xs sm:text-sm">
                      {account.currency.symbol}
                    </span>
                    <Badge variant="outline" className="text-xs">
                      {account.currencyCode}
                    </Badge>
                  </div>
                  <p className="text-lg sm:text-xl font-bold">
                    {formatAtomicAmount(account.balanceAtomic, account.currency.decimals)}
                  </p>
                  <p className="text-xs text-muted-foreground mt-1">
                    {account.currency.kind} · {account.accountType}
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Tip Volume Summary */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2 flex items-center gap-2">
            <ArrowDownToLine className="h-4 w-4" />
            Tip Transaction Summary
          </h4>
          <div className="grid gap-2 sm:grid-cols-2">
            <div className="rounded-md border p-3 bg-muted/30">
              <p className="text-xs text-muted-foreground mb-1">Sent Transactions</p>
              <p className="text-xl sm:text-2xl font-bold">{user.counts.tipSent}</p>
            </div>
            <div className="rounded-md border p-3 bg-muted/30">
              <p className="text-xs text-muted-foreground mb-1">Received Transactions</p>
              <p className="text-xl sm:text-2xl font-bold">{user.counts.tipReceived}</p>
            </div>
            <div className="rounded-md border p-3 bg-muted/30 sm:col-span-2">
              <p className="text-xs text-muted-foreground mb-1">Currency Conversions</p>
              <p className="text-xl sm:text-2xl font-bold">{user.counts.tipConversions}</p>
            </div>
          </div>
        </div>

        {/* Recent Transactions (Placeholder) */}
        <div className="border-t pt-4">
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Recent Transactions</h4>
          <div className="text-center py-4 text-xs sm:text-sm text-muted-foreground">
            Transaction history will be available here
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
