"use client";

import { useState, type ChangeEvent } from "react";
import { Edit, Save, X } from "lucide-react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import {
  getAllLevels,
  uploadLevelIcon,
  updateLevel,
  type UpdateLevelInput,
  type UserLevel,
} from "@/lib/api/levels";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";

export default function LevelsPageClient() {
  const session = useAdminSession();
  const queryClient = useQueryClient();
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<Partial<UpdateLevelInput>>({});

  const canMutate =
    session.effectiveRoles.includes("owner") ||
    session.effectiveRoles.includes("admin");

  const { data: levels = [], isLoading, error } = useQuery({
    queryKey: ["levels"],
    queryFn: getAllLevels,
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<UpdateLevelInput> }) =>
      updateLevel(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["levels"] });
      toast.success("Level updated successfully");
      setEditingId(null);
      setEditForm({});
    },
    onError: (error: unknown) => {
      const message =
        error instanceof Error ? error.message : "Failed to update level";
      toast.error(message);
    },
  });

  const uploadIconMutation = useMutation({
    mutationFn: ({ id, file }: { id: string; file: File }) =>
      uploadLevelIcon(id, file),
    onSuccess: (updatedLevel) => {
      queryClient.invalidateQueries({ queryKey: ["levels"] });
      if (editingId === updatedLevel.id) {
        setEditForm((prev) => ({ ...prev, iconUrl: updatedLevel.iconUrl }));
      }
      toast.success("Level badge icon uploaded");
    },
    onError: (error: unknown) => {
      const message =
        error instanceof Error
          ? error.message
          : "Failed to upload level icon";
      toast.error(message);
    },
  });

  const startEdit = (level: UserLevel) => {
    setEditingId(level.id);
    setEditForm({
      name: level.name,
      description: level.description,
      requiredBnp: level.requiredBnp,
      requiredComments: level.requiredComments,
      requiredDaysActive: level.requiredDaysActive,
      requiredQuests: level.requiredQuests,
      requiredUpdates: level.requiredUpdates,
      requiredProjects: level.requiredProjects,
      color: level.color ?? "",
      iconUrl: level.iconUrl,
    });
  };

  const cancelEdit = () => {
    setEditingId(null);
    setEditForm({});
  };

  const saveEdit = async (levelId: string) => {
    updateMutation.mutate({ id: levelId, data: editForm });
  };

  const handleIconUpload = (
    levelId: string,
    event: ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0];
    event.target.value = "";

    if (!file) {
      return;
    }

    const allowedMimeTypes = new Set([
      "image/svg+xml",
      "image/png",
      "image/jpeg",
      "image/webp",
    ]);

    if (!allowedMimeTypes.has(file.type)) {
      toast.error("Use SVG, PNG, JPEG, or WEBP for level badges.");
      return;
    }

    if (file.size > 3 * 1024 * 1024) {
      toast.error("Badge icon must be 3MB or smaller.");
      return;
    }

    uploadIconMutation.mutate({ id: levelId, file });
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-8">
        <p className="text-sm text-muted-foreground">Loading levels...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center py-8">
        <p className="text-sm text-red-500">Error loading levels</p>
      </div>
    );
  }

  return (
    <div className="space-y-4 md:space-y-6">
      <PageHeader
        title="User Levels"
        description="Manage the user level system and progression thresholds"
      />

      <div className="grid gap-4 md:gap-6">
        {levels.map((level) => {
          const isEditing = editingId === level.id;

          return (
            <Card key={level.id}>
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex min-w-0 flex-1 items-start gap-3 sm:gap-4">
                    <div className="relative h-10 w-10 overflow-hidden rounded-lg border border-border/70 bg-muted/30 sm:h-12 sm:w-12">
                      <img
                        src={
                          isEditing
                            ? editForm.iconUrl || level.iconUrl
                            : level.iconUrl
                        }
                        alt={`Level ${level.level} badge`}
                        className="h-full w-full object-cover"
                      />
                    </div>
                    <div className="min-w-0 flex-1">
                      {isEditing ? (
                        <Input
                          value={editForm.name}
                          onChange={(e) =>
                            setEditForm({ ...editForm, name: e.target.value })
                          }
                          className="mb-2 text-base font-semibold sm:text-lg"
                        />
                      ) : (
                        <CardTitle className="text-base sm:text-lg">
                          Level {level.level} • {level.name}
                        </CardTitle>
                      )}
                      {isEditing ? (
                        <Textarea
                          value={editForm.description}
                          onChange={(e) =>
                            setEditForm({
                              ...editForm,
                              description: e.target.value,
                            })
                          }
                          rows={3}
                          className="min-h-[88px] w-full resize-y text-xs sm:text-sm"
                        />
                      ) : (
                        <CardDescription className="text-xs sm:text-sm">
                          {level.description}
                        </CardDescription>
                      )}
                    </div>
                  </div>
                  {canMutate && (
                    <div className="ml-4 flex shrink-0 gap-1 pt-1 sm:gap-2">
                      {isEditing ? (
                        <>
                          <Button
                            size="sm"
                            onClick={() => saveEdit(level.id)}
                            disabled={updateMutation.isPending}
                            className="h-7 sm:h-8 px-2 sm:px-3"
                          >
                            <Save className="h-3 w-3 sm:h-4 sm:w-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={cancelEdit}
                            disabled={updateMutation.isPending}
                            className="h-7 sm:h-8 px-2 sm:px-3"
                          >
                            <X className="h-3 w-3 sm:h-4 sm:w-4" />
                          </Button>
                        </>
                      ) : (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => startEdit(level)}
                          className="h-7 sm:h-8 px-2 sm:px-3"
                        >
                          <Edit className="h-3 w-3 sm:h-4 sm:w-4" />
                        </Button>
                      )}
                    </div>
                  )}
                </div>
              </CardHeader>
              <CardContent>
                <div className="grid gap-3 sm:gap-4 md:grid-cols-2 lg:grid-cols-3">
                  {/* BNP */}
                  <div>
                    <Label className="text-xs sm:text-sm text-muted-foreground">
                      Required BNP
                    </Label>
                    {isEditing ? (
                      <Input
                        type="text"
                        value={editForm.requiredBnp}
                        onChange={(e) =>
                          setEditForm({
                            ...editForm,
                            requiredBnp: e.target.value,
                          })
                        }
                        className="mt-1"
                      />
                    ) : (
                      <p className="text-base sm:text-lg font-semibold">
                        {parseInt(level.requiredBnp).toLocaleString()}
                      </p>
                    )}
                  </div>

                  {/* Comments */}
                  <div>
                    <Label className="text-xs sm:text-sm text-muted-foreground">
                      Required Comments
                    </Label>
                    {isEditing ? (
                      <Input
                        type="number"
                        value={editForm.requiredComments}
                        onChange={(e) =>
                          setEditForm({
                            ...editForm,
                            requiredComments: parseInt(e.target.value) || 0,
                          })
                        }
                        className="mt-1"
                      />
                    ) : (
                      <p className="text-base sm:text-lg font-semibold">
                        {level.requiredComments.toLocaleString()}
                      </p>
                    )}
                  </div>

                  {/* Days Active */}
                  <div>
                    <Label className="text-xs sm:text-sm text-muted-foreground">
                      Required Days Active
                    </Label>
                    {isEditing ? (
                      <Input
                        type="number"
                        value={editForm.requiredDaysActive}
                        onChange={(e) =>
                          setEditForm({
                            ...editForm,
                            requiredDaysActive: parseInt(e.target.value) || 0,
                          })
                        }
                        className="mt-1"
                      />
                    ) : (
                      <p className="text-base sm:text-lg font-semibold">
                        {level.requiredDaysActive} days
                      </p>
                    )}
                  </div>

                  {/* Quests */}
                  <div>
                    <Label className="text-xs sm:text-sm text-muted-foreground">
                      Required Quests
                    </Label>
                    {isEditing ? (
                      <Input
                        type="number"
                        value={editForm.requiredQuests}
                        onChange={(e) =>
                          setEditForm({
                            ...editForm,
                            requiredQuests: parseInt(e.target.value) || 0,
                          })
                        }
                        className="mt-1"
                      />
                    ) : (
                      <p className="text-base sm:text-lg font-semibold">
                        {level.requiredQuests}
                      </p>
                    )}
                  </div>

                  {/* Updates */}
                  <div>
                    <Label className="text-xs sm:text-sm text-muted-foreground">
                      Required Updates
                    </Label>
                    {isEditing ? (
                      <Input
                        type="number"
                        value={editForm.requiredUpdates}
                        onChange={(e) =>
                          setEditForm({
                            ...editForm,
                            requiredUpdates: parseInt(e.target.value) || 0,
                          })
                        }
                        className="mt-1"
                      />
                    ) : (
                      <p className="text-base sm:text-lg font-semibold">
                        {level.requiredUpdates}
                      </p>
                    )}
                  </div>

                  {/* Projects */}
                  <div>
                    <Label className="text-xs sm:text-sm text-muted-foreground">
                      Required Projects
                    </Label>
                    {isEditing ? (
                      <Input
                        type="number"
                        value={editForm.requiredProjects}
                        onChange={(e) =>
                          setEditForm({
                            ...editForm,
                            requiredProjects: parseInt(e.target.value) || 0,
                          })
                        }
                        className="mt-1"
                      />
                    ) : (
                      <p className="text-base sm:text-lg font-semibold">
                        {level.requiredProjects}
                      </p>
                    )}
                  </div>

                  {/* Color */}
                  {isEditing && (
                    <div>
                      <Label className="text-xs sm:text-sm text-muted-foreground">
                        Color (Hex)
                      </Label>
                      <Input
                        type="text"
                        value={editForm.color}
                        onChange={(e) =>
                          setEditForm({ ...editForm, color: e.target.value })
                        }
                        placeholder="#6B7280"
                        className="mt-1"
                      />
                    </div>
                  )}

                  {/* Icon URL */}
                  {isEditing && (
                    <div className="md:col-span-2 lg:col-span-3">
                      <Label className="text-xs sm:text-sm text-muted-foreground">
                        Level Icon URL/Path
                      </Label>
                      <Input
                        type="text"
                        value={editForm.iconUrl}
                        onChange={(e) =>
                          setEditForm({ ...editForm, iconUrl: e.target.value })
                        }
                        placeholder="/images/levels/level-3.svg or https://..."
                        className="mt-1"
                      />
                      <p className="mt-1 text-[11px] text-muted-foreground">
                        Recommended: SVG for crisp rendering.
                      </p>
                    </div>
                  )}

                  {isEditing && (
                    <div className="md:col-span-2 lg:col-span-3">
                      <Label className="text-xs sm:text-sm text-muted-foreground">
                        Upload Badge Icon
                      </Label>
                      <Input
                        type="file"
                        accept="image/svg+xml,image/png,image/jpeg,image/webp"
                        onChange={(event) => handleIconUpload(level.id, event)}
                        disabled={uploadIconMutation.isPending}
                        className="mt-1 max-w-md"
                      />
                      {uploadIconMutation.isPending &&
                        uploadIconMutation.variables?.id === level.id && (
                          <p className="mt-1 text-[11px] text-muted-foreground">
                            Uploading icon...
                          </p>
                        )}
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
