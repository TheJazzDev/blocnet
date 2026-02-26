"use client";

import { Folder, Star, Eye } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

type ProjectsSectionProps = {
  userId: string;
};

/**
 * ProjectsSection - Displays user's project involvement
 * TODO: Fetch owned, hunting, and followed projects
 */
export function ProjectsSection({ userId }: ProjectsSectionProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <Folder className="h-4 w-4 sm:h-5 sm:w-5" />
          Projects & Involvement
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Project Stats */}
        <div className="grid gap-3 sm:grid-cols-3">
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Folder className="h-4 w-4 text-sky-400" />
              <p className="text-xs text-muted-foreground">Projects Owned</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Star className="h-4 w-4 text-amber-400" />
              <p className="text-xs text-muted-foreground">Projects Hunting</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
          <div className="rounded-md border p-3 bg-muted/30">
            <div className="flex items-center gap-2 mb-1">
              <Eye className="h-4 w-4 text-emerald-400" />
              <p className="text-xs text-muted-foreground">Projects Following</p>
            </div>
            <p className="text-xl sm:text-2xl font-bold">—</p>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Project Lists */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Project Details</h4>
          <div className="text-center py-6 text-xs sm:text-sm text-muted-foreground">
            Project involvement details will be available here
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
