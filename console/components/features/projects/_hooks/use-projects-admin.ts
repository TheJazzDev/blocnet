"use client";

import { useMemo, useState } from "react";
import { type AdminProject, type ProjectStatus } from "@/lib/api-client";
import { useProjectsQuery, useModerateProjectMutation } from "@/lib/hooks/queries";
import { useDebounce } from "@/lib/hooks";
import { isModeratorOnly } from "@/lib/rbac";
import type { StatusFilter } from "../_lib/projects-admin";

export function useProjectsAdmin(effectiveRoles: string[]) {
  const moderatorOnly = isModeratorOnly(effectiveRoles);

  const [searchInput, setSearchInput] = useState("");
  const [status, setStatus] = useState<StatusFilter>("all");
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedProject, setSelectedProject] = useState<AdminProject | null>(null);
  const [targetStatus, setTargetStatus] = useState<ProjectStatus>("active");

  // Debounce search input
  const q = useDebounce(searchInput.trim(), 300);

  // TanStack Query hook
  const { data: projects = [], isLoading, error } = useProjectsQuery({
    q: q || undefined,
    status: status === "all" ? undefined : (status as ProjectStatus),
    limit,
    offset,
  });

  // Mutation hook
  const moderateMutation = useModerateProjectMutation();

  function openModeration(project: AdminProject, nextStatus: ProjectStatus) {
    setSelectedProject(project);
    setTargetStatus(nextStatus);
    setDialogOpen(true);
  }

  async function submitModeration(nextStatus: ProjectStatus, reason: string) {
    if (!selectedProject) return;

    await moderateMutation.mutateAsync({
      projectId: selectedProject.id,
      status: nextStatus,
      reason,
    });
  }

  const statusOptions = useMemo(
    () =>
      moderatorOnly
        ? [
            { value: "active", label: "Active" },
            { value: "hidden", label: "Hidden" },
            { value: "archived", label: "Archived" },
          ]
        : [
            { value: "active", label: "Active" },
            { value: "paused", label: "Paused" },
            { value: "hidden", label: "Hidden" },
            { value: "archived", label: "Archived" },
          ],
    [moderatorOnly],
  );

  return {
    moderatorOnly,
    projects,
    loading: isLoading,
    error: error ? (error instanceof Error ? error.message : "Failed to load projects") : null,
    searchInput,
    setSearchInput,
    status,
    setStatus,
    limit,
    setLimit,
    offset,
    setOffset,
    dialogOpen,
    setDialogOpen,
    selectedProject,
    targetStatus,
    openModeration,
    submitModeration,
    statusOptions,
  };
}
