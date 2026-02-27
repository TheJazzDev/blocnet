"use client";

import { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

type Status = "checking" | "ok" | "error";

export function DashboardHealthCard() {
  const [apiStatus, setApiStatus] = useState<Status>("checking");

  useEffect(() => {
    const apiBase =
      process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api";

    fetch(`${apiBase}/health`, { cache: "no-store" })
      .then((r) => setApiStatus(r.ok ? "ok" : "error"))
      .catch(() => setApiStatus("error"));
  }, []);

  function statusBadge(status: Status) {
    if (status === "checking") {
      return (
        <Badge
          variant="outline"
          className="border-muted bg-muted/40 text-muted-foreground"
        >
          Checking…
        </Badge>
      );
    }
    if (status === "ok") {
      return (
        <Badge
          variant="outline"
          className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500"
        >
          Operational
        </Badge>
      );
    }
    return (
      <Badge
        variant="outline"
        className="border-red-500/20 bg-red-500/10 text-red-400"
      >
        Unreachable
      </Badge>
    );
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Platform Health</CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-sm text-muted-foreground">API Status</span>
          {statusBadge(apiStatus)}
        </div>
        <div className="flex items-center justify-between">
          <span className="text-sm text-muted-foreground">Auth Provider</span>
          <Badge
            variant="outline"
            className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500"
          >
            Supabase
          </Badge>
        </div>
      </CardContent>
    </Card>
  );
}
