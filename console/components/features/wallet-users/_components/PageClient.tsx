"use client";

import { ChevronLeft, ChevronRight, Loader2, Search } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { useAdminSession } from "@/components/admin-shell";
import { canMutateWallet } from "@/lib/rbac";
import { useWalletUsersAdmin } from "../_hooks/use-wallet-users-admin";
import {
  kycStatusBadge,
  shortAddress,
  walletStatusBadge,
  type KycStatusFilter,
  type WalletStatusFilter,
} from "../_lib/wallet-users";

export default function WalletUsersPageClient() {
  const session = useAdminSession();
  const canMutate = canMutateWallet(session.effectiveRoles);
  const state = useWalletUsersAdmin();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Wallet Users"
        description="Search members and inspect wallet provisioning, balances, and KYC state."
      />

      {!canMutate ? (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Read-only access. Owner/Admin roles are required to change wallet status.
          </CardContent>
        </Card>
      ) : null}

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Directory</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={state.searchInput}
                onChange={(e) => state.setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search by email, name, username, or user id"
              />
            </div>
            <Select
              value={state.walletStatus}
              onValueChange={(next) => {
                state.setWalletStatus(next as WalletStatusFilter);
                state.setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[180px]">
                <SelectValue placeholder="Wallet status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All wallet status</SelectItem>
                <SelectItem value="ready">Ready</SelectItem>
                <SelectItem value="provisioning">Provisioning</SelectItem>
                <SelectItem value="error">Error</SelectItem>
                <SelectItem value="disabled">Disabled</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={state.kycStatus}
              onValueChange={(next) => {
                state.setKycStatus(next as KycStatusFilter);
                state.setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[180px]">
                <SelectValue placeholder="KYC status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All KYC status</SelectItem>
                <SelectItem value="approved">Approved</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="rejected">Rejected</SelectItem>
                <SelectItem value="not_submitted">Not submitted</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={String(state.limit)}
              onValueChange={(next) => {
                state.setLimit(Number(next));
                state.setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[120px]">
                <SelectValue placeholder="Page size" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="25">25</SelectItem>
                <SelectItem value="50">50</SelectItem>
                <SelectItem value="100">100</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {state.statusError ? (
            <p className="mb-4 text-sm text-destructive">{state.statusError}</p>
          ) : null}

          {state.loading ? (
            <LoadingSpinner className="py-10" />
          ) : state.error ? (
            <p className="py-8 text-center text-sm text-destructive">{state.error}</p>
          ) : state.rows.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No users found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Wallet</TableHead>
                  <TableHead>KYC</TableHead>
                  <TableHead className="text-right">Available BNT</TableHead>
                  <TableHead className="text-right">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {state.rows.map((row) => {
                  const disabled = row.wallet?.status === "disabled";
                  const saving = state.statusSavingUserId === row.id;
                  return (
                    <TableRow key={row.id}>
                      <TableCell>
                        <div className="space-y-0.5">
                          <p className="font-medium">{row.displayName ?? row.email}</p>
                          <p className="text-xs text-muted-foreground">{row.email}</p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="space-y-1">
                          {row.wallet ? walletStatusBadge(row.wallet.status) : <Badge variant="secondary">None</Badge>}
                          <p className="text-xs text-muted-foreground">
                            {shortAddress(row.wallet?.address)}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>{kycStatusBadge(row.kyc?.status ?? null)}</TableCell>
                      <TableCell className="text-right font-medium">
                        {row.balances?.available ?? "0"}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          size="sm"
                          variant={disabled ? "default" : "destructive"}
                          disabled={!canMutate || saving}
                          onClick={() =>
                            state.openStatusConfirm(row.id, row.email, !disabled)
                          }
                        >
                          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                          {disabled ? "Enable" : "Disable"}
                        </Button>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          )}

          <div className="mt-4 flex items-center justify-between">
            <p className="text-xs text-muted-foreground">
              Showing {state.rows.length === 0 ? 0 : state.offset + 1}-
              {Math.min(state.offset + state.rows.length, state.total)} of {state.total}
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={state.offset === 0 || state.loading}
                onClick={() => state.setOffset((prev) => Math.max(prev - state.limit, 0))}
              >
                <ChevronLeft className="h-4 w-4" />
                Prev
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={state.offset + state.limit >= state.total || state.loading}
                onClick={() => state.setOffset((prev) => prev + state.limit)}
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Dialog
        open={state.confirmOpen}
        onOpenChange={(nextOpen) => {
          state.setConfirmOpen(nextOpen);
          if (!nextOpen) state.setPendingStatusAction(null);
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Wallet Status Update</DialogTitle>
            <DialogDescription>
              {state.pendingStatusAction
                ? `Are you sure you want to ${state.pendingStatusAction.nextDisabled ? "disable" : "enable"} wallet access for ${state.pendingStatusAction.email}?`
                : "Confirm wallet status update."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => state.setConfirmOpen(false)}
              disabled={Boolean(state.statusSavingUserId)}
            >
              Cancel
            </Button>
            <Button
              variant={state.pendingStatusAction?.nextDisabled ? "destructive" : "default"}
              onClick={() => void state.confirmStatusChange()}
              disabled={!state.pendingStatusAction || Boolean(state.statusSavingUserId)}
            >
              {state.statusSavingUserId ? (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              ) : null}
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
