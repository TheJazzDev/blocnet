"use client";

import { PageHeader } from "@/components/page-header";
import { ModerationDialog } from "@/components/moderation-dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CommunityPostsTab } from "./CommunityPostsTab";
import { CommunityCommentsTab } from "./CommunityCommentsTab";
import { useCommunityAdmin } from "../_hooks/use-community-admin";
import { MODERATION_STATUS_OPTIONS } from "../_lib/community-admin";

export default function CommunityPageClient() {
  const state = useCommunityAdmin();

  return (
    <div className="space-y-6">
      <PageHeader title="Community" description="Moderate community posts and discussion comments." />

      <Tabs defaultValue="posts">
        <TabsList>
          <TabsTrigger value="posts">Posts</TabsTrigger>
          <TabsTrigger value="comments">Comments</TabsTrigger>
        </TabsList>

        <TabsContent value="posts">
          <CommunityPostsTab
            posts={state.posts}
            loading={state.postsLoading}
            error={state.postsError}
            searchInput={state.postSearchInput}
            onSearchInputChange={state.setPostSearchInput}
            status={state.postStatus}
            onStatusChange={(value) => {
              state.setPostStatus(value);
              state.setPostOffset(0);
            }}
            topic={state.postTopic}
            onTopicChange={(value) => {
              state.setPostTopic(value);
              state.setPostOffset(0);
            }}
            offset={state.postOffset}
            limit={state.postLimit}
            onPreviousPage={() =>
              state.setPostOffset((prev) => Math.max(prev - state.postLimit, 0))
            }
            onNextPage={() => state.setPostOffset((prev) => prev + state.postLimit)}
            onModerate={state.openPostModeration}
          />
        </TabsContent>

        <TabsContent value="comments">
          <CommunityCommentsTab
            comments={state.comments}
            loading={state.commentsLoading}
            error={state.commentsError}
            searchInput={state.commentSearchInput}
            onSearchInputChange={state.setCommentSearchInput}
            status={state.commentStatus}
            onStatusChange={(value) => {
              state.setCommentStatus(value);
              state.setCommentOffset(0);
            }}
            offset={state.commentOffset}
            limit={state.commentLimit}
            onPreviousPage={() =>
              state.setCommentOffset((prev) => Math.max(prev - state.commentLimit, 0))
            }
            onNextPage={() =>
              state.setCommentOffset((prev) => prev + state.commentLimit)
            }
            onModerate={state.openCommentModeration}
          />
        </TabsContent>
      </Tabs>

      <ModerationDialog
        open={state.postDialogOpen}
        onOpenChange={state.setPostDialogOpen}
        title="Moderate Community Post"
        description="Provide moderation reason for audit traceability."
        statusOptions={MODERATION_STATUS_OPTIONS}
        initialStatus={state.postTargetStatus}
        onSubmit={async ({ status, reason }) => {
          await state.submitPostModeration(status as "active" | "hidden" | "archived", reason);
        }}
      />

      <ModerationDialog
        open={state.commentDialogOpen}
        onOpenChange={state.setCommentDialogOpen}
        title="Moderate Community Comment"
        description="Provide moderation reason for audit traceability."
        statusOptions={MODERATION_STATUS_OPTIONS}
        initialStatus={state.commentTargetStatus}
        onSubmit={async ({ status, reason }) => {
          await state.submitCommentModeration(status as "active" | "hidden" | "archived", reason);
        }}
      />
    </div>
  );
}
