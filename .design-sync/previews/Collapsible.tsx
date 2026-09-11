import * as React from "react";
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "blocnet-admin";
import { ChevronDown } from "lucide-react";

const Group = ({
  label,
  items,
  open,
}: {
  label: string;
  items: string[];
  open?: boolean;
}) => (
  <Collapsible defaultOpen={open} className="w-60">
    <CollapsibleTrigger className="group flex w-full items-center justify-between rounded-md px-2 py-1.5 text-xs font-semibold uppercase tracking-wide text-muted-foreground hover:text-foreground">
      {label}
      <ChevronDown className="size-4 transition-transform group-data-[state=closed]:-rotate-90" />
    </CollapsibleTrigger>
    <CollapsibleContent className="mt-1 space-y-0.5">
      {items.map((i) => (
        <span
          key={i}
          className="block rounded-md px-2 py-1.5 text-sm text-muted-foreground"
        >
          {i}
        </span>
      ))}
    </CollapsibleContent>
  </Collapsible>
);

export const SidebarGroups = () => (
  <div className="w-60 space-y-2 rounded-lg border border-border bg-sidebar p-2">
    <Group label="Economy" items={["Wallet users", "Withdrawals", "KYC review"]} open />
    <Group label="Gamification" items={["Mining", "Levels", "Badges"]} />
  </div>
);

export const Expanded = () => (
  <Group label="Content" items={["Projects", "Updates", "Comments"]} open />
);

export const Collapsed = () => <Group label="Access" items={["Members", "Roles"]} />;
