"use client";

import { useState } from "react";
import { CheckCircle2, Loader2, XCircle } from "lucide-react";
import { Button } from "@/components/ui/button";

type ReviewButtonsProps = {
  onApprove: () => Promise<void>;
  onReject: () => Promise<void>;
};

export function ReviewButtons({ onApprove, onReject }: ReviewButtonsProps) {
  const [loading, setLoading] = useState<"approve" | "reject" | null>(null);

  async function handle(action: "approve" | "reject") {
    setLoading(action);
    try {
      if (action === "approve") {
        await onApprove();
      } else {
        await onReject();
      }
    } finally {
      setLoading(null);
    }
  }

  return (
    <div className="flex shrink-0 gap-2">
      <Button
        size="sm"
        className="bg-emerald-600 hover:bg-emerald-700"
        disabled={loading !== null}
        onClick={() => handle("approve")}
      >
        {loading === "approve" ? (
          <Loader2 className="h-3.5 w-3.5 animate-spin" />
        ) : (
          <CheckCircle2 className="h-3.5 w-3.5" />
        )}
        Approve
      </Button>
      <Button
        size="sm"
        variant="destructive"
        disabled={loading !== null}
        onClick={() => handle("reject")}
      >
        {loading === "reject" ? (
          <Loader2 className="h-3.5 w-3.5 animate-spin" />
        ) : (
          <XCircle className="h-3.5 w-3.5" />
        )}
        Reject
      </Button>
    </div>
  );
}
