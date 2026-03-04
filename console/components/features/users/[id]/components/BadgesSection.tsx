"use client";

import { useState } from "react";
import { Loader2, Award } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { AdminUserDetail } from "@/lib/api-client";
import { PermissionGate } from "./PermissionGate";

type AdminBadgeModel = {
  id: string;
  slug: string;
  name: string;
  isActive: boolean;
};

type BadgesSectionProps = {
  user: AdminUserDetail;
  allBadges: AdminBadgeModel[];
  canManage: boolean;
  actionLoading: string | null;
  onGrantBadge: (badgeId: string, badgeName: string) => Promise<void>;
  onRevokeBadge: (badgeSlug: string, badgeName: string) => Promise<void>;
};

function fmtDate(value: string | null) {
  if (!value) return "—";
  try {
    return new Date(value).toLocaleString();
  } catch {
    return "—";
  }
}

function rarityColor(rarity: string) {
  switch (rarity.toLowerCase()) {
    case "legendary":
      return "border-amber-500/30 bg-amber-500/10 text-amber-300";
    case "epic":
      return "border-purple-500/30 bg-purple-500/10 text-purple-300";
    case "rare":
      return "border-blue-500/30 bg-blue-500/10 text-blue-300";
    case "uncommon":
      return "border-green-500/30 bg-green-500/10 text-green-300";
    default:
      return "border-gray-500/30 bg-gray-500/10 text-gray-300";
  }
}

function categoryColor(category: string) {
  switch (category.toLowerCase()) {
    case "governance":
      return "border-primary/30 bg-primary/10 text-primary";
    case "engagement":
      return "border-teal-500/30 bg-teal-500/10 text-teal-300";
    case "contribution":
      return "border-emerald-500/30 bg-emerald-500/10 text-emerald-300";
    case "achievement":
      return "border-sky-500/30 bg-sky-500/10 text-sky-300";
    default:
      return "border-gray-500/30 bg-gray-500/10 text-gray-300";
  }
}

export function BadgesSection({
  user,
  allBadges,
  canManage,
  actionLoading,
  onGrantBadge,
  onRevokeBadge,
}: BadgesSectionProps) {
  const [selectedBadgeId, setSelectedBadgeId] = useState("");

  async function handleGrantBadge() {
    if (!selectedBadgeId) return;
    const badge = allBadges.find((b) => b.id === selectedBadgeId);
    if (!badge) return;
    await onGrantBadge(badge.id, badge.name);
    setSelectedBadgeId("");
  }

  const earnedBadgeIds = new Set(user.badges.map((b) => b.badge.id));
  const availableBadges = allBadges.filter((b) => !earnedBadgeIds.has(b.id));

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base flex items-center gap-2">
          <Award className="h-4 w-4 sm:h-5 sm:w-5" />
          Badges & Achievements
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Grant Badge Section */}
        <PermissionGate
          hasPermission={canManage}
          requiredRole="Admin"
          reason="Admin access required to manage badges"
          showLock={false}
        >
          <div className="rounded-md border p-3 sm:p-4 bg-muted/30">
            <div className="grid gap-3 sm:grid-cols-[1fr_auto] sm:items-end">
              <div className="space-y-2">
                <Label htmlFor="grant-badge-select" className="text-xs sm:text-sm">
                  Grant Badge to User
                </Label>
                <Select
                  value={selectedBadgeId}
                  onValueChange={setSelectedBadgeId}
                  disabled={!canManage}
                >
                  <SelectTrigger id="grant-badge-select" className="text-xs sm:text-sm">
                    <SelectValue placeholder="Select a badge to grant" />
                  </SelectTrigger>
                  <SelectContent>
                    {availableBadges.length === 0 ? (
                      <div className="p-2 text-xs sm:text-sm text-muted-foreground">
                        All badges already earned
                      </div>
                    ) : (
                      availableBadges.map((badge) => (
                        <SelectItem
                          key={badge.id}
                          value={badge.id}
                          className="text-xs sm:text-sm"
                        >
                          {badge.name}
                        </SelectItem>
                      ))
                    )}
                  </SelectContent>
                </Select>
              </div>
              <Button
                onClick={handleGrantBadge}
                disabled={!canManage || !selectedBadgeId || Boolean(actionLoading)}
                size="sm"
                className="text-xs sm:text-sm"
              >
                {actionLoading?.startsWith("grant-badge-") ? (
                  <Loader2 className="mr-2 h-3 w-3 sm:h-4 sm:w-4 animate-spin" />
                ) : null}
                Grant Badge
              </Button>
            </div>
          </div>
        </PermissionGate>

        {/* Primary Badge */}
        <div>
          <h4 className="text-xs sm:text-sm font-semibold mb-2">Primary Badge</h4>
          {user.primaryBadge ? (
            <div className="flex items-center gap-2 p-3 rounded-md border">
              <Award className="h-5 w-5 sm:h-6 sm:w-6 text-amber-400" />
              <div className="flex-1">
                <p className="font-medium text-xs sm:text-sm">{user.primaryBadge.name}</p>
                <div className="flex gap-2 mt-1">
                  <Badge className={`${rarityColor(user.primaryBadge.rarity)} text-xs`}>
                    {user.primaryBadge.rarity}
                  </Badge>
                  <Badge className={`${categoryColor(user.primaryBadge.category)} text-xs`}>
                    {user.primaryBadge.category}
                  </Badge>
                </div>
              </div>
            </div>
          ) : (
            <p className="text-xs sm:text-sm text-muted-foreground">No primary badge set</p>
          )}
        </div>

        <div className="border-t pt-4" />

        {/* All Earned Badges */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <h4 className="text-xs sm:text-sm font-semibold">
              All Badges ({user.badges.length})
            </h4>
          </div>

          {user.badges.length === 0 ? (
            <div className="text-center py-6 sm:py-8">
              <Award className="h-10 w-10 sm:h-12 sm:w-12 mx-auto text-muted-foreground/50 mb-2" />
              <p className="text-xs sm:text-sm text-muted-foreground">
                No badges earned yet
              </p>
            </div>
          ) : (
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {user.badges.map((entry) => (
                <div
                  key={`${entry.badge.id}-${entry.earnedAt}`}
                  className="rounded-md border p-3 hover:bg-muted/30 transition-colors"
                >
                  <div className="flex items-start gap-2 mb-2">
                    <Award className="h-4 w-4 sm:h-5 sm:w-5 text-amber-400 shrink-0 mt-0.5" />
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-xs sm:text-sm truncate">
                        {entry.badge.name}
                      </p>
                      <p className="text-xs text-muted-foreground mt-0.5">
                        {entry.badge.slug}
                      </p>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-1.5 mb-2">
                    <Badge className={`${rarityColor(entry.badge.rarity)} text-xs`}>
                      {entry.badge.rarity}
                    </Badge>
                    <Badge className={`${categoryColor(entry.badge.category)} text-xs`}>
                      {entry.badge.category}
                    </Badge>
                  </div>

                  <p className="text-xs text-muted-foreground mb-2">
                    Earned {fmtDate(entry.earnedAt)}
                  </p>

                  <PermissionGate
                    hasPermission={canManage}
                    requiredRole="Admin"
                    reason="Admin access required to revoke badges"
                    showLock={false}
                  >
                    <Button
                      variant="outline"
                      size="sm"
                      className="w-full text-xs"
                      disabled={!canManage || Boolean(actionLoading)}
                      onClick={() => onRevokeBadge(entry.badge.slug, entry.badge.name)}
                    >
                      {actionLoading === `revoke-badge-${entry.badge.slug}` ? (
                        <Loader2 className="mr-2 h-3 w-3 animate-spin" />
                      ) : null}
                      Revoke
                    </Button>
                  </PermissionGate>
                </div>
              ))}
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
