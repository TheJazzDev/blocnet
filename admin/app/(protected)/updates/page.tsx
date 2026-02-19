"use client";

import { useEffect, useState } from "react";
import {
  Search,
  MoreHorizontal,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
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
  clientApi,
  type AdminUpdate,
  type UpdateStatus,
} from "@/lib/api-client";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

type StatusFilter = "all" | UpdateStatus;

function statusBadge(status: UpdateStatus) {
  switch (status) {
    case "published":
      return (
        <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500">
          Published
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

function urgencyBadge(urgency: AdminUpdate["urgency"]) {
  switch (urgency) {
    case "high":
      return <Badge className="bg-red-500/15 text-red-300">High</Badge>;
    case "medium":
      return <Badge className="bg-amber-500/15 text-amber-300">Medium</Badge>;
    case "low":
      return <Badge className="bg-slate-500/15 text-slate-300">Low</Badge>;
  }
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export default function UpdatesPage() {
  const [updates, setUpdates] = useState<AdminUpdate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedUpdate, setSelectedUpdate] = useState<AdminUpdate | null>(null);
  const [targetStatus, setTargetStatus] = useState<UpdateStatus>("published");

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
      .listAdminUpdates({
        q,
        status: status === "all" ? undefined : status,
        limit,
        offset,
      })
      .then(setUpdates)
      .catch((e: unknown) => {
        setUpdates([]);
        setError(e instanceof Error ? e.message : "Failed to load updates");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, status, limit, offset]);

  function openModeration(update: AdminUpdate, nextStatus: UpdateStatus) {
    setSelectedUpdate(update);
    setTargetStatus(nextStatus);
    setDialogOpen(true);
  }

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
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search title, content, or project"
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
                <SelectItem value="published">Published</SelectItem>
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
            <LoadingSpinner className="py-10" />
          ) : error ? (
            <p className="py-8 text-center text-sm text-destructive">{error}</p>
          ) : updates.length === 0 ? (
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
                {updates.map((update) => (
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
                            <DropdownMenuItem onClick={() => openModeration(update, "published")}>
                              Set Published
                            </DropdownMenuItem>
                          )}
                          {update.status !== "hidden" && (
                            <DropdownMenuItem onClick={() => openModeration(update, "hidden")}>
                              Set Hidden
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuSeparator />
                          {update.status !== "archived" && (
                            <DropdownMenuItem
                              className="text-destructive"
                              onClick={() => openModeration(update, "archived")}
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
              disabled={updates.length < limit || loading}
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
        title={`Moderate Update${selectedUpdate ? `: ${selectedUpdate.title}` : ""}`}
        description="Every moderation decision requires a reason for traceability."
        statusOptions={[
          { value: "published", label: "Published" },
          { value: "hidden", label: "Hidden" },
          { value: "archived", label: "Archived" },
        ]}
        initialStatus={targetStatus}
        onSubmit={async ({ status: nextStatus, reason }) => {
          if (!selectedUpdate) return;
          const previous = updates;
          setUpdates((rows) =>
            rows.map((row) =>
              row.id === selectedUpdate.id
                ? { ...row, status: nextStatus as UpdateStatus }
                : row,
            ),
          );
          try {
            await clientApi.moderateUpdateStatus(selectedUpdate.id, {
              status: nextStatus as UpdateStatus,
              reason,
            });
            await load();
          } catch (error) {
            setUpdates(previous);
            throw error;
          }
        }}
      />
    </div>
  );
}
