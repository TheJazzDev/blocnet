"use client";

import { useEffect, useState } from "react";
import {
  Search,
  MoreHorizontal,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
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
  clientApi,
  type AdminProject,
  type ProjectStatus,
} from "@/lib/api-client";
import { isModeratorOnly } from "@/lib/rbac";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

type StatusFilter = "all" | ProjectStatus;

function statusBadge(status: ProjectStatus) {
  switch (status) {
    case "active":
      return (
        <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500">
          Active
        </Badge>
      );
    case "paused":
      return (
        <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">
          Paused
        </Badge>
      );
    case "hidden":
      return (
        <Badge variant="outline" className="border-amber-500/20 bg-amber-500/10 text-amber-400">
          Hidden
        </Badge>
      );
    case "archived":
      return (
        <Badge variant="outline" className="border-red-500/20 bg-red-500/10 text-red-400">
          Archived
        </Badge>
      );
  }
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
}

function TableSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 py-2">
          <Skeleton className="h-8 w-8 rounded-lg" />
          <Skeleton className="h-4 w-32" />
          <Skeleton className="ml-auto h-4 w-16" />
          <Skeleton className="h-4 w-16" />
          <Skeleton className="h-4 w-12" />
          <Skeleton className="h-4 w-12" />
          <Skeleton className="h-4 w-20" />
        </div>
      ))}
    </div>
  );
}

export default function ProjectsPage() {
  const session = useAdminSession();
  const moderatorOnly = isModeratorOnly(session.roles);

  const [projects, setProjects] = useState<AdminProject[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedProject, setSelectedProject] = useState<AdminProject | null>(null);
  const [targetStatus, setTargetStatus] = useState<ProjectStatus>("active");

  useEffect(() => {
    const timer = setTimeout(() => {
      setQ(searchInput.trim());
      setOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput]);

  function load() {
    setLoading(true);
    setError(null);
    clientApi
      .listAdminProjects({
        q,
        status: status === "all" ? undefined : status,
        limit,
        offset,
      })
      .then((rows) => setProjects(rows))
      .catch((e: unknown) => {
        setProjects([]);
        setError(e instanceof Error ? e.message : "Failed to load projects");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, status, limit, offset]);

  function openModeration(project: AdminProject, nextStatus: ProjectStatus) {
    setSelectedProject(project);
    setTargetStatus(nextStatus);
    setDialogOpen(true);
  }

  const statusOptions = moderatorOnly
    ? [
        { value: "active", label: "Active" },
        { value: "hidden", label: "Hidden" },
        { value: "archived", label: "Archived" },
      ]
    : [
        { value: "active", label: "Active" },
        { value: "paused", label: "Paused" },
        { value: "hidden", label: "Hidden" },
        { value: "archived", label: "Archived" },
      ];

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
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search by name, symbol, slug, or description"
              />
            </div>
            <Select
              value={status}
              onValueChange={(next) => {
                setStatus(next as StatusFilter);
                setOffset(0);
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
              value={String(limit)}
              onValueChange={(next) => {
                setLimit(Number(next));
                setOffset(0);
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
          {loading ? (
            <TableSkeleton />
          ) : error ? (
            <p className="py-8 text-center text-sm text-destructive">{error}</p>
          ) : projects.length === 0 ? (
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
                {projects.map((project) => (
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
                            <DropdownMenuItem onClick={() => openModeration(project, "active")}>
                              Set Active
                            </DropdownMenuItem>
                          )}
                          {!moderatorOnly && project.status !== "paused" && (
                            <DropdownMenuItem onClick={() => openModeration(project, "paused")}>
                              Set Paused
                            </DropdownMenuItem>
                          )}
                          {project.status !== "hidden" && (
                            <DropdownMenuItem onClick={() => openModeration(project, "hidden")}>
                              Set Hidden
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuSeparator />
                          {project.status !== "archived" && (
                            <DropdownMenuItem
                              className="text-destructive"
                              onClick={() => openModeration(project, "archived")}
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
              disabled={offset === 0 || loading}
              onClick={() => setOffset((prev) => Math.max(prev - limit, 0))}
            >
              <ChevronLeft className="h-4 w-4" />
              Prev
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={projects.length < limit || loading}
              onClick={() => setOffset((prev) => prev + limit)}
            >
              Next
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </CardContent>
      </Card>

      <ModerationDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        title={`Moderate Project${selectedProject ? `: ${selectedProject.name}` : ""}`}
        description="Status changes are reversible and always recorded in the audit log."
        statusOptions={statusOptions}
        initialStatus={targetStatus}
        onSubmit={async ({ status: nextStatus, reason }) => {
          if (!selectedProject) return;
          const previous = projects;
          setProjects((rows) =>
            rows.map((row) =>
              row.id === selectedProject.id
                ? { ...row, status: nextStatus as ProjectStatus }
                : row,
            ),
          );
          try {
            await clientApi.moderateProjectStatus(selectedProject.id, {
              status: nextStatus as ProjectStatus,
              reason,
            });
            await load();
          } catch (error) {
            setProjects(previous);
            throw error;
          }
        }}
      />
    </div>
  );
}
