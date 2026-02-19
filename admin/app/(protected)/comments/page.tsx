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
  type AdminComment,
  type ContentStatus,
} from "@/lib/api-client";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

type StatusFilter = "all" | ContentStatus;

function statusBadge(status: ContentStatus) {
  switch (status) {
    case "active":
      return (
        <Badge variant="outline" className="border-emerald-500/20 bg-emerald-500/10 text-emerald-500">
          Active
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
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export default function CommentsPage() {
  const [comments, setComments] = useState<AdminComment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchInput, setSearchInput] = useState("");
  const [q, setQ] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedComment, setSelectedComment] = useState<AdminComment | null>(null);
  const [targetStatus, setTargetStatus] = useState<ContentStatus>("active");

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
      .listAdminComments({
        q,
        status: status === "all" ? undefined : status,
        limit,
        offset,
      })
      .then(setComments)
      .catch((e: unknown) => {
        setComments([]);
        setError(e instanceof Error ? e.message : "Failed to load comments");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, status, limit, offset]);

  function openModeration(comment: AdminComment, nextStatus: ContentStatus) {
    setSelectedComment(comment);
    setTargetStatus(nextStatus);
    setDialogOpen(true);
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Comments" description="Moderate update comments with reversible status changes." />

      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Update Comments</CardTitle>
          <div className="mt-3 flex flex-col gap-3 md:flex-row">
            <div className="relative flex-1">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                className="pl-9"
                placeholder="Search comment content"
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
          ) : comments.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No comments found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Comment</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Author</TableHead>
                  <TableHead className="text-right">Created</TableHead>
                  <TableHead className="w-[40px]" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {comments.map((comment) => (
                  <TableRow key={comment.id}>
                    <TableCell>
                      <div className="min-w-0">
                        <p className="truncate text-sm">{comment.content}</p>
                        <p className="truncate text-xs text-muted-foreground">{comment.update.title}</p>
                      </div>
                    </TableCell>
                    <TableCell>{statusBadge(comment.status)}</TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {comment.author.displayName ?? comment.author.email}
                    </TableCell>
                    <TableCell className="text-right text-sm text-muted-foreground">
                      {formatDate(comment.createdAt)}
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon" className="h-8 w-8">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          {comment.status !== "active" && (
                            <DropdownMenuItem onClick={() => openModeration(comment, "active")}>
                              Set Active
                            </DropdownMenuItem>
                          )}
                          {comment.status !== "hidden" && (
                            <DropdownMenuItem onClick={() => openModeration(comment, "hidden")}>
                              Set Hidden
                            </DropdownMenuItem>
                          )}
                          <DropdownMenuSeparator />
                          {comment.status !== "archived" && (
                            <DropdownMenuItem
                              className="text-destructive"
                              onClick={() => openModeration(comment, "archived")}
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
              disabled={comments.length < limit || loading}
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
        title="Moderate Comment"
        description="Provide a reason for this moderation action."
        statusOptions={[
          { value: "active", label: "Active" },
          { value: "hidden", label: "Hidden" },
          { value: "archived", label: "Archived" },
        ]}
        initialStatus={targetStatus}
        onSubmit={async ({ status: nextStatus, reason }) => {
          if (!selectedComment) return;
          const previous = comments;
          setComments((rows) =>
            rows.map((row) =>
              row.id === selectedComment.id
                ? { ...row, status: nextStatus as ContentStatus }
                : row,
            ),
          );
          try {
            await clientApi.moderateCommentStatus(selectedComment.id, {
              status: nextStatus as ContentStatus,
              reason,
            });
            await load();
          } catch (error) {
            setComments(previous);
            throw error;
          }
        }}
      />
    </div>
  );
}
