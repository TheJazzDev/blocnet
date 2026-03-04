"use client";

import { FormEvent, useMemo } from "react";
import { Plus } from "lucide-react";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import { apiFetch } from "@/lib/api-client";
import { useBadges } from "@/lib/hooks";
import { BadgeCreateDialog } from "./BadgeCreateDialog";
import { BadgeEditDialog } from "./BadgeEditDialog";
import { BadgeGrantDialog } from "./BadgeGrantDialog";
import { BadgesTable } from "./BadgesTable";
import { groupBadgesByCategory } from "./badge-models";

export default function BadgesPage() {
  const session = useAdminSession();
  const canMutate =
    session.effectiveRoles.includes("owner") ||
    session.effectiveRoles.includes("admin");

  const {
    // Data
    badges,
    isLoading,
    error,
    loadBadges,

    // Dialogs
    createOpen,
    editOpen,
    grantOpen,
    selectedBadge,
    openCreate,
    closeCreate,
    openEdit,
    closeEdit,
    openGrant,
    closeGrant,

    // Create form
    newName,
    newDescription,
    newImageUrl,
    newCategory,
    newRarity,
    newPoints,
    creating,
    setNewName,
    setNewDescription,
    setNewImageUrl,
    setNewCategory,
    setNewRarity,
    setNewPoints,
    setCreating,
    resetCreateForm,

    // Edit form
    editName,
    editDescription,
    editImageUrl,
    editCategory,
    editRarity,
    editPoints,
    editActive,
    editSaving,
    setEditName,
    setEditDescription,
    setEditImageUrl,
    setEditCategory,
    setEditRarity,
    setEditPoints,
    setEditActive,
    setEditSaving,

    // Grant
    grantUserIdentifier,
    grantMatches,
    grantSearchLoading,
    grantSelected,
    granting,
    grantFeedback,
    setGrantUserIdentifier,
    setGrantSelected,
    setGranting,
    setGrantFeedback,
  } = useBadges();

  const groupedBadges = useMemo(
    () => groupBadgesByCategory(badges),
    [badges]
  );

  async function createBadge(e: FormEvent) {
    e.preventDefault();
    if (!canMutate) return;

    const name = newName.trim();
    if (!name) return;

    setCreating(true);
    try {
      await apiFetch("/admin/badges", {
        method: "POST",
        body: JSON.stringify({
          name,
          description: newDescription.trim(),
          imageUrl: newImageUrl.trim(),
          category: newCategory,
          rarity: newRarity,
          pointsRequirement: parseInt(newPoints) || 0,
        }),
      });

      resetCreateForm();
      closeCreate();
      await loadBadges();
    } finally {
      setCreating(false);
    }
  }

  async function saveEdit() {
    if (!canMutate || !selectedBadge) return;

    const name = editName.trim();
    if (!name) return;

    setEditSaving(true);
    try {
      await apiFetch(`/admin/badges/${selectedBadge.id}`, {
        method: "PATCH",
        body: JSON.stringify({
          name,
          description: editDescription.trim(),
          imageUrl: editImageUrl.trim(),
          category: editCategory,
          rarity: editRarity,
          pointsRequirement: parseInt(editPoints) || 0,
          isActive: editActive,
        }),
      });

      closeEdit();
      await loadBadges();
    } finally {
      setEditSaving(false);
    }
  }

  async function grantBadge(e: FormEvent) {
    e.preventDefault();
    if (!canMutate || !selectedBadge) return;

    const userIdentifier = grantSelected?.email ?? grantUserIdentifier.trim();
    if (!userIdentifier) return;

    setGranting(true);
    try {
      await apiFetch(`/admin/badges/${selectedBadge.id}/grant`, {
        method: "POST",
        body: JSON.stringify({ userIdentifier }),
      });

      closeGrant();
      setGrantFeedback({
        type: "success",
        message: `Badge granted to ${userIdentifier}.`,
      });
    } catch (e: unknown) {
      setGrantFeedback({
        type: "error",
        message: e instanceof Error ? e.message : "Failed to grant badge",
      });
    } finally {
      setGranting(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Badges"
        description="Manage achievement badges that users earn through activity and milestones."
      >
        {canMutate ? (
          <Button onClick={openCreate}>
            <Plus className="h-4 w-4" />
            Create Badge
          </Button>
        ) : null}
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Badge management actions are available to owner, dev, and admin roles
            only.
          </CardContent>
        </Card>
      )}

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">
            {error}
          </CardContent>
        </Card>
      )}

      {grantFeedback && (
        <Card
          className={
            grantFeedback.type === "error"
              ? "border-red-500/30 bg-red-500/5"
              : "border-emerald-500/30 bg-emerald-500/5"
          }
        >
          <CardContent
            className={
              grantFeedback.type === "error"
                ? "pt-6 text-sm text-red-300"
                : "pt-6 text-sm text-emerald-300"
            }
          >
            {grantFeedback.message}
          </CardContent>
        </Card>
      )}

      <BadgesTable
        loading={isLoading}
        badgesLength={badges.length}
        groupedBadges={groupedBadges}
        canMutate={canMutate}
        onEdit={openEdit}
        onGrant={openGrant}
      />

      <BadgeCreateDialog
        open={createOpen}
        canMutate={canMutate}
        creating={creating}
        name={newName}
        description={newDescription}
        imageUrl={newImageUrl}
        category={newCategory}
        rarity={newRarity}
        points={newPoints}
        onOpenChange={closeCreate}
        setName={setNewName}
        setDescription={setNewDescription}
        setImageUrl={setNewImageUrl}
        setCategory={setNewCategory}
        setRarity={setNewRarity}
        setPoints={setNewPoints}
        onSubmit={createBadge}
      />

      <BadgeEditDialog
        open={editOpen}
        canMutate={canMutate}
        saving={editSaving}
        name={editName}
        description={editDescription}
        imageUrl={editImageUrl}
        category={editCategory}
        rarity={editRarity}
        points={editPoints}
        active={editActive}
        onOpenChange={closeEdit}
        setName={setEditName}
        setDescription={setEditDescription}
        setImageUrl={setEditImageUrl}
        setCategory={setEditCategory}
        setRarity={setEditRarity}
        setPoints={setEditPoints}
        setActive={setEditActive}
        onSave={saveEdit}
      />

      <BadgeGrantDialog
        open={grantOpen}
        canMutate={canMutate}
        granting={granting}
        selectedBadgeName={selectedBadge?.name ?? null}
        userIdentifier={grantUserIdentifier}
        selectedUser={grantSelected}
        grantMatches={grantMatches}
        searching={grantSearchLoading}
        onOpenChange={closeGrant}
        onUserIdentifierChange={setGrantUserIdentifier}
        onSelectUser={setGrantSelected}
        onSubmit={grantBadge}
      />
    </div>
  );
}
