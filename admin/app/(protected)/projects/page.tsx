"use client";

import { useEffect, useState } from "react";
import { Search, Plus, MoreHorizontal, ExternalLink, Pause, Play, Archive, Loader2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { PageHeader } from "@/components/page-header";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { clientApi, type Project } from "@/lib/api-client";

function statusBadge(status: "active" | "paused" | "archived") {
  switch (status) {
    case "active":
      return <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500">Active</Badge>;
    case "paused":
      return <Badge variant="outline" className="border-yellow-500/20 bg-yellow-500/10 text-yellow-500">Paused</Badge>;
    case "archived":
      return <Badge variant="outline" className="border-red-500/20 bg-red-500/10 text-red-400">Archived</Badge>;
  }
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", { year: "numeric", month: "short", day: "numeric" });
}

function TableSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 6 }).map((_, i) => (
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

function ProjectActions({ project, onRefresh }: { project: Project; onRefresh: () => void }) {
  const [loading, setLoading] = useState(false);

  async function updateStatus(status: "active" | "paused" | "archived") {
    setLoading(true);
    try {
      await clientApi.updateProject(project.id, { status });
      onRefresh();
    } finally {
      setLoading(false);
    }
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon" className="h-8 w-8" disabled={loading}>
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <MoreHorizontal className="h-4 w-4" />}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem asChild>
          <a href={`${process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3080/api"}/projects/${project.id}`} target="_blank" rel="noopener noreferrer">
            <ExternalLink className="h-4 w-4" /> View Details
          </a>
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        {project.status !== "active" && (
          <DropdownMenuItem onClick={() => updateStatus("active")}>
            <Play className="h-4 w-4" /> Set Active
          </DropdownMenuItem>
        )}
        {project.status !== "paused" && (
          <DropdownMenuItem onClick={() => updateStatus("paused")}>
            <Pause className="h-4 w-4" /> Pause Project
          </DropdownMenuItem>
        )}
        {project.status !== "archived" && (
          <DropdownMenuItem className="text-destructive" onClick={() => updateStatus("archived")}>
            <Archive className="h-4 w-4" /> Archive Project
          </DropdownMenuItem>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export default function ProjectsPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  function load() {
    setLoading(true);
    clientApi.listProjects()
      .then(setProjects)
      .catch(() => setProjects([]))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, []);

  const filtered = projects.filter((p) =>
    search === "" ||
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    (p.symbol ?? "").toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <PageHeader title="Projects" description="Manage crypto projects tracked on the platform.">
        <Button>
          <Plus className="h-4 w-4" /> New Project
        </Button>
      </PageHeader>

      <div className="relative flex-1">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          placeholder="Search projects…"
          className="pl-9"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">
            All Projects
            <span className="ml-2 text-sm font-normal text-muted-foreground">
              ({loading ? "…" : filtered.length})
            </span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <TableSkeleton />
          ) : filtered.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No projects found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Project</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Tag</TableHead>
                  <TableHead className="text-right">Updates</TableHead>
                  <TableHead className="text-right">Followers</TableHead>
                  <TableHead className="text-right">Created</TableHead>
                  <TableHead className="w-[40px]" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.map((project) => (
                  <TableRow key={project.id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-secondary text-xs font-bold">
                          {project.symbol?.slice(0, 3) ?? project.name.slice(0, 2).toUpperCase()}
                        </div>
                        <div>
                          <p className="font-medium">{project.name}</p>
                          <p className="text-xs text-muted-foreground">{project.symbol ?? "—"}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>{statusBadge(project.status)}</TableCell>
                    <TableCell><Badge variant="secondary">{project.primaryTag ?? "—"}</Badge></TableCell>
                    <TableCell className="text-right">{project.updatesCount}</TableCell>
                    <TableCell className="text-right">{project.followersCount}</TableCell>
                    <TableCell className="text-right text-muted-foreground text-sm">{formatDate(project.createdAt)}</TableCell>
                    <TableCell>
                      <ProjectActions project={project} onRefresh={load} />
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
