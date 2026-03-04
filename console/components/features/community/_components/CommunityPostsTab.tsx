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
  DropdownMenuSeparator,
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
import type { AdminCommunityPost, ContentStatus } from "@/lib/api-client";
import { formatDate, statusBadge, topicBadge, type StatusFilter, type TopicFilter } from "../_lib/community-admin";

type CommunityPostsTabProps = {
  posts: AdminCommunityPost[];
  loading: boolean;
  error: string | null;
  searchInput: string;
  onSearchInputChange: (value: string) => void;
  status: StatusFilter;
  onStatusChange: (value: StatusFilter) => void;
  topic: TopicFilter;
  onTopicChange: (value: TopicFilter) => void;
  offset: number;
  limit: number;
  onPreviousPage: () => void;
  onNextPage: () => void;
  onModerate: (post: AdminCommunityPost, status: ContentStatus) => void;
};

export function CommunityPostsTab({
  posts,
  loading,
  error,
  searchInput,
  onSearchInputChange,
  status,
  onStatusChange,
  topic,
  onTopicChange,
  offset,
  limit,
  onPreviousPage,
  onNextPage,
  onModerate,
}: CommunityPostsTabProps) {
  return (
    <Card>
      <CardHeader className="pb-3">
        <CardTitle className="text-base">Community Posts</CardTitle>
        <div className="mt-3 flex flex-col gap-3 md:flex-row">
          <div className="relative flex-1">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={searchInput}
              onChange={(e) => onSearchInputChange(e.target.value)}
              className="pl-9"
              placeholder="Search post content"
            />
          </div>
          <Select value={status} onValueChange={(value) => onStatusChange(value as StatusFilter)}>
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
          <Select value={topic} onValueChange={(value) => onTopicChange(value as TopicFilter)}>
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
        {loading ? (
          <LoadingSpinner className="py-10" />
        ) : error ? (
          <p className="py-8 text-center text-sm text-destructive">{error}</p>
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
                          <DropdownMenuItem onClick={() => onModerate(post, "active")}>
                            Set Active
                          </DropdownMenuItem>
                        )}
                        {post.status !== "hidden" && (
                          <DropdownMenuItem onClick={() => onModerate(post, "hidden")}>
                            Set Hidden
                          </DropdownMenuItem>
                        )}
                        <DropdownMenuSeparator />
                        {post.status !== "archived" && (
                          <DropdownMenuItem
                            className="text-destructive"
                            onClick={() => onModerate(post, "archived")}
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
          <Button variant="outline" size="sm" disabled={offset === 0 || loading} onClick={onPreviousPage}>
            <ChevronLeft className="h-4 w-4" />
            Prev
          </Button>
          <Button
            variant="outline"
            size="sm"
            disabled={posts.length < limit || loading}
            onClick={onNextPage}
          >
            Next
            <ChevronRight className="h-4 w-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
