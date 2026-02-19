"use client";

import { useEffect, useState } from "react";
import { ChevronLeft, ChevronRight, Search } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { Button } from "@/components/ui/button";
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
import { clientApi, type AdminWalletUser, type WalletKycStatus, type WalletStatus } from "@/lib/api-client";

type WalletStatusFilter = "all" | WalletStatus;
type KycStatusFilter = "all" | WalletKycStatus;

function walletStatusBadge(status: WalletStatus) {
  switch (status) {
    case "ready":
      return <Badge className="bg-emerald-500/15 text-emerald-300">Ready</Badge>;
    case "provisioning":
      return <Badge className="bg-blue-500/15 text-blue-300">Provisioning</Badge>;
    case "disabled":
      return <Badge variant="secondary">Disabled</Badge>;
    case "error":
      return <Badge className="bg-red-500/15 text-red-300">Error</Badge>;
  }
}

function kycStatusBadge(status: WalletKycStatus | null) {
  if (!status) return <Badge variant="secondary">N/A</Badge>;
  switch (status) {
    case "approved":
      return <Badge className="bg-emerald-500/15 text-emerald-300">Approved</Badge>;
    case "pending":
      return <Badge className="bg-amber-500/15 text-amber-300">Pending</Badge>;
    case "rejected":
      return <Badge className="bg-red-500/15 text-red-300">Rejected</Badge>;
    case "not_submitted":
      return <Badge variant="secondary">Not Submitted</Badge>;
  }
}

function shortAddress(address: string | null | undefined) {
  if (!address) return "—";
  if (address.length < 14) return address;
  return `${address.slice(0, 8)}...${address.slice(-6)}`;
}

export default function WalletUsersPage() {
  const [rows, setRows] = useState<AdminWalletUser[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [walletStatus, setWalletStatus] = useState<WalletStatusFilter>("all");
  const [kycStatus, setKycStatus] = useState<KycStatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  useEffect(() => {
    const timer = setTimeout(() => {
      setQ(searchInput.trim());
      setOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput]);

  function load() {
    setLoading(true);
    setError(null);
    clientApi
      .listWalletUsers({
        q,
        walletStatus: walletStatus === "all" ? undefined : walletStatus,
        kycStatus: kycStatus === "all" ? undefined : kycStatus,
        limit,
        offset,
      })
      .then((result) => {
        setRows(result.data);
        setTotal(result.total);
      })
      .catch((e: unknown) => {
        setRows([]);
        setTotal(0);
        setError(e instanceof Error ? e.message : "Failed to load wallet users");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, walletStatus, kycStatus, limit, offset]);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Wallet Users"
        description="Search members and inspect wallet provisioning, balances, and KYC state."
      />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Directory</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search by email, name, username, or user id"
              />
            </div>
            <Select
              value={walletStatus}
              onValueChange={(next) => {
                setWalletStatus(next as WalletStatusFilter);
                setOffset(0);
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
              value={kycStatus}
              onValueChange={(next) => {
                setKycStatus(next as KycStatusFilter);
                setOffset(0);
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
              value={String(limit)}
              onValueChange={(next) => {
                setLimit(Number(next));
                setOffset(0);
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
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : error ? (
            <p className="py-8 text-center text-sm text-destructive">{error}</p>
          ) : rows.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No users found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Wallet</TableHead>
                  <TableHead>KYC</TableHead>
                  <TableHead className="text-right">Available BNT</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((row) => (
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
                        <p className="text-xs text-muted-foreground">{shortAddress(row.wallet?.address)}</p>
                      </div>
                    </TableCell>
                    <TableCell>{kycStatusBadge(row.kyc?.status ?? null)}</TableCell>
                    <TableCell className="text-right font-medium">
                      {row.balances?.available ?? "0"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}

          <div className="mt-4 flex items-center justify-between">
            <p className="text-xs text-muted-foreground">
              Showing {rows.length === 0 ? 0 : offset + 1}-{Math.min(offset + rows.length, total)} of {total}
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={offset === 0 || loading}
                onClick={() => setOffset((prev) => Math.max(prev - limit, 0))}
              >
                <ChevronLeft className="h-4 w-4" />
                Prev
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={offset + limit >= total || loading}
                onClick={() => setOffset((prev) => prev + limit)}
              >
                Next
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
