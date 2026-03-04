"use client";

import { ChevronLeft, ChevronRight, MoreHorizontal, Search } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { PageHeader } from "@/components/page-header";
import { ModerationDialog } from "@/components/moderation-dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
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
import { useUpdatesAdmin } from "../_hooks/use-updates-admin";
import {
  formatDate,
  statusBadge,
  UPDATE_STATUS_OPTIONS,
  urgencyBadge,
  type StatusFilter,
} from "../_lib/updates-admin";
import type { UpdateStatus } from "@/lib/api-client";

export default function UpdatesPageClient() {
  const state = useUpdatesAdmin();

  return (
    <div className="space-y-6">
      <PageHeader title="Updates" description="Moderate project updates and publication visibility." />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Update Feed</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={state.searchInput}
                onChange={(e) => state.setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search title, content, or project"
              />
            </div>
            <Select
              value={state.status}
              onValueChange={(next) => {
                state.setStatus(next as StatusFilter);
                state.setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[180px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All statuses</SelectItem>
                {UPDATE_STATUS_OPTIONS.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Select
              value={String(state.limit)}
              onValueChange={(next) => {
                state.setLimit(Number(next));
                state.setOffset(0);
              }}
            >
              <SelectTrigger className="w-full md:w-[140px]">
                <SelectValue placeholder="Page size" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="25">25 / page</SelectItem>
                <SelectItem value="50">50 / page</SelectItem>
                <SelectItem value="100">100 / page</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardHeader>
        <CardContent>
          {state.loading ? (
            <LoadingSpinner className="py-10" />
          ) : state.error ? (
            <p className="py-8 text-center text-sm text-destructive">{state.error}</p>
          ) : state.updates.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No updates found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Update</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Urgency</TableHead>
                  <TableHead>Author</TableHead>
                  <TableHead className="text-right">Created</TableHead>
                  <TableHead className="w-[40px]" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {state.updates.map((update) => (
                  <TableRow key={update.id}>
                    <TableCell>
                      <div className="min-w-0">
                        <p className="truncate font-medium">{update.title}</p>
                        <p className="truncate text-xs text-muted-foreground">{update.project.name}</p>
                      </div>
                    </TableCell>
                    <TableCell>{statusBadge(update.status)}</TableCell>
                    <TableCell>{urgencyBadge(update.urgency)}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {update.author.displayName ?? update.author.email}
                    </TableCell>
                    <TableCell className="text-right text-sm text-muted-foreground">
                      {formatDate(update.createdAt)}
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon" className="h-8 w-8">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          {update.status !== "published" && (
                            <DropdownMenuItem onClick={() => state.openModeration(update, "published")}>
                              Set Published
                            </DropdownMenuItem>
                          )}
                          {update.status !== "hidden" && (
                            <DropdownMenuItem onClick={() => state.openModeration(update, "hidden")}>
                              Set Hidden
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuSeparator />
                          {update.status !== "archived" && (
                            <DropdownMenuItem className="text-destructive" onClick={() => state.openModeration(update, "archived")}>
                              Set Archived
                            </DropdownMenuItem>
                          )}
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}

          <div className="mt-4 flex justify-end gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={state.offset === 0 || state.loading}
              onClick={() => state.setOffset((prev) => Math.max(prev - state.limit, 0))}
            >
              <ChevronLeft className="h-4 w-4" />
              Prev
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={state.updates.length < state.limit || state.loading}
              onClick={() => state.setOffset((prev) => prev + state.limit)}
            >
              Next
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      <ModerationDialog
        open={state.dialogOpen}
        onOpenChange={state.setDialogOpen}
        title={`Moderate Update${state.selectedUpdate ? `: ${state.selectedUpdate.title}` : ""}`}
        description="Every moderation decision requires a reason for traceability."
        statusOptions={UPDATE_STATUS_OPTIONS}
        initialStatus={state.targetStatus}
        onSubmit={async ({ status, reason }) => {
          await state.submitModeration(status as UpdateStatus, reason);
        }}
      />
    </div>
  );
}
