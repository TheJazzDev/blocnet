import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { clientApi } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for a project's hunter invites (all statuses, newest first).
 * Accepted invites double as the "current hunters" list: the API has no
 * separate read for direct assignments yet.
 */
export function useProjectInvitesQuery(projectId: string | null) {
  return useQuery({
    queryKey: queryKeys.projects.invites(projectId ?? ""),
    queryFn: () => clientApi.listProjectInvites(projectId as string, { limit: 100 }),
    ...queryOptions.standard,
    enabled: Boolean(projectId),
    // A 403 (admin who does not own the project) will not change on retry;
    // fail fast so the sheet can show the reason instead of a spinner.
    retry: false,
  });
}

type HunterActionInput = {
  projectId: string;
  hunterId: string;
  note?: string;
};

function useInvalidateProjectHunters() {
  const queryClient = useQueryClient();
  return (projectId: string) => {
    queryClient.invalidateQueries({ queryKey: queryKeys.projects.invites(projectId) });
    queryClient.invalidateQueries({ queryKey: queryKeys.projects.lists() });
  };
}

/**
 * Mutation hook that assigns a hunter to a project immediately (no acceptance step).
 */
export function useAssignHunterMutation() {
  const invalidate = useInvalidateProjectHunters();

  return useMutation({
    mutationFn: ({ projectId, hunterId, note }: HunterActionInput) =>
      clientApi.assignProjectHunter(projectId, hunterId, note ? { note } : {}),
    onSuccess: (_result, variables) => invalidate(variables.projectId),
  });
}

/**
 * Mutation hook that invites a hunter; the hunter accepts or declines in the app.
 */
export function useInviteHunterMutation() {
  const invalidate = useInvalidateProjectHunters();

  return useMutation({
    mutationFn: ({ projectId, hunterId, note }: HunterActionInput) =>
      clientApi.inviteProjectHunter(projectId, hunterId, note ? { note } : {}),
    onSuccess: (_result, variables) => invalidate(variables.projectId),
  });
}
