"use client";

import { useAdminSession } from "@/components/admin-shell";
import { PageHeader } from "@/components/page-header";
import { ModerationDialog } from "@/components/moderation-dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CommunityPostsTab } from "./CommunityPostsTab";
import { CommunityCommentsTab } from "./CommunityCommentsTab";
import { CommunityReportsTab } from "./CommunityReportsTab";
import { CommunityUserActionsDialog } from "./CommunityUserActionsDialog";
import { useCommunityAdmin } from "../_hooks/use-community-admin";
import {
  canApplyEscalatedCommunitySanctions,
  canArchiveCommunityContent,
  FRONTLINE_MODERATION_STATUS_OPTIONS,
  MODERATION_STATUS_OPTIONS,
  REPORT_REVIEW_STATUS_OPTIONS,
} from "../_lib/community-admin";

export default function CommunityPageClient() {
  const session = useAdminSession();
  const state = useCommunityAdmin();
  const canArchive = canArchiveCommunityContent(session.effectiveRoles);
  const canEscalate = canApplyEscalatedCommunitySanctions(session.effectiveRoles);
  const moderationStatusOptions = canArchive
    ? MODERATION_STATUS_OPTIONS
    : FRONTLINE_MODERATION_STATUS_OPTIONS;

  return (
    <div className="space-y-6">
      <PageHeader title="Community" description="Moderate community posts and discussion comments." />

      <Tabs defaultValue="posts">
        <TabsList>
          <TabsTrigger value="posts">Posts</TabsTrigger>
          <TabsTrigger value="comments">Comments</TabsTrigger>
          <TabsTrigger value="reports">Reports</TabsTrigger>
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
            canArchive={canArchive}
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
            canArchive={canArchive}
          />
        </TabsContent>

        <TabsContent value="reports">
          <CommunityReportsTab
            reports={state.reports}
            total={state.reportsTotal}
            loading={state.reportsLoading}
            error={state.reportsError}
            searchInput={state.reportSearchInput}
            onSearchInputChange={state.setReportSearchInput}
            status={state.reportStatus}
            onStatusChange={(value) => {
              state.setReportStatus(value);
              state.setReportOffset(0);
            }}
            targetType={state.reportTargetType}
            onTargetTypeChange={(value) => {
              state.setReportTargetType(value);
              state.setReportOffset(0);
            }}
            offset={state.reportOffset}
            limit={state.reportLimit}
            onPreviousPage={() =>
              state.setReportOffset((prev) => Math.max(prev - state.reportLimit, 0))
            }
            onNextPage={() => state.setReportOffset((prev) => prev + state.reportLimit)}
            onReview={state.openReportReview}
            onOpenUserActions={state.openUserActions}
          />
        </TabsContent>
      </Tabs>

      <ModerationDialog
        open={state.postDialogOpen}
        onOpenChange={state.setPostDialogOpen}
        title="Moderate Community Post"
        description="Provide moderation reason for audit traceability."
        statusOptions={moderationStatusOptions}
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
        statusOptions={moderationStatusOptions}
        initialStatus={state.commentTargetStatus}
        onSubmit={async ({ status, reason }) => {
          await state.submitCommentModeration(status as "active" | "hidden" | "archived", reason);
        }}
      />

      <ModerationDialog
        open={state.reportDialogOpen}
        onOpenChange={state.setReportDialogOpen}
        title="Review Community Report"
        description="Apply a report review decision with a short note."
        statusOptions={REPORT_REVIEW_STATUS_OPTIONS}
        initialStatus={state.reportTargetStatus}
        onSubmit={async ({ status, reason }) => {
          await state.submitReportReview(status as "resolved" | "dismissed", reason);
        }}
      />

      <CommunityUserActionsDialog
        open={state.userActionsDialogOpen}
        onOpenChange={state.setUserActionsDialogOpen}
        userId={state.selectedModerationUserId}
        reportId={state.selectedModerationReportId}
        canEscalate={canEscalate}
      />
    </div>
  );
}
