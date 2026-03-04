"use client";

import Link from "next/link";
import { ExternalLink } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { OpsEventProvider, OpsEventSource, OpsEventStatus } from "@/lib/api-client";
import { PROVIDER_OPTIONS, SOURCE_OPTIONS, STATUS_OPTIONS } from "../_lib/ops-events";

type OpsFiltersCardProps = {
  q: string;
  setQ: (value: string) => void;
  source: "all" | OpsEventSource;
  setSource: (value: "all" | OpsEventSource) => void;
  provider: "all" | OpsEventProvider;
  setProvider: (value: "all" | OpsEventProvider) => void;
  status: "all" | OpsEventStatus;
  setStatus: (value: "all" | OpsEventStatus) => void;
  from: string;
  setFrom: (value: string) => void;
  to: string;
  setTo: (value: string) => void;
  refreshing: boolean;
  providerLinks: Array<{ label: string; href: string }>;
  onApply: () => void;
  onReset: () => void;
};

export function OpsFiltersCard({
  q,
  setQ,
  source,
  setSource,
  provider,
  setProvider,
  status,
  setStatus,
  from,
  setFrom,
  to,
  setTo,
  refreshing,
  providerLinks,
  onApply,
  onReset,
}: OpsFiltersCardProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Filters</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="grid gap-2 md:grid-cols-2 xl:grid-cols-6">
          <Input
            placeholder="Search action, actor, resource"
            value={q}
            onChange={(event) => setQ(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                onApply();
              }
            }}
          />
          <Select value={source} onValueChange={setSource}>
            <SelectTrigger>
              <SelectValue placeholder="Source" />
            </SelectTrigger>
            <SelectContent>
              {SOURCE_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={provider} onValueChange={setProvider}>
            <SelectTrigger>
              <SelectValue placeholder="Provider" />
            </SelectTrigger>
            <SelectContent>
              {PROVIDER_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={status} onValueChange={setStatus}>
            <SelectTrigger>
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              {STATUS_OPTIONS.map((option) => (
                <SelectItem key={option.value} value={option.value}>
                  {option.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Input type="datetime-local" value={from} onChange={(event) => setFrom(event.target.value)} />
          <Input type="datetime-local" value={to} onChange={(event) => setTo(event.target.value)} />
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" onClick={onApply} disabled={refreshing}>
            Apply
          </Button>
          <Button variant="ghost" onClick={onReset}>
            Reset
          </Button>
          {providerLinks.map((link) => (
            <Button key={link.href} variant="ghost" asChild>
              <Link href={link.href} target="_blank" rel="noreferrer">
                {link.label}
                <ExternalLink className="h-4 w-4" />
              </Link>
            </Button>
          ))}
        </div>
      </CardContent>
    </Card>
  );
}
