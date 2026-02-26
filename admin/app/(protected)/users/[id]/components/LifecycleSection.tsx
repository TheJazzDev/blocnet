"use client";

import { Clock, Power, Smartphone, Bell } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";

type LifecycleSectionProps = {
  user: AdminUserDetail;
};

function fmtDate(value: string | null) {
  if (!value) return "—";
  try {
    return new Date(value).toLocaleString();
  } catch {
    return "—";
  }
}

/**
 * LifecycleSection - Displays account lifecycle info
 * TODO: Add deactivation history, device tokens, notification settings
 */
export function LifecycleSection({ user }: LifecycleSectionProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <Clock className="h-4 w-4 sm:h-5 sm:w-5" />
          Account Lifecycle
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Account Status */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Account Status</h4>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="space-y-2 text-xs sm:text-sm">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Current Status:</span>
                {user.isDeactivated ? (
                  <Badge className="bg-red-500/15 text-red-300">Deactivated</Badge>
                ) : (
                  <Badge className="bg-emerald-500/15 text-emerald-300">Active</Badge>
                )}
              </div>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Joined:</span>
                <span>{fmtDate(user.createdAt)}</span>
              </div>
              {user.isDeactivated && user.deactivatedAt && (
                <div className="flex items-center justify-between">
                  <span className="text-muted-foreground">Deactivated At:</span>
                  <span>{fmtDate(user.deactivatedAt)}</span>
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Device & Notifications */}
        <div className="grid gap-3 sm:grid-cols-2">
          <div>
            <h4 className="text-xs sm:text-sm font-semibold mb-2 flex items-center gap-2">
              <Smartphone className="h-4 w-4" />
              Device Tokens
            </h4>
            <div className="rounded-md border p-3 bg-muted/30">
              <p className="text-xl sm:text-2xl font-bold">—</p>
              <p className="text-xs text-muted-foreground mt-1">Registered devices</p>
            </div>
          </div>
          <div>
            <h4 className="text-xs sm:text-sm font-semibold mb-2 flex items-center gap-2">
              <Bell className="h-4 w-4" />
              Notifications
            </h4>
            <div className="rounded-md border p-3 bg-muted/30">
              <p className="text-xs sm:text-sm text-muted-foreground">
                Notification settings will be shown here
              </p>
            </div>
          </div>
        </div>

        {/* Deactivation History */}
        {user.isDeactivated && (
          <>
            <div className="border-t pt-4" />
            <div>
              <h4 className="text-xs sm:text-sm font-semibold mb-2 flex items-center gap-2">
                <Power className="h-4 w-4" />
                Deactivation History
              </h4>
              <div className="text-center py-4 text-xs sm:text-sm text-muted-foreground">
                Deactivation history and reasons will be shown here
              </div>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}
