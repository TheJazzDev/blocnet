"use client";

import { FormEvent, useState } from "react";
import { Loader2 } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import { canManageTags } from "@/lib/rbac";
import { type Tag } from "@/lib/api-client";
import { TagTypeCard } from "./TagTypeCard";
import {
  usePrimaryTagsQuery,
  useSecondaryTagsQuery,
  useCreatePrimaryTagMutation,
  useCreateSecondaryTagMutation,
  useUpdatePrimaryTagMutation,
  useUpdateSecondaryTagMutation,
} from "@/lib/hooks/queries";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export default function TagsPage() {
  const session = useAdminSession();
  const canMutate = canManageTags(session.effectiveRoles);

  // TanStack Query hooks
  const {
    data: primaryTags = [],
    isLoading: primaryLoading,
    error: primaryError,
  } = usePrimaryTagsQuery();
  const {
    data: secondaryTags = [],
    isLoading: secondaryLoading,
    error: secondaryError,
  } = useSecondaryTagsQuery();

  const createPrimaryMutation = useCreatePrimaryTagMutation();
  const createSecondaryMutation = useCreateSecondaryTagMutation();
  const updatePrimaryMutation = useUpdatePrimaryTagMutation();
  const updateSecondaryMutation = useUpdateSecondaryTagMutation();

  const loading = primaryLoading || secondaryLoading;
  const error =
    primaryError instanceof Error
      ? primaryError.message
      : secondaryError instanceof Error
        ? secondaryError.message
        : null;

  const [newPrimaryName, setNewPrimaryName] = useState("");
  const [newSecondaryName, setNewSecondaryName] = useState("");
  const [creatingPrimary, setCreatingPrimary] = useState(false);
  const [creatingSecondary, setCreatingSecondary] = useState(false);

  const [editOpen, setEditOpen] = useState(false);
  const [editType, setEditType] = useState<"primary" | "secondary">("primary");
  const [editTag, setEditTag] = useState<Tag | null>(null);
  const [editName, setEditName] = useState("");
  const [editSaving, setEditSaving] = useState(false);

  async function createPrimary(e: FormEvent) {
    e.preventDefault();
    if (!canMutate) return;
    const name = newPrimaryName.trim();
    if (!name) return;

    setCreatingPrimary(true);
    try {
      await createPrimaryMutation.mutateAsync({ name });
      setNewPrimaryName("");
    } finally {
      setCreatingPrimary(false);
    }
  }

  async function createSecondary(e: FormEvent) {
    e.preventDefault();
    if (!canMutate) return;
    const name = newSecondaryName.trim();
    if (!name) return;

    setCreatingSecondary(true);
    try {
      await createSecondaryMutation.mutateAsync({ name });
      setNewSecondaryName("");
    } finally {
      setCreatingSecondary(false);
    }
  }

  function beginEdit(type: "primary" | "secondary", tag: Tag) {
    setEditType(type);
    setEditTag(tag);
    setEditName(tag.name);
    setEditOpen(true);
  }

  async function saveEdit() {
    if (!canMutate || !editTag) return;
    const name = editName.trim();
    if (!name) return;

    setEditSaving(true);
    try {
      if (editType === "primary") {
        await updatePrimaryMutation.mutateAsync({ id: editTag.id, data: { name } });
      } else {
        await updateSecondaryMutation.mutateAsync({ id: editTag.id, data: { name } });
      }
      setEditOpen(false);
    } finally {
      setEditSaving(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader title="Tags" description="Manage primary and secondary project taxonomy tags." />

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Tag create/edit actions are available to owner, dev, and admin roles only.
          </CardContent>
        </Card>
      )}

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <TagTypeCard
          title="Primary Tags"
          inputValue={newPrimaryName}
          setInputValue={setNewPrimaryName}
          creating={creatingPrimary}
          canMutate={canMutate}
          loading={loading}
          emptyLabel="No primary tags found."
          tags={primaryTags}
          onCreate={createPrimary}
          onEdit={(tag) => beginEdit("primary", tag)}
          formatDate={formatDate}
        />

        <TagTypeCard
          title="Secondary Tags"
          inputValue={newSecondaryName}
          setInputValue={setNewSecondaryName}
          creating={creatingSecondary}
          canMutate={canMutate}
          loading={loading}
          emptyLabel="No secondary tags found."
          tags={secondaryTags}
          onCreate={createSecondary}
          onEdit={(tag) => beginEdit("secondary", tag)}
          formatDate={formatDate}
        />
      </div>

      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit {editType === "primary" ? "Primary" : "Secondary"} Tag</DialogTitle>
            <DialogDescription>Update tag name and regenerate slug.</DialogDescription>
          </DialogHeader>
          <Input
            value={editName}
            onChange={(e) => setEditName(e.target.value)}
            placeholder="Tag name"
            disabled={!canMutate || editSaving}
          />
          <DialogFooter>
            <Button variant="outline" onClick={() => setEditOpen(false)} disabled={editSaving}>
              Cancel
            </Button>
            <Button onClick={saveEdit} disabled={!canMutate || editSaving}>
              {editSaving && <Loader2 className="h-4 w-4 animate-spin" />}
              Save
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
