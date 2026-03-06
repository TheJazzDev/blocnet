export type ProjectStatus = "active" | "paused" | "hidden" | "archived";
export type UpdateStatus = "published" | "hidden" | "archived";
export type ContentStatus = "active" | "hidden" | "archived";
export type CommunityTopic = "general" | "market_talk" | "introductions";

export interface ActorSummary {
  id: string;
  email: string;
  displayName: string | null;
}

export interface ModerationInfo {
  moderatedBy: ActorSummary | null;
  moderatedAt: string | null;
  moderationReason: string | null;
}

export interface AdminProject {
  id: string;
  name: string;
  symbol: string | null;
  status: ProjectStatus;
  description: string;
  slug: string;
  primaryTag: { id: string; name: string } | null;
  owner: ActorSummary | null;
  moderation: ModerationInfo;
  counts: {
    updates: number;
    followers: number;
  };
  createdAt: string;
  updatedAt: string;
}

export interface AdminUpdate {
  id: string;
  projectId: string;
  authorId: string;
  title: string;
  contentMd: string;
  urgency: "high" | "medium" | "low";
  status: UpdateStatus;
  author: ActorSummary;
  project: {
    id: string;
    name: string;
    slug: string;
  };
  moderation: ModerationInfo;
  createdAt: string;
  updatedAt: string;
}

export interface AdminComment {
  id: string;
  updateId: string;
  authorId: string;
  content: string;
  status: ContentStatus;
  author: ActorSummary;
  update: {
    id: string;
    title: string;
    project: {
      id: string;
      name: string;
    };
  };
  moderation: ModerationInfo;
  createdAt: string;
  updatedAt: string;
}

export interface AdminCommunityPost {
  id: string;
  authorId: string;
  topic: CommunityTopic;
  content: string;
  status: ContentStatus;
  author: ActorSummary;
  moderation: ModerationInfo;
  counts: {
    comments: number;
    reactions: number;
  };
  createdAt: string;
  updatedAt: string;
}

export interface AdminCommunityComment {
  id: string;
  postId: string;
  authorId: string;
  content: string;
  status: ContentStatus;
  author: ActorSummary;
  post: {
    id: string;
    topic: CommunityTopic;
    preview: string;
  };
  moderation: ModerationInfo;
  createdAt: string;
  updatedAt: string;
}

export interface AdminApplication {
  id: string;
  userId: string;
  user: {
    id: string;
    email: string;
    displayName: string | null;
    avatarUrl: string | null;
  };
  targetRole: "admin" | "hunter";
  reason: string;
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  reviewedAt: string | null;
}

export interface ProjectProposal {
  id: string;
  name: string;
  symbol: string | null;
  description: string;
  reason: string | null;
  primaryTag: { id: string; name: string } | null;
  applicant: {
    id: string;
    email: string;
    displayName: string | null;
  };
  status: "pending" | "approved" | "rejected";
  createdAt: string;
  reviewedAt: string | null;
}

export interface AuditLog {
  id: string;
  action: string;
  actor: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  resourceType: string;
  resourceId: string | null;
  description: string | null;
  metadata: Record<string, unknown>;
  createdAt: string;
}

export type OpsEventSource =
  | "email"
  | "wallet"
  | "tips"
  | "social"
  | "auth"
  | "notifications"
  | "system";
export type OpsEventProvider =
  | "resend"
  | "supabase"
  | "turnkey"
  | "bsc"
  | "x"
  | "instagram"
  | "tiktok"
  | "youtube"
  | "linkedin"
  | "discord"
  | "telegram"
  | "internal"
  | "unknown";
export type OpsEventStatus = "success" | "warning" | "error" | "info";

export type CommunityReportTargetType =
  | "community_post"
  | "community_comment"
  | "user_profile";
export type CommunityReportStatus = "open" | "resolved" | "dismissed";
export type CommunityModerationActionType =
  | "warning"
  | "mute"
  | "suspend"
  | "restrict_posting"
  | "restrict_commenting"
  | "clear_restrictions";

export interface OpsEvent {
  id: string;
  action: string;
  source: OpsEventSource;
  provider: OpsEventProvider;
  status: OpsEventStatus;
  resourceType: string;
  resourceId: string | null;
  summary: string;
  actor: {
    id: string;
    email: string;
    displayName: string | null;
  } | null;
  metadata: Record<string, unknown>;
  createdAt: string;
}

export interface CommunityModerationReport {
  id: string;
  reporterId: string;
  targetType: CommunityReportTargetType;
  targetId: string;
  targetUserId: string | null;
  reason: string;
  details: string | null;
  status: CommunityReportStatus;
  reviewedById: string | null;
  reviewedAt: string | null;
  resolutionNote: string | null;
  createdAt: string;
  updatedAt: string;
  reporter: ActorSummary;
  reviewer: ActorSummary | null;
  targetUser:
    | {
        id: string;
        email: string;
        username: string | null;
        displayName: string | null;
      }
    | null;
}

export interface CommunityModerationReportsResponse {
  data: CommunityModerationReport[];
  total: number;
  limit: number;
  offset: number;
}

export interface CommunityModerationUserState {
  id: string;
  email: string;
  username: string | null;
  displayName: string | null;
  communityWarnCount: number;
  communityLastWarnedAt: string | null;
  communityMutedUntil: string | null;
  communitySuspendedUntil: string | null;
  communityPostingRestrictedUntil: string | null;
  communityCommentingRestrictedUntil: string | null;
  roles: string[];
}

export interface Tag {
  id: string;
  name: string;
  slug: string;
  createdAt: string;
  updatedAt: string;
}
