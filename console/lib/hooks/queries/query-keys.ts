/**
 * Query key factory for TanStack Query
 *
 * Centralized query keys prevent typos and make cache invalidation easier.
 *
 * @example
 * // In a hook
 * useQuery({ queryKey: queryKeys.users.list({ role: 'admin' }) })
 *
 * // Invalidate all user queries
 * queryClient.invalidateQueries({ queryKey: queryKeys.users.all })
 *
 * // Invalidate specific user
 * queryClient.invalidateQueries({ queryKey: queryKeys.users.detail(userId) })
 */

export const queryKeys = {
  // Users
  users: {
    all: ['users'] as const,
    lists: () => [...queryKeys.users.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.users.lists(), filters] as const,
    details: () => [...queryKeys.users.all, 'detail'] as const,
    detail: (id: string) => [...queryKeys.users.details(), id] as const,
  },

  // Stats
  stats: {
    all: ['stats'] as const,
    dashboard: () => [...queryKeys.stats.all, 'dashboard'] as const,
    health: () => [...queryKeys.stats.all, 'health'] as const,
  },

  // Roles
  roles: {
    all: ['roles'] as const,
    matrix: () => [...queryKeys.roles.all, 'matrix'] as const,
  },

  // Projects
  projects: {
    all: ['projects'] as const,
    lists: () => [...queryKeys.projects.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.projects.lists(), filters] as const,
    details: () => [...queryKeys.projects.all, 'detail'] as const,
    detail: (id: string) => [...queryKeys.projects.details(), id] as const,
  },

  // Updates
  updates: {
    all: ['updates'] as const,
    lists: () => [...queryKeys.updates.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.updates.lists(), filters] as const,
    details: () => [...queryKeys.updates.all, 'detail'] as const,
    detail: (id: string) => [...queryKeys.updates.details(), id] as const,
  },

  // Comments
  comments: {
    all: ['comments'] as const,
    lists: () => [...queryKeys.comments.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.comments.lists(), filters] as const,
  },

  // Badges
  badges: {
    all: ['badges'] as const,
    lists: () => [...queryKeys.badges.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.badges.lists(), filters] as const,
  },

  // Quests
  quests: {
    all: ['quests'] as const,
    lists: () => [...queryKeys.quests.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.quests.lists(), filters] as const,
    details: () => [...queryKeys.quests.all, 'detail'] as const,
    detail: (id: string) => [...queryKeys.quests.details(), id] as const,
  },

  // Notifications
  notifications: {
    all: ['notifications'] as const,
    lists: () => [...queryKeys.notifications.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.notifications.lists(), filters] as const,
  },

  // Wallet
  wallet: {
    all: ['wallet'] as const,
    users: (filters: Record<string, unknown>) => [...queryKeys.wallet.all, 'users', filters] as const,
    withdrawals: (filters: Record<string, unknown>) => [...queryKeys.wallet.all, 'withdrawals', filters] as const,
    kyc: (filters: Record<string, unknown>) => [...queryKeys.wallet.all, 'kyc', filters] as const,
    settings: () => [...queryKeys.wallet.all, 'settings'] as const,
  },

  // Audit Log
  auditLog: {
    all: ['audit-log'] as const,
    lists: () => [...queryKeys.auditLog.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.auditLog.lists(), filters] as const,
  },

  // Mining
  mining: {
    all: ['mining'] as const,
    leaderboard: (filters: Record<string, unknown>) => [...queryKeys.mining.all, 'leaderboard', filters] as const,
  },

  // Tags
  tags: {
    all: ['tags'] as const,
    primary: () => [...queryKeys.tags.all, 'primary'] as const,
    secondary: () => [...queryKeys.tags.all, 'secondary'] as const,
    lists: () => [...queryKeys.tags.all, 'list'] as const,
    list: (filters: Record<string, unknown>) => [...queryKeys.tags.lists(), filters] as const,
  },

  // Community
  community: {
    all: ['community'] as const,
    posts: {
      all: ['community', 'posts'] as const,
      lists: () => [...queryKeys.community.posts.all, 'list'] as const,
    },
    comments: {
      all: ['community', 'comments'] as const,
      lists: () => [...queryKeys.community.comments.all, 'list'] as const,
    },
    moderation: {
      all: ['community', 'moderation'] as const,
      reports: (filters: Record<string, unknown>) =>
        [...queryKeys.community.moderation.all, 'reports', filters] as const,
      userState: (userId: string) =>
        [...queryKeys.community.moderation.all, 'user-state', userId] as const,
    },
  },

  // Governance
  governance: {
    all: ['governance'] as const,
    applications: () => [...queryKeys.governance.all, 'applications'] as const,
    proposals: () => [...queryKeys.governance.all, 'proposals'] as const,
    opsEvents: () => [...queryKeys.governance.all, 'ops-events'] as const,
  },

  // Tips
  tips: {
    all: ['tips'] as const,
    transactions: (filters: Record<string, unknown>) => [...queryKeys.tips.all, 'transactions', filters] as const,
    settings: () => [...queryKeys.tips.all, 'settings'] as const,
  },
} as const;
