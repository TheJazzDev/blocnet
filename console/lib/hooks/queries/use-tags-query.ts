import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { clientApi, type Tag } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for listing primary tags
 */
export function usePrimaryTagsQuery() {
  return useQuery({
    queryKey: queryKeys.tags.primary(),
    queryFn: () => clientApi.listPrimaryTags(),
    ...queryOptions.static, // Tags change rarely
  });
}

/**
 * Query hook for listing secondary tags
 */
export function useSecondaryTagsQuery() {
  return useQuery({
    queryKey: queryKeys.tags.secondary(),
    queryFn: () => clientApi.listSecondaryTags(),
    ...queryOptions.static, // Tags change rarely
  });
}

/**
 * Mutation hook for creating primary tag
 */
export function useCreatePrimaryTagMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { name: string }) => clientApi.createPrimaryTag(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.tags.primary() });
    },
  });
}

/**
 * Mutation hook for creating secondary tag
 */
export function useCreateSecondaryTagMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: { name: string }) => clientApi.createSecondaryTag(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.tags.secondary() });
    },
  });
}

/**
 * Mutation hook for updating primary tag
 */
export function useUpdatePrimaryTagMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: { name: string } }) =>
      clientApi.updatePrimaryTag(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.tags.primary() });
    },
  });
}

/**
 * Mutation hook for updating secondary tag
 */
export function useUpdateSecondaryTagMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: { name: string } }) =>
      clientApi.updateSecondaryTag(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.tags.secondary() });
    },
  });
}
