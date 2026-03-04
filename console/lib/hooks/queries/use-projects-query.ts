import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { clientApi, type AdminProject, type ProjectStatus } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for listing projects with filters
 */
export function useProjectsQuery(params?: {
  q?: string;
  status?: ProjectStatus;
  limit?: number;
  offset?: number;
}) {
  return useQuery({
    queryKey: queryKeys.projects.list(params ?? {}),
    queryFn: () => clientApi.listAdminProjects(params),
    ...queryOptions.standard,
  });
}

/**
 * Mutation hook for moderating project status
 */
export function useModerateProjectMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      projectId,
      status,
      reason,
    }: {
      projectId: string;
      status: ProjectStatus;
      reason: string;
    }) => clientApi.moderateProjectStatus(projectId, { status, reason }),

    onSuccess: (updatedProject) => {
      // Update the specific project in cache if it exists
      queryClient.setQueryData<AdminProject>(
        queryKeys.projects.detail(updatedProject.id),
        updatedProject
      );

      // Invalidate project lists to refetch with updated data
      queryClient.invalidateQueries({ queryKey: queryKeys.projects.lists() });
    },
  });
}
