import { cn } from "@/lib/utils";

interface PageHeaderProps {
  title: string;
  description?: string;
  children?: React.ReactNode;
  className?: string;
}

export function PageHeader({ title, description, children, className }: PageHeaderProps) {
  return (
    <div
      className={cn(
        "flex flex-col gap-1 rounded-xl border border-primary/15 bg-gradient-to-r from-primary/10 via-transparent to-teal-400/10 px-4 py-3 sm:flex-row sm:items-center sm:justify-between",
        className,
      )}
    >
      <div className="relative pl-3">
        <span className="absolute left-0 top-1 h-8 w-1 rounded-full bg-gradient-to-b from-primary to-teal-300" />
        <h1 className="text-xl font-bold tracking-tight md:text-2xl">{title}</h1>
        {description && (
          <p className="mt-1 text-sm text-muted-foreground">{description}</p>
        )}
      </div>
      {children && <div className="mt-3 flex items-center gap-2 sm:mt-0">{children}</div>}
    </div>
  );
}
