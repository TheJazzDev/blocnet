"use client";

import { useMemo } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { useAdminSession } from "@/components/admin-shell";
import { canManageGamification } from "@/lib/rbac";
import { groupLevelsByTier } from "@/components/shared/levels";
import {
  getAllLevels,
  updateLevel,
  uploadLevelIcon,
  type UpdateLevelInput,
  type UserLevel,
} from "@/lib/api/levels";
import { useLevelsStore } from "@/lib/stores";

export const LEVELS_QUERY_KEY = ["levels"] as const;

const ALLOWED_ICON_TYPES = new Set(["image/svg+xml", "image/png", "image/jpeg", "image/webp"]);
const MAX_ICON_BYTES = 3 * 1024 * 1024;

/** Returns an error message when the file is not an acceptable badge icon. */
export function validateLevelIconFile(file: File): string | null {
  if (!ALLOWED_ICON_TYPES.has(file.type)) {
    return "Use SVG, PNG, JPEG, or WEBP for level badges.";
  }
  if (file.size > MAX_ICON_BYTES) {
    return "Badge icon must be 3MB or smaller.";
  }
  return null;
}

function errorMessage(error: unknown, fallback: string) {
  return error instanceof Error ? error.message : fallback;
}

export function useLevelsPage() {
  const session = useAdminSession();
  const queryClient = useQueryClient();
  const { editingId, editForm, cancelEdit, patchEditForm } = useLevelsStore();

  const canMutate = canManageGamification(session.effectiveRoles);

  const { data: levels = [], isLoading, error } = useQuery({
    queryKey: LEVELS_QUERY_KEY,
    queryFn: getAllLevels,
  });

  const groups = useMemo(() => groupLevelsByTier(levels), [levels]);

  const replaceLevelInCache = (updated: UserLevel) => {
    queryClient.setQueryData<UserLevel[]>(LEVELS_QUERY_KEY, (current) =>
      current ? current.map((l) => (l.id === updated.id ? updated : l)) : current,
    );
  };

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateLevelInput }) => updateLevel(id, data),
    onSuccess: (updated) => {
      replaceLevelInCache(updated);
      queryClient.invalidateQueries({ queryKey: LEVELS_QUERY_KEY });
      toast.success("Level updated successfully");
      cancelEdit();
    },
    onError: (err: unknown) => toast.error(errorMessage(err, "Failed to update level")),
  });

  const uploadIconMutation = useMutation({
    mutationFn: ({ id, file }: { id: string; file: File }) => uploadLevelIcon(id, file),
    onSuccess: (updated) => {
      // Swap the cached level first so the new badge shows immediately.
      replaceLevelInCache(updated);
      queryClient.invalidateQueries({ queryKey: LEVELS_QUERY_KEY });
      if (useLevelsStore.getState().editingId === updated.id) {
        patchEditForm({ iconUrl: updated.iconUrl });
      }
      toast.success("Level badge icon uploaded");
    },
    onError: (err: unknown) => toast.error(errorMessage(err, "Failed to upload level icon")),
  });

  const saveEdit = (levelId: string) => {
    if (!editForm) return;
    updateMutation.mutate({ id: levelId, data: editForm });
  };

  const uploadIcon = (levelId: string, file: File) => {
    const problem = validateLevelIconFile(file);
    if (problem) {
      toast.error(problem);
      return;
    }
    uploadIconMutation.mutate({ id: levelId, file });
  };

  return {
    levels,
    groups,
    isLoading,
    error,
    canMutate,
    editingId,
    isSaving: updateMutation.isPending,
    uploadingLevelId: uploadIconMutation.isPending
      ? (uploadIconMutation.variables?.id ?? null)
      : null,
    saveEdit,
    uploadIcon,
  };
}
