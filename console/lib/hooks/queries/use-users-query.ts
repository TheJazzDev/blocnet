import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { clientApi, type AdminUsersResponse, type AdminUserDetail, type AdminUserStatus } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for listing users with pagination and filters
 */
export function useUsersQuery(params?: {
  limit?: number;
  offset?: number;
  role?: string;
  q?: string;
  status?: AdminUserStatus | "all";
}) {
  return useQuery({
    queryKey: queryKeys.users.list(params ?? {}),
    queryFn: () => clientApi.listUsers(params),
    ...queryOptions.standard,
  });
}

/**
 * Query hook for fetching a single user's details
 */
export function useUserQuery(userId: string, options?: { enabled?: boolean }) {
  return useQuery({
    queryKey: queryKeys.users.detail(userId),
    queryFn: () => clientApi.getUser(userId),
    ...queryOptions.standard,
    enabled: options?.enabled ?? true,
  });
}

/**
 * Mutation hook for updating a user
 */
export function useUpdateUserMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      userId,
      data,
    }: {
      userId: string;
      data: Partial<{
        displayName: string | null;
        username: string | null;
        avatarUrl: string | null;
        bio: string | null;
      }>;
    }) => clientApi.updateUser(userId, data),
    onSuccess: (updatedUser, variables) => {
      // Update the user detail cache
      queryClient.setQueryData<AdminUserDetail>(
        queryKeys.users.detail(variables.userId),
        updatedUser
      );

      // Invalidate user lists to refetch with updated data
      queryClient.invalidateQueries({ queryKey: queryKeys.users.lists() });
    },
  });
}

/**
 * Mutation hook for deactivating a user
 */
export function useDeleteUserMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ userId, reason }: { userId: string; reason?: string }) =>
      clientApi.deleteUser(userId, { reason }),
    onSuccess: (_, variables) => {
      // Invalidate both detail and list queries
      queryClient.invalidateQueries({ queryKey: queryKeys.users.detail(variables.userId) });
      queryClient.invalidateQueries({ queryKey: queryKeys.users.lists() });
    },
  });
}

/**
 * Mutation hook for reactivating a user
 */
export function useReactivateUserMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ userId, reason }: { userId: string; reason?: string }) =>
      clientApi.reactivateUser(userId, { reason }),
    onSuccess: (_, variables) => {
      // Invalidate both detail and list queries
      queryClient.invalidateQueries({ queryKey: queryKeys.users.detail(variables.userId) });
      queryClient.invalidateQueries({ queryKey: queryKeys.users.lists() });
    },
  });
}

/**
 * Mutation hook for hard deleting a user (permanent)
 */
export function useHardDeleteUserMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ userId, reason }: { userId: string; reason?: string }) =>
      clientApi.hardDeleteUser(userId, { reason }),
    onSuccess: (_, variables) => {
      // Remove from cache and invalidate lists
      queryClient.removeQueries({ queryKey: queryKeys.users.detail(variables.userId) });
      queryClient.invalidateQueries({ queryKey: queryKeys.users.lists() });
    },
  });
}
