import { getAdminEnvironmentLabel, type AdminEnvironment } from '@/lib/environment';
import { cn } from '@/lib/utils';

export function EnvironmentBadge({
  environment,
  className,
}: {
  environment: AdminEnvironment;
  className?: string;
}) {
  return (
    <span
      title={`Connected to the ${getAdminEnvironmentLabel(environment).toLowerCase()} environment`}
      className={cn(
        'inline-flex shrink-0 items-center rounded-full border px-2 py-0.5 text-[10px] font-semibold uppercase tracking-[0.08em]',
        environment === 'production'
          ? 'border-teal-400/30 bg-teal-500/12 text-teal-200'
          : 'border-amber-400/30 bg-amber-500/12 text-amber-200',
        className,
      )}>
      {getAdminEnvironmentLabel(environment)}
    </span>
  );
}
