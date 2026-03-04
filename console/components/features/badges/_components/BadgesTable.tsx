"use client";

import { Fragment } from "react";
import { Award, Edit2, UserPlus } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  formatBadgeDate,
  getRarityColor,
  toCategoryLabel,
  toLabel,
  type BadgeModel,
} from "./badge-models";

type BadgeGroup = {
  category: string;
  badges: BadgeModel[];
};

type BadgesTableProps = {
  loading: boolean;
  badgesLength: number;
  groupedBadges: BadgeGroup[];
  canMutate: boolean;
  onEdit: (badge: BadgeModel) => void;
  onGrant: (badge: BadgeModel) => void;
};

export function BadgesTable({
  loading,
  badgesLength,
  groupedBadges,
  canMutate,
  onEdit,
  onGrant,
}: BadgesTableProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>All Badges ({badgesLength})</CardTitle>
      </CardHeader>
      <CardContent>
        {loading ? (
          <LoadingSpinner className="py-10" />
        ) : badgesLength === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">No badges found.</p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Rarity</TableHead>
                <TableHead>Points Req.</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Created</TableHead>
                <TableHead className="w-[100px]" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {groupedBadges.map((group) => (
                <Fragment key={group.category}>
                  <TableRow className="bg-muted/20">
                    <TableCell colSpan={7} className="py-2">
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground">
                          {toCategoryLabel(group.category)}
                        </span>
                        <Badge variant="outline" className="text-[11px]">
                          {group.badges.length}
                        </Badge>
                      </div>
                    </TableCell>
                  </TableRow>
                  {group.badges.map((badge) => (
                    <TableRow key={badge.id}>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Award className={`h-4 w-4 ${getRarityColor(badge.rarity)}`} />
                          <span className="font-medium">{badge.name}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{toCategoryLabel(badge.category)}</Badge>
                      </TableCell>
                      <TableCell>
                        <span className={`text-sm font-medium ${getRarityColor(badge.rarity)}`}>
                          {toLabel(badge.rarity)}
                        </span>
                      </TableCell>
                      <TableCell className="text-sm">{badge.pointsRequirement}</TableCell>
                      <TableCell>
                        <Badge variant={badge.isActive ? "default" : "secondary"}>
                          {badge.isActive ? "Active" : "Inactive"}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-right text-sm text-muted-foreground">
                        {formatBadgeDate(badge.createdAt)}
                      </TableCell>
                      <TableCell>
                        <div className="flex gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8"
                            disabled={!canMutate}
                            onClick={() => onEdit(badge)}
                          >
                            <Edit2 className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-8 w-8"
                            disabled={!canMutate}
                            onClick={() => onGrant(badge)}
                          >
                            <UserPlus className="h-4 w-4" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </Fragment>
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}
