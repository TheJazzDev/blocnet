"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Brain, GitMerge, Settings2, Sparkles } from "lucide-react";
import { cn } from "@/lib/utils";

const sections = [
  { href: "/edge-engine", label: "Command Center", icon: GitMerge },
  { href: "/edge-engine/decision-engine", label: "Decision Engine", icon: Sparkles },
  { href: "/edge-engine/ml-analysis", label: "ML Analysis", icon: Brain },
  { href: "/edge-engine/settings", label: "Settings", icon: Settings2 },
];

export function EdgeSectionNav() {
  const pathname = usePathname();

  return (
    <div className="flex flex-wrap gap-2">
      {sections.map((section) => {
        const active =
          pathname === section.href ||
          (section.href !== "/edge-engine" && pathname.startsWith(`${section.href}/`));
        return (
          <Link
            key={section.href}
            href={section.href}
            className={cn(
              "inline-flex items-center gap-2 rounded-md border px-3 py-1.5 text-xs font-medium transition-colors",
              active
                ? "border-primary/40 bg-primary/10 text-primary"
                : "border-border text-muted-foreground hover:text-foreground",
            )}
          >
            <section.icon className="h-3.5 w-3.5" />
            {section.label}
          </Link>
        );
      })}
    </div>
  );
}
