import { ReactNode } from "react";
import { Lock } from "lucide-react";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "@/components/ui/tooltip";

type PermissionGateProps = {
  children: ReactNode;
  hasPermission: boolean;
  requiredRole?: string;
  reason?: string;
  showLock?: boolean;
};

/**
 * PermissionGate wrapper component
 *
 * Shows disabled UI elements with contextual feedback when permissions are lacking.
 * Helps users understand system capabilities and request access.
 */
export function PermissionGate({
  children,
  hasPermission,
  requiredRole,
  reason,
  showLock = true,
}: PermissionGateProps) {
  if (hasPermission) {
    return <>{children}</>;
  }

  const message =
    reason ?? (requiredRole ? `${requiredRole} access required` : "Insufficient permissions");

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <div className="relative">
            <div className="pointer-events-none opacity-50">{children}</div>
            {showLock && (
              <Lock className="absolute right-2 top-2 h-4 w-4 text-muted-foreground" />
            )}
          </div>
        </TooltipTrigger>
        <TooltipContent>
          <p className="text-xs">{message}</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
