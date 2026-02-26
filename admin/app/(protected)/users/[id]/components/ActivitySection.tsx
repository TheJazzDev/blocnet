"use client";

import { Activity, MessageSquare, FileText, Heart } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { AdminUserDetail } from "@/lib/api-client";

type ActivitySectionProps = {
  user: AdminUserDetail;
};

/**
 * ActivitySection - Displays user activity and content
 * TODO: Fetch recent updates, comments, community posts
 */
export function ActivitySection({ user }: ActivitySectionProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <Activity className="h-4 w-4 sm:h-5 sm:w-5" />
          Activity & Content
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Activity Stats */}
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <FileText className="h-4 w-4 text-sky-400" />
              <p className="text-xs text-muted-foreground">Updates Posted</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">{user.counts.updates}</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <MessageSquare className="h-4 w-4 text-emerald-400" />
              <p className="text-xs text-muted-foreground">Comments</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Activity className="h-4 w-4 text-purple-400" />
              <p className="text-xs text-muted-foreground">Community Posts</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Heart className="h-4 w-4 text-pink-400" />
              <p className="text-xs text-muted-foreground">Reactions Given</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Recent Activity */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Recent Activity</h4>
          <div className="text-center py-6 text-xs sm:text-sm text-muted-foreground">
            Recent activity feed will be available here
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
