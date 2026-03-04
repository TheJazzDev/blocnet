"use client";

import { Loader2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { AdminTipSettings } from "@/lib/api-client";

type ActiveTipCurrencyCardProps = {
  loading: boolean;
  canMutate: boolean;
  settings: AdminTipSettings | null;
  activeCurrencyCode: string;
  setActiveCurrencyCode: (value: string) => void;
  activating: boolean;
  onActivate: () => Promise<void>;
};

export function ActiveTipCurrencyCard({
  loading,
  canMutate,
  settings,
  activeCurrencyCode,
  setActiveCurrencyCode,
  activating,
  onActivate,
}: ActiveTipCurrencyCardProps) {
  const currencies = settings?.currencies ?? [];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Active Tipping Currency</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3 md:max-w-xl">
        {loading ? (
          <LoadingSpinner className="py-8" />
        ) : currencies.length === 0 ? (
          <p className="text-sm text-muted-foreground">No tip currencies configured.</p>
        ) : (
          <>
            <div className="flex flex-wrap items-center gap-2">
              {currencies.map((row) => (
                <Badge key={row.code} variant={row.isActiveTippingCurrency ? "default" : "secondary"}>
                  {row.code} {row.isActiveTippingCurrency ? "(Active)" : ""}
                </Badge>
              ))}
            </div>
            <div className="flex flex-col gap-3 md:flex-row">
              <Select value={activeCurrencyCode} onValueChange={setActiveCurrencyCode}>
                <SelectTrigger className="w-full md:w-[220px]">
                  <SelectValue placeholder="Select currency" />
                </SelectTrigger>
                <SelectContent>
                  {currencies.map((row) => (
                    <SelectItem key={row.code} value={row.code}>
                      {row.code} ({row.symbol})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button
                onClick={() => void onActivate()}
                disabled={
                  !canMutate ||
                  !activeCurrencyCode ||
                  activeCurrencyCode === settings?.activeCurrencyCode ||
                  activating
                }
              >
                {activating ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
                Set Active
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
