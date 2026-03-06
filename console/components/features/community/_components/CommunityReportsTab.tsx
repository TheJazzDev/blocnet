"use client";

import {
  ChevronLeft,
  ChevronRight,
  MoreHorizontal,
  Search,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type {
  CommunityModerationReport,
  CommunityReportStatus,
} from "@/lib/api-client";
import {
  formatDate,
  reportStatusBadge,
  reportTargetTypeBadge,
  type ReportStatusFilter,
  type ReportTargetTypeFilter,
} from "../_lib/community-admin";

type CommunityReportsTabProps = {
  reports: CommunityModerationReport[];
  total: number;
  loading: boolean;
  error: string | null;
  searchInput: string;
  onSearchInputChange: (value: string) => void;
  status: ReportStatusFilter;
  onStatusChange: (value: ReportStatusFilter) => void;
  targetType: ReportTargetTypeFilter;
  onTargetTypeChange: (value: ReportTargetTypeFilter) => void;
  offset: number;
  limit: number;
  onPreviousPage: () => void;
  onNextPage: () => void;
  onReview: (
    report: CommunityModerationReport,
    status: Exclude<CommunityReportStatus, "open">,
  ) => void;
  onOpenUserActions: (report: CommunityModerationReport) => void;
};

export function CommunityReportsTab({
  reports,
  total,
  loading,
  error,
  searchInput,
  onSearchInputChange,
  status,
  onStatusChange,
  targetType,
  onTargetTypeChange,
  offset,
  limit,
  onPreviousPage,
  onNextPage,
  onReview,
  onOpenUserActions,
}: CommunityReportsTabProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Community Reports</CardTitle>
        <div className="mt-3 flex flex-col gap-3 md:flex-row">
          <div className="relative flex-1">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={searchInput}
              onChange={(e) => onSearchInputChange(e.target.value)}
              className="pl-9"
              placeholder="Search report reason, details, or reporter"
            />
          </div>
          <Select value={status} onValueChange={(value) => onStatusChange(value as ReportStatusFilter)}>
            <SelectTrigger className="w-full md:w-[180px]">
              <SelectValue placeholder="Status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All statuses</SelectItem>
              <SelectItem value="open">Open</SelectItem>
              <SelectItem value="resolved">Resolved</SelectItem>
              <SelectItem value="dismissed">Dismissed</SelectItem>
            </SelectContent>
          </Select>
          <Select
            value={targetType}
            onValueChange={(value) => onTargetTypeChange(value as ReportTargetTypeFilter)}
          >
            <SelectTrigger className="w-full md:w-[180px]">
              <SelectValue placeholder="Target type" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All targets</SelectItem>
              <SelectItem value="community_post">Post</SelectItem>
              <SelectItem value="community_comment">Comment</SelectItem>
              <SelectItem value="user_profile">Profile</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </CardHeader>
      <CardContent>
        {loading ? (
          <LoadingSpinner className="py-10" />
        ) : error ? (
          <p className="py-8 text-center text-sm text-destructive">{error}</p>
        ) : reports.length === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">
            No reports found.
          </p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Reason</TableHead>
                <TableHead>Target</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Reporter</TableHead>
                <TableHead className="text-right">Created</TableHead>
                <TableHead className="w-[40px]" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {reports.map((report) => (
                <TableRow key={report.id}>
                  <TableCell>
                    <div className="max-w-[360px] space-y-1">
                      <p className="truncate text-sm font-medium">{report.reason}</p>
                      {report.details ? (
                        <p className="line-clamp-2 text-xs text-muted-foreground">
                          {report.details}
                        </p>
                      ) : null}
                    </div>
                  </TableCell>
                  <TableCell>{reportTargetTypeBadge(report.targetType)}</TableCell>
                  <TableCell>{reportStatusBadge(report.status)}</TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {report.reporter.displayName ?? report.reporter.email}
                  </TableCell>
                  <TableCell className="text-right text-sm text-muted-foreground">
                    {formatDate(report.createdAt)}
                  </TableCell>
                  <TableCell>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon" className="h-8 w-8">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        {report.status === "open" ? (
                          <>
                            <DropdownMenuItem
                              onClick={() => onReview(report, "resolved")}
                            >
                              Resolve report
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              className="text-muted-foreground"
                              onClick={() => onReview(report, "dismissed")}
                            >
                              Dismiss report
                            </DropdownMenuItem>
                          </>
                        ) : null}
                        {report.targetUserId || report.targetUser?.id ? (
                          <DropdownMenuItem onClick={() => onOpenUserActions(report)}>
                            Open user actions
                          </DropdownMenuItem>
                        ) : null}
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}

        <div className="mt-4 flex items-center justify-between">
          <p className="text-xs text-muted-foreground">
            Showing {reports.length === 0 ? 0 : offset + 1}-
            {Math.min(offset + reports.length, total)} of {total}
          </p>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={offset === 0 || loading}
              onClick={onPreviousPage}
            >
              <ChevronLeft className="h-4 w-4" />
              Prev
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={offset + limit >= total || loading}
              onClick={onNextPage}
            >
              Next
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
