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
import { clientApi, type AdminTipTransaction, type TipDirection } from "@/lib/api-client";

type DirectionFilter = "all" | Exclude<TipDirection, "all">;

function displayUser(row: {
  username: string | null;
  displayName: string | null;
  id: string;
}) {
  if (row.displayName?.trim()) {
    return row.displayName;
  }
  if (row.username?.trim()) {
    return `@${row.username.replace(/^@/, "")}`;
  }
  return row.id;
}

function shortId(value: string) {
  if (value.length <= 14) return value;
  return `${value.slice(0, 8)}...${value.slice(-6)}`;
}

function money(value: string, symbol: string) {
  return `${value} ${symbol}`;
}

export default function TipsTransactionsPage() {
  const [rows, setRows] = useState<AdminTipTransaction[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [currencyCode, setCurrencyCode] = useState("all");
  const [direction, setDirection] = useState<DirectionFilter>("all");
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
      .listTipTransactions({
        q,
        currencyCode: currencyCode === "all" ? undefined : currencyCode,
        direction: direction === "all" ? undefined : direction,
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
        setError(e instanceof Error ? e.message : "Failed to load tip transactions");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, currencyCode, direction, limit, offset]);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Tip Transactions"
        description="Review sender, hunter recipient, gross tip amount, and fee vault capture."
      />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">History</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(event) => setSearchInput(event.target.value)}
                className="pl-9"
                placeholder="Search by sender/recipient, note, or id"
              />
            </div>
            <Select
              value={currencyCode}
              onValueChange={(next) => {
                setCurrencyCode(next);
                setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[160px]">
                <SelectValue placeholder="Currency" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All currencies</SelectItem>
                <SelectItem value="BNP">BNP</SelectItem>
                <SelectItem value="BNT">BNT</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={direction}
              onValueChange={(next) => {
                setDirection(next as DirectionFilter);
                setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[150px]">
                <SelectValue placeholder="Direction" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All directions</SelectItem>
                <SelectItem value="sent">Sent</SelectItem>
                <SelectItem value="received">Received</SelectItem>
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
            <p className="py-8 text-center text-sm text-muted-foreground">No tip transactions found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Created</TableHead>
                  <TableHead>Sender</TableHead>
                  <TableHead>Hunter</TableHead>
                  <TableHead className="text-right">Amount</TableHead>
                  <TableHead className="text-right">Fee</TableHead>
                  <TableHead className="text-right">Total Debit</TableHead>
                  <TableHead>Currency</TableHead>
                  <TableHead>Context</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((row) => (
                  <TableRow key={row.id}>
                    <TableCell>
                      <div className="space-y-0.5">
                        <p className="text-xs">{new Date(row.createdAt).toLocaleString()}</p>
                        <p className="font-mono text-[11px] text-muted-foreground">{shortId(row.id)}</p>
                      </div>
                    </TableCell>
                    <TableCell>
                      <p className="text-sm font-medium">{displayUser(row.sender)}</p>
                      <p className="font-mono text-[11px] text-muted-foreground">{shortId(row.sender.id)}</p>
                    </TableCell>
                    <TableCell>
                      <p className="text-sm font-medium">{displayUser(row.recipient)}</p>
                      <p className="font-mono text-[11px] text-muted-foreground">{shortId(row.recipient.id)}</p>
                    </TableCell>
                    <TableCell className="text-right font-medium">
                      {money(row.amount, row.currency.symbol)}
                    </TableCell>
                    <TableCell className="text-right">{money(row.fee, row.currency.symbol)}</TableCell>
                    <TableCell className="text-right">{money(row.totalDebit, row.currency.symbol)}</TableCell>
                    <TableCell>
                      <Badge variant="outline">{row.currency.code}</Badge>
                    </TableCell>
                    <TableCell>
                      <p className="max-w-[240px] truncate text-sm text-muted-foreground">
                        {row.note?.trim() || row.contextType?.trim() || "—"}
                      </p>
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
