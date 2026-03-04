"use client";

import { Users, UserPlus } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";

type SocialSectionProps = {
  user: AdminUserDetail;
};

/**
 * SocialSection - Displays followers, following, and social network
 * TODO: Fetch recent followers and following lists
 */
export function SocialSection({ user }: SocialSectionProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <Users className="h-4 w-4 sm:h-5 sm:w-5" />
          Social Network
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Social Stats */}
        <div className="grid gap-3 sm:grid-cols-2">
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Users className="h-4 w-4 text-sky-400" />
              <p className="text-xs text-muted-foreground">Followers</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">{user.counts.followers}</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <UserPlus className="h-4 w-4 text-emerald-400" />
              <p className="text-xs text-muted-foreground">Following</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">{user.counts.following}</p>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Recent Followers/Following */}
        <div className="space-y-3">
          <div>
            <h4 className="text-xs sm:text-sm font-semibold mb-2">Recent Followers</h4>
            <div className="text-center py-4 text-xs sm:text-sm text-muted-foreground">
              Recent followers will be shown here
            </div>
          </div>
          <div>
            <h4 className="text-xs sm:text-sm font-semibold mb-2">Recent Following</h4>
            <div className="text-center py-4 text-xs sm:text-sm text-muted-foreground">
              Recent following will be shown here
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
