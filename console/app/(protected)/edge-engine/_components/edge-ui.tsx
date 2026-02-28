import type { LucideIcon } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export function actionBadge(action: string) {
  if (action === "act") return <Badge className="bg-emerald-500/15 text-emerald-300">Act</Badge>;
  if (action === "watch") return <Badge className="bg-amber-500/15 text-amber-300">Watch</Badge>;
  return <Badge variant="secondary">Ignore</Badge>;
}

export function urgencyBadge(urgency: string) {
  if (urgency === "high") {
    return <Badge className="bg-red-500/15 text-red-300">High</Badge>;
  }
  if (urgency === "medium") {
    return <Badge className="bg-amber-500/15 text-amber-300">Medium</Badge>;
  }
  return <Badge className="bg-slate-500/15 text-slate-300">Low</Badge>;
}

export function MetricCard({
  title,
  value,
  hint,
  icon: Icon,
}: {
  title: string;
  value: string;
  hint: string;
  icon: LucideIcon;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <p className="text-2xl font-bold">{value}</p>
        <p className="mt-1 text-xs text-muted-foreground">{hint}</p>
      </CardContent>
    </Card>
  );
}

export function MetricCell({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border p-2">
      <p className="text-[10px] text-muted-foreground">{label}</p>
      <p className="text-xs font-semibold">{value}</p>
    </div>
  );
}
