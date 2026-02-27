"use client";

import { useAdminSession } from "@/components/admin-shell";
import { apiFetch } from "@/lib/api-client";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { FormEvent, useEffect, useState } from "react";
import { AlertCircle, CheckCircle2, Loader2, Plus, Edit, Award } from "lucide-react";
import { PageHeader } from "@/components/page-header";

interface QuestModel {
  id: string;
  slug: string;
  title: string;
  description: string;
  type: string;
  category: string;
  rewardPoints: number;
  rewardBadgeId: string | null;
  rewardBadge?: {
    id: string;
    name: string;
    imageUrl: string;
  } | null;
  targetUrl: string | null;
  targetAction: string | null;
  verificationMethod: string;
  requiredProof: string | null;
  isActive: boolean;
  sortOrder: number;
  expiresAt: string | null;
  createdAt: string;
}

interface BadgeOption {
  id: string;
  name: string;
  slug: string;
}

const QUEST_TYPES = [
  { value: "external_link", label: "External Link" },
  { value: "internal_action", label: "Internal Action" },
  { value: "social_media", label: "Social Media" },
];

const QUEST_CATEGORIES = [
  { value: "special", label: "Special" },
  { value: "mining", label: "Mining" },
  { value: "engagement", label: "Engagement" },
  { value: "social", label: "Social" },
  { value: "trust", label: "Trust" },
];

const VERIFICATION_METHODS = [
  { value: "auto", label: "Auto" },
  { value: "manual", label: "Manual" },
];

const NONE_OPTION_VALUE = "__none__";

function formatDate(dateString: string | null): string {
  if (!dateString) return "—";
  try {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  } catch {
    return "Invalid Date";
  }
}

function questTypeBadgeClass(type: string): string {
  switch (type) {
    case "internal_action":
      return "border border-amber-400/30 bg-amber-400/12 text-amber-200";
    case "social_media":
      return "border border-fuchsia-400/30 bg-fuchsia-400/12 text-fuchsia-200";
    case "external_link":
    default:
      return "border border-sky-400/30 bg-sky-400/12 text-sky-200";
  }
}

function questCategoryBadgeClass(category: string): string {
  switch (category) {
    case "mining":
      return "border border-indigo-400/30 bg-indigo-400/12 text-indigo-200";
    case "engagement":
      return "border border-emerald-400/30 bg-emerald-400/12 text-emerald-200";
    case "social":
      return "border border-pink-400/30 bg-pink-400/12 text-pink-200";
    case "trust":
      return "border border-cyan-400/30 bg-cyan-400/12 text-cyan-200";
    case "special":
    default:
      return "border border-violet-400/30 bg-violet-400/12 text-violet-200";
  }
}

function verificationBadgeClass(method: string): string {
  return method === "auto"
    ? "border border-emerald-400/30 bg-emerald-400/12 text-emerald-200"
    : "border border-orange-400/30 bg-orange-400/12 text-orange-200";
}

export default function QuestsPage() {
  const session = useAdminSession();
  const [quests, setQuests] = useState<QuestModel[]>([]);
  const [badges, setBadges] = useState<BadgeOption[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [createOpen, setCreateOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [selectedQuest, setSelectedQuest] = useState<QuestModel | null>(null);
  const [createSubmitError, setCreateSubmitError] = useState<string | null>(null);
  const [editSubmitError, setEditSubmitError] = useState<string | null>(null);

  const canManageQuests =
    session.effectiveRoles.includes("owner") || session.effectiveRoles.includes("admin");
  const activeQuestsCount = quests.filter((quest) => quest.isActive).length;
  const inactiveQuestsCount = quests.length - activeQuestsCount;
  const autoVerifiedCount = quests.filter(
    (quest) => quest.verificationMethod === "auto",
  ).length;
  const manualVerifiedCount = quests.length - autoVerifiedCount;
  const configuredRewardPointsTotal = quests.reduce(
    (total, quest) => total + (quest.rewardPoints ?? 0),
    0,
  );

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    setIsLoading(true);
    setError(null);
    try {
      const [questsData, badgesData] = await Promise.all([
        apiFetch<QuestModel[]>("/admin/quests"),
        apiFetch<BadgeOption[]>("/admin/badges"),
      ]);
      setQuests(questsData ?? []);
      setBadges(badgesData ?? []);
    } catch (err: unknown) {
      console.error("Error fetching data:", err);
      setError(err instanceof Error ? err.message : "Failed to load quests");
    } finally {
      setIsLoading(false);
    }
  }

  function openCreate() {
    setCreateSubmitError(null);
    setCreateOpen(true);
  }

  function openEdit(quest: QuestModel) {
    setSelectedQuest(quest);
    setEditSubmitError(null);
    setEditOpen(true);
  }

  async function handleCreateSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);

    const payload: Record<string, unknown> = {
      title: formData.get("title"),
      description: formData.get("description"),
      type: formData.get("type"),
      category: formData.get("category"),
      rewardPoints: parseInt(formData.get("rewardPoints") as string, 10) || 0,
      verificationMethod: formData.get("verificationMethod"),
      targetUrl: formData.get("targetUrl") || null,
      targetAction: formData.get("targetAction") || null,
      requiredProof: formData.get("requiredProof") || null,
      expiresAt: formData.get("expiresAt") || null,
    };

    const rewardBadgeId = formData.get("rewardBadgeId") as string;
    if (rewardBadgeId && rewardBadgeId !== NONE_OPTION_VALUE) {
      payload.rewardBadgeId = rewardBadgeId;
    }

    setCreateSubmitError(null);
    try {
      await apiFetch("/admin/quests", {
        method: "POST",
        body: JSON.stringify(payload),
      });
      setCreateOpen(false);
      void fetchData();
    } catch (err: unknown) {
      setCreateSubmitError(
        err instanceof Error ? err.message : "Failed to create quest",
      );
    }
  }

  async function handleEditSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!selectedQuest) return;

    const formData = new FormData(e.currentTarget);

    const payload: Record<string, unknown> = {
      title: formData.get("title"),
      description: formData.get("description"),
      type: formData.get("type"),
      category: formData.get("category"),
      rewardPoints: parseInt(formData.get("rewardPoints") as string, 10) || 0,
      verificationMethod: formData.get("verificationMethod"),
      isActive: formData.get("isActive") === "true",
      targetUrl: formData.get("targetUrl") || null,
      targetAction: formData.get("targetAction") || null,
      requiredProof: formData.get("requiredProof") || null,
      expiresAt: formData.get("expiresAt") || null,
    };

    const rewardBadgeId = formData.get("rewardBadgeId") as string;
    if (rewardBadgeId && rewardBadgeId !== NONE_OPTION_VALUE) {
      payload.rewardBadgeId = rewardBadgeId;
    } else {
      payload.rewardBadgeId = null;
    }

    setEditSubmitError(null);
    try {
      await apiFetch(`/admin/quests/${selectedQuest.id}`, {
        method: "PATCH",
        body: JSON.stringify(payload),
      });
      setEditOpen(false);
      setSelectedQuest(null);
      void fetchData();
    } catch (err: unknown) {
      setEditSubmitError(
        err instanceof Error ? err.message : "Failed to update quest",
      );
    }
  }

  if (!canManageQuests) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="rounded-lg border border-destructive/35 bg-destructive/10 p-6">
          <p className="text-sm text-destructive-foreground">You do not have permission to manage quests.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Quests"
        description="Manage quests, balance incentives, and monitor verification mix."
      >
        <Button onClick={openCreate} size="sm" className="gap-2">
          <Plus className="h-4 w-4" />
          <span className="hidden sm:inline">Create Quest</span>
          <span className="sm:hidden">New</span>
        </Button>
      </PageHeader>

      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
        <div className="rounded-lg border bg-card p-3">
          <p className="text-xs text-muted-foreground">Total Quests</p>
          <p className="text-lg font-semibold">{quests.length.toLocaleString()}</p>
        </div>
        <div className="rounded-lg border bg-card p-3">
          <p className="text-xs text-muted-foreground">Active / Inactive</p>
          <p className="text-lg font-semibold">
            {activeQuestsCount.toLocaleString()} / {inactiveQuestsCount.toLocaleString()}
          </p>
        </div>
        <div className="rounded-lg border bg-card p-3">
          <p className="text-xs text-muted-foreground">Auto / Manual Verification</p>
          <p className="text-lg font-semibold">
            {autoVerifiedCount.toLocaleString()} / {manualVerifiedCount.toLocaleString()}
          </p>
        </div>
        <div className="rounded-lg border bg-card p-3">
          <p className="text-xs text-muted-foreground">Configured Reward Points</p>
          <p className="text-lg font-semibold">{configuredRewardPointsTotal.toLocaleString()}</p>
        </div>
        <div className="rounded-lg border bg-card p-3">
          <p className="text-xs text-muted-foreground">Average Reward / Quest</p>
          <p className="text-lg font-semibold">
            {quests.length > 0
              ? Math.round(configuredRewardPointsTotal / quests.length).toLocaleString()
              : "0"}
          </p>
        </div>
      </div>

      {error && (
        <div className="rounded-lg border border-destructive/35 bg-destructive/10 p-4">
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 shrink-0 text-destructive" />
            <p className="text-sm text-destructive-foreground">{error}</p>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-6 w-6 animate-spin text-primary" />
        </div>
      ) : (
        <div className="rounded-lg border bg-card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Title</TableHead>
                <TableHead className="hidden md:table-cell">Type</TableHead>
                <TableHead className="hidden lg:table-cell">Category</TableHead>
                <TableHead className="hidden sm:table-cell">Rewards</TableHead>
                <TableHead className="hidden xl:table-cell">Verification</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="hidden lg:table-cell">Expires</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {quests.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={8} className="text-center py-8 text-muted-foreground">
                    No quests found. Create your first quest to get started.
                  </TableCell>
                </TableRow>
              ) : (
                quests.map((quest) => (
                  <TableRow key={quest.id}>
                    <TableCell>
                      <div className="space-y-1">
                        <p className="font-medium text-sm">{quest.title}</p>
                        <p className="text-xs text-muted-foreground line-clamp-1">
                          {quest.description}
                        </p>
                      </div>
                    </TableCell>
                    <TableCell className="hidden md:table-cell">
                      <span
                        className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ${questTypeBadgeClass(quest.type)}`}
                      >
                        {QUEST_TYPES.find((t) => t.value === quest.type)?.label ?? quest.type}
                      </span>
                    </TableCell>
                    <TableCell className="hidden lg:table-cell">
                      <span
                        className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ${questCategoryBadgeClass(quest.category)}`}
                      >
                        {QUEST_CATEGORIES.find((c) => c.value === quest.category)?.label ??
                          quest.category}
                      </span>
                    </TableCell>
                    <TableCell className="hidden sm:table-cell">
                      <div className="flex flex-col gap-1">
                        {quest.rewardPoints > 0 && (
                          <span className="text-xs text-muted-foreground">
                            {quest.rewardPoints} pts
                          </span>
                        )}
                        {quest.rewardBadge && (
                          <div className="flex items-center gap-1">
                            <Award className="h-3 w-3 text-yellow-600" />
                            <span className="text-xs text-muted-foreground">
                              {quest.rewardBadge.name}
                            </span>
                          </div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell className="hidden xl:table-cell">
                      <span
                        className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ${verificationBadgeClass(quest.verificationMethod)}`}
                      >
                        {quest.verificationMethod === "auto" ? "Auto" : "Manual"}
                      </span>
                    </TableCell>
                    <TableCell>
                      {quest.isActive ? (
                        <span className="inline-flex items-center gap-1 rounded-md border border-emerald-400/30 bg-emerald-400/12 px-2 py-1 text-xs font-medium text-emerald-200">
                          <CheckCircle2 className="h-3 w-3" />
                          Active
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 rounded-md border border-zinc-400/30 bg-zinc-400/12 px-2 py-1 text-xs font-medium text-zinc-200">
                          <AlertCircle className="h-3 w-3" />
                          Inactive
                        </span>
                      )}
                    </TableCell>
                    <TableCell className="hidden lg:table-cell text-xs text-muted-foreground">
                      {formatDate(quest.expiresAt)}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button variant="ghost" size="sm" onClick={() => openEdit(quest)}>
                        <Edit className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </div>
      )}

      {/* Create Dialog */}
      <Dialog
        open={createOpen}
        onOpenChange={(nextOpen) => {
          setCreateOpen(nextOpen);
          if (!nextOpen) {
            setCreateSubmitError(null);
          }
        }}
      >
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Create New Quest</DialogTitle>
            <DialogDescription>
              Add a new quest for users to complete and earn rewards.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleCreateSubmit}>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="create-title">Title *</Label>
                <Input id="create-title" name="title" required placeholder="Follow us on X" />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="create-description">Description *</Label>
                <Textarea
                  id="create-description"
                  name="description"
                  required
                  placeholder="Follow our official X account to stay updated"
                  rows={3}
                />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="grid gap-2">
                  <Label htmlFor="create-type">Type *</Label>
                  <Select name="type" defaultValue="external_link" required>
                    <SelectTrigger id="create-type">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {QUEST_TYPES.map((type) => (
                        <SelectItem key={type.value} value={type.value}>
                          {type.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="create-category">Category *</Label>
                  <Select name="category" defaultValue="social" required>
                    <SelectTrigger id="create-category">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {QUEST_CATEGORIES.map((cat) => (
                        <SelectItem key={cat.value} value={cat.value}>
                          {cat.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div className="grid gap-2">
                  <Label htmlFor="create-points">Reward Points</Label>
                  <Input
                    id="create-points"
                    name="rewardPoints"
                    type="number"
                    defaultValue={0}
                    min={0}
                  />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="create-badge">Reward Badge (Optional)</Label>
                    <Select name="rewardBadgeId" defaultValue={NONE_OPTION_VALUE}>
                      <SelectTrigger id="create-badge">
                        <SelectValue placeholder="None" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value={NONE_OPTION_VALUE}>None</SelectItem>
                        {badges.map((badge) => (
                          <SelectItem key={badge.id} value={badge.id}>
                            {badge.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="create-verification">Verification Method *</Label>
                <Select name="verificationMethod" defaultValue="manual" required>
                  <SelectTrigger id="create-verification">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {VERIFICATION_METHODS.map((method) => (
                      <SelectItem key={method.value} value={method.value}>
                        {method.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="grid gap-2">
                <Label htmlFor="create-targetUrl">Target URL (Optional)</Label>
                <Input
                  id="create-targetUrl"
                  name="targetUrl"
                  type="url"
                  placeholder="https://x.com/blocnet"
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="create-targetAction">Target Action (Optional)</Label>
                <Input
                  id="create-targetAction"
                  name="targetAction"
                  placeholder="follow_on_x"
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="create-requiredProof">Required Proof (Optional)</Label>
                <Textarea
                  id="create-requiredProof"
                  name="requiredProof"
                  placeholder="Provide a screenshot showing you followed our account"
                  rows={2}
                />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="create-expiresAt">Expires At (Optional)</Label>
                <Input id="create-expiresAt" name="expiresAt" type="datetime-local" />
              </div>
            </div>
            {createSubmitError ? (
              <p className="mb-2 text-sm text-destructive">{createSubmitError}</p>
            ) : null}
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setCreateOpen(false)}>
                Cancel
              </Button>
              <Button type="submit">Create Quest</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Edit Dialog */}
      <Dialog
        open={editOpen}
        onOpenChange={(nextOpen) => {
          setEditOpen(nextOpen);
          if (!nextOpen) {
            setEditSubmitError(null);
          }
        }}
      >
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Edit Quest</DialogTitle>
            <DialogDescription>Update quest details and rewards.</DialogDescription>
          </DialogHeader>
          {selectedQuest && (
            <form onSubmit={handleEditSubmit}>
              <div className="grid gap-4 py-4">
                <div className="grid gap-2">
                  <Label htmlFor="edit-title">Title *</Label>
                  <Input
                    id="edit-title"
                    name="title"
                    required
                    defaultValue={selectedQuest.title}
                  />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="edit-description">Description *</Label>
                  <Textarea
                    id="edit-description"
                    name="description"
                    required
                    defaultValue={selectedQuest.description}
                    rows={3}
                  />
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="edit-type">Type *</Label>
                    <Select name="type" defaultValue={selectedQuest.type} required>
                      <SelectTrigger id="edit-type">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {QUEST_TYPES.map((type) => (
                          <SelectItem key={type.value} value={type.value}>
                            {type.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="grid gap-2">
                    <Label htmlFor="edit-category">Category *</Label>
                    <Select name="category" defaultValue={selectedQuest.category} required>
                      <SelectTrigger id="edit-category">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {QUEST_CATEGORIES.map((cat) => (
                          <SelectItem key={cat.value} value={cat.value}>
                            {cat.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="edit-points">Reward Points</Label>
                    <Input
                      id="edit-points"
                      name="rewardPoints"
                      type="number"
                      defaultValue={selectedQuest.rewardPoints}
                      min={0}
                    />
                  </div>

                  <div className="grid gap-2">
                    <Label htmlFor="edit-badge">Reward Badge (Optional)</Label>
                    <Select
                      name="rewardBadgeId"
                      defaultValue={selectedQuest.rewardBadgeId ?? NONE_OPTION_VALUE}
                    >
                      <SelectTrigger id="edit-badge">
                        <SelectValue placeholder="None" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value={NONE_OPTION_VALUE}>None</SelectItem>
                        {badges.map((badge) => (
                          <SelectItem key={badge.id} value={badge.id}>
                            {badge.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="edit-verification">Verification Method *</Label>
                  <Select
                    name="verificationMethod"
                    defaultValue={selectedQuest.verificationMethod}
                    required
                  >
                    <SelectTrigger id="edit-verification">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {VERIFICATION_METHODS.map((method) => (
                        <SelectItem key={method.value} value={method.value}>
                          {method.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="edit-targetUrl">Target URL (Optional)</Label>
                  <Input
                    id="edit-targetUrl"
                    name="targetUrl"
                    type="url"
                    defaultValue={selectedQuest.targetUrl ?? ""}
                  />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="edit-targetAction">Target Action (Optional)</Label>
                  <Input
                    id="edit-targetAction"
                    name="targetAction"
                    defaultValue={selectedQuest.targetAction ?? ""}
                  />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="edit-requiredProof">Required Proof (Optional)</Label>
                  <Textarea
                    id="edit-requiredProof"
                    name="requiredProof"
                    defaultValue={selectedQuest.requiredProof ?? ""}
                    rows={2}
                  />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="edit-expiresAt">Expires At (Optional)</Label>
                  <Input
                    id="edit-expiresAt"
                    name="expiresAt"
                    type="datetime-local"
                    defaultValue={
                      selectedQuest.expiresAt
                        ? new Date(selectedQuest.expiresAt).toISOString().slice(0, 16)
                        : ""
                    }
                  />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="edit-isActive">Status *</Label>
                  <Select
                    name="isActive"
                    defaultValue={selectedQuest.isActive ? "true" : "false"}
                    required
                  >
                    <SelectTrigger id="edit-isActive">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="true">Active</SelectItem>
                      <SelectItem value="false">Inactive</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              {editSubmitError ? (
                <p className="mb-2 text-sm text-destructive">{editSubmitError}</p>
              ) : null}
              <DialogFooter>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    setEditOpen(false);
                    setSelectedQuest(null);
                  }}
                >
                  Cancel
                </Button>
                <Button type="submit">Save Changes</Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
