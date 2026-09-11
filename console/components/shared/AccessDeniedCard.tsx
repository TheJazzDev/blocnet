import { ShieldOff } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { PageHeader } from "@/components/page-header";

type AccessDeniedCardProps = {
  /** Page title so the header still renders; omit to render only the card. */
  title?: string;
  description?: string;
  /** Which roles unlock the page, e.g. "Owner or dev role is required". */
  requirement: string;
};

/**
 * The one access-denied treatment for console pages. Pages should render
 * this instead of redirecting, so the admin sees why the page is empty.
 */
export function AccessDeniedCard({ title, description, requirement }: AccessDeniedCardProps) {
  const card = (
    <Card>
      <CardContent className="flex items-start gap-3 py-6 text-xs text-muted-foreground sm:py-8 sm:text-sm">
        <ShieldOff className="mt-0.5 h-4 w-4 shrink-0 sm:h-5 sm:w-5" />
        <div className="space-y-1">
          <p className="font-medium text-foreground">Access denied</p>
          <p>{requirement}</p>
        </div>
      </CardContent>
    </Card>
  );

  if (!title) return card;

  return (
    <div className="space-y-4 sm:space-y-6">
      <PageHeader title={title} description={description} />
      {card}
    </div>
  );
}
