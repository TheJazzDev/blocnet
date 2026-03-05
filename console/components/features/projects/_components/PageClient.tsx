"use client";

import {
  ChevronLeft,
  ChevronRight,
  MoreHorizontal,
  Search,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { PageHeader } from "@/components/page-header";
import { ModerationDialog } from "@/components/moderation-dialog";
import { useAdminSession } from "@/components/admin-shell";
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
import { useProjectsAdmin } from "../_hooks/use-projects-admin";
import { formatDate, statusBadge, type StatusFilter } from "../_lib/projects-admin";
import type { ProjectStatus } from "@/lib/api-client";

export default function ProjectsPageClient() {
  const session = useAdminSession();
  const state = useProjectsAdmin(session.effectiveRoles);

  return (
    <div className="space-y-6">
      <PageHeader title="Projects" description="Moderate project visibility and lifecycle status." />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Project Content</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={state.searchInput}
                onChange={(e) => state.setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search by name, symbol, slug, or description"
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
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="paused">Paused</SelectItem>
                <SelectItem value="hidden">Hidden</SelectItem>
                <SelectItem value="archived">Archived</SelectItem>
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
          ) : state.projects.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No projects found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Project</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Primary Tag</TableHead>
                  <TableHead className="text-right">Updates</TableHead>
                  <TableHead className="text-right">Followers</TableHead>
                  <TableHead className="text-right">Created</TableHead>
                  <TableHead className="w-[40px]" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {state.projects.map((project) => (
                  <TableRow key={project.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-secondary text-xs font-bold">
                          {project.symbol?.slice(0, 3) ?? project.name.slice(0, 2).toUpperCase()}
                        </div>
                        <div className="min-w-0">
                          <p className="truncate font-medium">{project.name}</p>
                          <p className="truncate text-xs text-muted-foreground">{project.symbol ?? "—"}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>{statusBadge(project.status)}</TableCell>
                    <TableCell>
                      <Badge variant="secondary">{project.primaryTag?.name ?? "—"}</Badge>
                    </TableCell>
                    <TableCell className="text-right">{project.counts.updates}</TableCell>
                    <TableCell className="text-right">{project.counts.followers}</TableCell>
                    <TableCell className="text-right text-sm text-muted-foreground">
                      {formatDate(project.createdAt)}
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon" className="h-8 w-8">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          {project.status !== "active" && (
                            <DropdownMenuItem onClick={() => state.openModeration(project, "active")}>
                              Set Active
                            </DropdownMenuItem>
                          )}
                          {!state.moderatorOnly && project.status !== "paused" && (
                            <DropdownMenuItem onClick={() => state.openModeration(project, "paused")}>
                              Set Paused
                            </DropdownMenuItem>
                          )}
                          {project.status !== "hidden" && (
                            <DropdownMenuItem onClick={() => state.openModeration(project, "hidden")}>
                              Set Hidden
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuSeparator />
                          {project.status !== "archived" && (
                            <DropdownMenuItem
                              className="text-destructive"
                              onClick={() => state.openModeration(project, "archived")}
                            >
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
              disabled={state.projects.length < state.limit || state.loading}
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
        title={`Moderate Project${state.selectedProject ? `: ${state.selectedProject.name}` : ""}`}
        description="Status changes are reversible and always recorded in the audit log."
        statusOptions={state.statusOptions}
        initialStatus={state.targetStatus}
        onSubmit={async ({ status, reason }) => {
          await state.submitModeration(status as ProjectStatus, reason);
        }}
      />
    </div>
  );
}
