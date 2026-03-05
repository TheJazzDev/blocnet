import { create } from "zustand";
import { devtools } from "zustand/middleware";
import type {
  AdminCommunityPost,
  AdminCommunityComment,
  ContentStatus,
  CommunityTopic,
} from "@/lib/api";

interface CommunityState {
  // Posts
  posts: AdminCommunityPost[];
  postsLoading: boolean;
  postsError: string | null;
  postSearchQuery: string;
  postStatusFilter: ContentStatus | "all" | null;
  postTopicFilter: CommunityTopic | "all" | null;

  // Comments
  comments: AdminCommunityComment[];
  commentsLoading: boolean;
  commentsError: string | null;
  commentSearchQuery: string;
  commentStatusFilter: ContentStatus | "all" | null;
  commentPostIdFilter: string | null;

  // Post Actions
  setPosts: (posts: AdminCommunityPost[]) => void;
  setPostsLoading: (loading: boolean) => void;
  setPostsError: (error: string | null) => void;
  setPostSearchQuery: (query: string) => void;
  setPostStatusFilter: (status: ContentStatus | "all" | null) => void;
  setPostTopicFilter: (topic: CommunityTopic | "all" | null) => void;
  clearPostFilters: () => void;

  // Comment Actions
  setComments: (comments: AdminCommunityComment[]) => void;
  setCommentsLoading: (loading: boolean) => void;
  setCommentsError: (error: string | null) => void;
  setCommentSearchQuery: (query: string) => void;
  setCommentStatusFilter: (status: ContentStatus | "all" | null) => void;
  setCommentPostIdFilter: (postId: string | null) => void;
  clearCommentFilters: () => void;

  reset: () => void;

  // Computed
  hasPostFilters: () => boolean;
  hasCommentFilters: () => boolean;
}

const initialState = {
  posts: [],
  postsLoading: false,
  postsError: null,
  postSearchQuery: "",
  postStatusFilter: null,
  postTopicFilter: null,
  comments: [],
  commentsLoading: false,
  commentsError: null,
  commentSearchQuery: "",
  commentStatusFilter: null,
  commentPostIdFilter: null,
};

export const useCommunityStore = create<CommunityState>()(
  devtools(
    (set, get) => ({
      ...initialState,

      // Post Actions
      setPosts: (posts) => set({ posts, postsError: null, postsLoading: false }),

      setPostsLoading: (postsLoading) => set({ postsLoading }),

      setPostsError: (postsError) => set({ postsError, postsLoading: false }),

      setPostSearchQuery: (postSearchQuery) => set({ postSearchQuery }),

      setPostStatusFilter: (postStatusFilter) => set({ postStatusFilter }),

      setPostTopicFilter: (postTopicFilter) => set({ postTopicFilter }),

      clearPostFilters: () =>
        set({
          postSearchQuery: "",
          postStatusFilter: null,
          postTopicFilter: null,
        }),

      // Comment Actions
      setComments: (comments) =>
        set({ comments, commentsError: null, commentsLoading: false }),

      setCommentsLoading: (commentsLoading) => set({ commentsLoading }),

      setCommentsError: (commentsError) =>
        set({ commentsError, commentsLoading: false }),

      setCommentSearchQuery: (commentSearchQuery) => set({ commentSearchQuery }),

      setCommentStatusFilter: (commentStatusFilter) =>
        set({ commentStatusFilter }),

      setCommentPostIdFilter: (commentPostIdFilter) =>
        set({ commentPostIdFilter }),

      clearCommentFilters: () =>
        set({
          commentSearchQuery: "",
          commentStatusFilter: null,
          commentPostIdFilter: null,
        }),

      reset: () => set(initialState),

      // Computed
      hasPostFilters: () => {
        const { postSearchQuery, postStatusFilter, postTopicFilter } = get();
        return (
          postSearchQuery !== "" ||
          (postStatusFilter !== null && postStatusFilter !== "all") ||
          (postTopicFilter !== null && postTopicFilter !== "all")
        );
      },

      hasCommentFilters: () => {
        const { commentSearchQuery, commentStatusFilter, commentPostIdFilter } =
          get();
        return (
          commentSearchQuery !== "" ||
          (commentStatusFilter !== null && commentStatusFilter !== "all") ||
          commentPostIdFilter !== null
        );
      },
    }),
    { name: "community-store" }
  )
);
