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
import { Skeleton } from "@/components/ui/skeleton";
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
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  clientApi,
  type AdminCommunityComment,
  type AdminCommunityPost,
  type CommunityTopic,
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
type TopicFilter = "all" | CommunityTopic;

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

function topicBadge(topic: CommunityTopic) {
  const label = topic === "market_talk" ? "Market Talk" : topic === "introductions" ? "Introductions" : "General";
  return <Badge variant="secondary">{label}</Badge>;
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

function TableSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 py-2">
          <Skeleton className="h-4 w-52" />
          <Skeleton className="h-4 w-20" />
          <Skeleton className="h-4 w-24" />
          <Skeleton className="ml-auto h-4 w-20" />
        </div>
      ))}
    </div>
  );
}

export default function CommunityPage() {
  const [posts, setPosts] = useState<AdminCommunityPost[]>([]);
  const [postsLoading, setPostsLoading] = useState(true);
  const [postsError, setPostsError] = useState<string | null>(null);

  const [postSearchInput, setPostSearchInput] = useState("");
  const [postQ, setPostQ] = useState("");
  const [postStatus, setPostStatus] = useState<StatusFilter>("all");
  const [postTopic, setPostTopic] = useState<TopicFilter>("all");
  const postLimit = 25;
  const [postOffset, setPostOffset] = useState(0);

  const [comments, setComments] = useState<AdminCommunityComment[]>([]);
  const [commentsLoading, setCommentsLoading] = useState(true);
  const [commentsError, setCommentsError] = useState<string | null>(null);

  const [commentSearchInput, setCommentSearchInput] = useState("");
  const [commentQ, setCommentQ] = useState("");
  const [commentStatus, setCommentStatus] = useState<StatusFilter>("all");
  const commentLimit = 25;
  const [commentOffset, setCommentOffset] = useState(0);

  const [postDialogOpen, setPostDialogOpen] = useState(false);
  const [selectedPost, setSelectedPost] = useState<AdminCommunityPost | null>(null);
  const [postTargetStatus, setPostTargetStatus] = useState<ContentStatus>("active");

  const [commentDialogOpen, setCommentDialogOpen] = useState(false);
  const [selectedComment, setSelectedComment] = useState<AdminCommunityComment | null>(null);
  const [commentTargetStatus, setCommentTargetStatus] = useState<ContentStatus>("active");

  useEffect(() => {
    const timer = setTimeout(() => {
      setPostQ(postSearchInput.trim());
      setPostOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [postSearchInput]);

  useEffect(() => {
    const timer = setTimeout(() => {
      setCommentQ(commentSearchInput.trim());
      setCommentOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [commentSearchInput]);

  function loadPosts() {
    setPostsLoading(true);
    setPostsError(null);
    clientApi
      .listAdminCommunityPosts({
        q: postQ,
        status: postStatus === "all" ? undefined : postStatus,
        topic: postTopic === "all" ? undefined : postTopic,
        limit: postLimit,
        offset: postOffset,
      })
      .then(setPosts)
      .catch((e: unknown) => {
        setPosts([]);
        setPostsError(e instanceof Error ? e.message : "Failed to load community posts");
      })
      .finally(() => setPostsLoading(false));
  }

  function loadComments() {
    setCommentsLoading(true);
    setCommentsError(null);
    clientApi
      .listAdminCommunityComments({
        q: commentQ,
        status: commentStatus === "all" ? undefined : commentStatus,
        limit: commentLimit,
        offset: commentOffset,
      })
      .then(setComments)
      .catch((e: unknown) => {
        setComments([]);
        setCommentsError(e instanceof Error ? e.message : "Failed to load community comments");
      })
      .finally(() => setCommentsLoading(false));
  }

  useEffect(() => {
    loadPosts();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [postQ, postStatus, postTopic, postOffset]);

  useEffect(() => {
    loadComments();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [commentQ, commentStatus, commentOffset]);

  function openPostModeration(post: AdminCommunityPost, nextStatus: ContentStatus) {
    setSelectedPost(post);
    setPostTargetStatus(nextStatus);
    setPostDialogOpen(true);
  }

  function openCommentModeration(comment: AdminCommunityComment, nextStatus: ContentStatus) {
    setSelectedComment(comment);
    setCommentTargetStatus(nextStatus);
    setCommentDialogOpen(true);
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Community" description="Moderate community posts and discussion comments." />

      <Tabs defaultValue="posts">
        <TabsList>
          <TabsTrigger value="posts">Posts</TabsTrigger>
          <TabsTrigger value="comments">Comments</TabsTrigger>
        </TabsList>

        <TabsContent value="posts">
          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-base">Community Posts</CardTitle>
              <div className="mt-3 flex flex-col gap-3 md:flex-row">
                <div className="relative flex-1">
                  <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    value={postSearchInput}
                    onChange={(e) => setPostSearchInput(e.target.value)}
                    className="pl-9"
                    placeholder="Search post content"
                  />
                </div>
                <Select
                  value={postStatus}
                  onValueChange={(next) => {
                    setPostStatus(next as StatusFilter);
                    setPostOffset(0);
                  }}
                >
                  <SelectTrigger className="w-full md:w-[170px]">
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
                  value={postTopic}
                  onValueChange={(next) => {
                    setPostTopic(next as TopicFilter);
                    setPostOffset(0);
                  }}
                >
                  <SelectTrigger className="w-full md:w-[190px]">
                    <SelectValue placeholder="Topic" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All topics</SelectItem>
                    <SelectItem value="general">General</SelectItem>
                    <SelectItem value="market_talk">Market Talk</SelectItem>
                    <SelectItem value="introductions">Introductions</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </CardHeader>
            <CardContent>
              {postsLoading ? (
                <TableSkeleton />
              ) : postsError ? (
                <p className="py-8 text-center text-sm text-destructive">{postsError}</p>
              ) : posts.length === 0 ? (
                <p className="py-8 text-center text-sm text-muted-foreground">No posts found.</p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Post</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Topic</TableHead>
                      <TableHead>Author</TableHead>
                      <TableHead className="text-right">Created</TableHead>
                      <TableHead className="w-[40px]" />
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {posts.map((post) => (
                      <TableRow key={post.id}>
                        <TableCell>
                          <p className="line-clamp-2 text-sm">{post.content}</p>
                        </TableCell>
                        <TableCell>{statusBadge(post.status)}</TableCell>
                        <TableCell>{topicBadge(post.topic)}</TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {post.author.displayName ?? post.author.email}
                        </TableCell>
                        <TableCell className="text-right text-sm text-muted-foreground">
                          {formatDate(post.createdAt)}
                        </TableCell>
                        <TableCell>
                          <DropdownMenu>
                            <DropdownMenuTrigger asChild>
                              <Button variant="ghost" size="icon" className="h-8 w-8">
                                <MoreHorizontal className="h-4 w-4" />
                              </Button>
                            </DropdownMenuTrigger>
                            <DropdownMenuContent align="end">
                              {post.status !== "active" && (
                                <DropdownMenuItem onClick={() => openPostModeration(post, "active")}>
                                  Set Active
                                </DropdownMenuItem>
                              )}
                              {post.status !== "hidden" && (
                                <DropdownMenuItem onClick={() => openPostModeration(post, "hidden")}>
                                  Set Hidden
                                </DropdownMenuItem>
                              )}
                              <DropdownMenuSeparator />
                              {post.status !== "archived" && (
                                <DropdownMenuItem
                                  className="text-destructive"
                                  onClick={() => openPostModeration(post, "archived")}
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
                  disabled={postOffset === 0 || postsLoading}
                  onClick={() => setPostOffset((prev) => Math.max(prev - postLimit, 0))}
                >
                  <ChevronLeft className="h-4 w-4" />
                  Prev
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={posts.length < postLimit || postsLoading}
                  onClick={() => setPostOffset((prev) => prev + postLimit)}
                >
                  Next
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="comments">
          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-base">Community Comments</CardTitle>
              <div className="mt-3 flex flex-col gap-3 md:flex-row">
                <div className="relative flex-1">
                  <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    value={commentSearchInput}
                    onChange={(e) => setCommentSearchInput(e.target.value)}
                    className="pl-9"
                    placeholder="Search comment content"
                  />
                </div>
                <Select
                  value={commentStatus}
                  onValueChange={(next) => {
                    setCommentStatus(next as StatusFilter);
                    setCommentOffset(0);
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
              </div>
            </CardHeader>
            <CardContent>
              {commentsLoading ? (
                <TableSkeleton />
              ) : commentsError ? (
                <p className="py-8 text-center text-sm text-destructive">{commentsError}</p>
              ) : comments.length === 0 ? (
                <p className="py-8 text-center text-sm text-muted-foreground">No comments found.</p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Comment</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Topic</TableHead>
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
                            <p className="truncate text-xs text-muted-foreground">{comment.post.preview}</p>
                          </div>
                        </TableCell>
                        <TableCell>{statusBadge(comment.status)}</TableCell>
                        <TableCell>{topicBadge(comment.post.topic)}</TableCell>
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
                                <DropdownMenuItem onClick={() => openCommentModeration(comment, "active")}>
                                  Set Active
                                </DropdownMenuItem>
                              )}
                              {comment.status !== "hidden" && (
                                <DropdownMenuItem onClick={() => openCommentModeration(comment, "hidden")}>
                                  Set Hidden
                                </DropdownMenuItem>
                              )}
                              <DropdownMenuSeparator />
                              {comment.status !== "archived" && (
                                <DropdownMenuItem
                                  className="text-destructive"
                                  onClick={() => openCommentModeration(comment, "archived")}
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
                  disabled={commentOffset === 0 || commentsLoading}
                  onClick={() => setCommentOffset((prev) => Math.max(prev - commentLimit, 0))}
                >
                  <ChevronLeft className="h-4 w-4" />
                  Prev
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={comments.length < commentLimit || commentsLoading}
                  onClick={() => setCommentOffset((prev) => prev + commentLimit)}
                >
                  Next
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      <ModerationDialog
        open={postDialogOpen}
        onOpenChange={setPostDialogOpen}
        title="Moderate Community Post"
        description="Provide moderation reason for audit traceability."
        statusOptions={[
          { value: "active", label: "Active" },
          { value: "hidden", label: "Hidden" },
          { value: "archived", label: "Archived" },
        ]}
        initialStatus={postTargetStatus}
        onSubmit={async ({ status: nextStatus, reason }) => {
          if (!selectedPost) return;
          const previous = posts;
          setPosts((rows) =>
            rows.map((row) =>
              row.id === selectedPost.id
                ? { ...row, status: nextStatus as ContentStatus }
                : row,
            ),
          );
          try {
            await clientApi.moderateCommunityPostStatus(selectedPost.id, {
              status: nextStatus as ContentStatus,
              reason,
            });
            await loadPosts();
          } catch (error) {
            setPosts(previous);
            throw error;
          }
        }}
      />

      <ModerationDialog
        open={commentDialogOpen}
        onOpenChange={setCommentDialogOpen}
        title="Moderate Community Comment"
        description="Provide moderation reason for audit traceability."
        statusOptions={[
          { value: "active", label: "Active" },
          { value: "hidden", label: "Hidden" },
          { value: "archived", label: "Archived" },
        ]}
        initialStatus={commentTargetStatus}
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
            await clientApi.moderateCommunityCommentStatus(selectedComment.id, {
              status: nextStatus as ContentStatus,
              reason,
            });
            await loadComments();
          } catch (error) {
            setComments(previous);
            throw error;
          }
        }}
      />
    </div>
  );
}
