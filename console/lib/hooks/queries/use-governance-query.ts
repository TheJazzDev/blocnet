import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { clientApi, type AdminApplication, type ProjectProposal, type AuditLog, type OpsEvent, type OpsEventSource, type OpsEventProvider, type OpsEventStatus } from "@/lib/api-client";
import { queryKeys } from "./query-keys";
import { queryOptions } from "./query-options";

/**
 * Query hook for listing admin applications
 */
export function useAdminApplicationsQuery() {
  return useQuery({
    queryKey: queryKeys.governance.applications(),
    queryFn: () => clientApi.listAdminApplications(),
    ...queryOptions.standard,
  });
}

/**
 * Mutation hook for reviewing admin application
 */
export function useReviewAdminApplicationMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      status,
      note,
    }: {
      id: string;
      status: "approved" | "rejected";
      note?: string;
    }) => clientApi.reviewAdminApplication(id, { status, note }),

    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.governance.applications() });
    },
  });
}

/**
 * Query hook for listing project proposals
 */
export function useProjectProposalsQuery() {
  return useQuery({
    queryKey: queryKeys.governance.proposals(),
    queryFn: () => clientApi.listProjectProposals(),
    ...queryOptions.standard,
  });
}

/**
 * Mutation hook for reviewing project proposal
 */
export function useReviewProjectProposalMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      id,
      status,
      note,
    }: {
      id: string;
      status: "approved" | "rejected";
      note?: string;
    }) => clientApi.reviewProjectProposal(id, { status, note }),

    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.governance.proposals() });
    },
  });
}

/**
 * Query hook for listing audit log
 */
export function useAuditLogQuery(params?: { limit?: number; offset?: number }) {
  return useQuery({
    queryKey: queryKeys.auditLog.list(params ?? {}),
    queryFn: () => clientApi.listAuditLog(params?.limit, params?.offset),
    ...queryOptions.standard,
  });
}

/**
 * Query hook for listing ops events
 */
export function useOpsEventsQuery(
  params?: {
    q?: string;
    source?: OpsEventSource;
    provider?: OpsEventProvider;
    status?: OpsEventStatus;
    from?: string;
    to?: string;
    limit?: number;
    offset?: number;
  },
  options?: { refetchInterval?: number | false; enabled?: boolean }
) {
  return useQuery({
    queryKey: [...queryKeys.governance.opsEvents(), params ?? {}],
    queryFn: () => clientApi.listOpsEvents(params),
    ...queryOptions.standard,
    refetchInterval: options?.refetchInterval,
    enabled: options?.enabled,
  });
}
