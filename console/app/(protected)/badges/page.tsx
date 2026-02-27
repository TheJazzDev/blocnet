"use client";

import { FormEvent, Fragment, useEffect, useMemo, useState } from "react";
import { Award, Edit2, Loader2, Plus, UserPlus } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { LoadingSpinner } from "@/components/ui/loading-spinner";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { useAdminSession } from "@/components/admin-shell";
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { apiFetch } from "@/lib/api-client";

interface BadgeModel {
  id: string;
  slug: string;
  name: string;
  description: string;
  imageUrl: string;
  category: string;
  rarity: string;
  pointsRequirement: number;
  isActive: boolean;
  sortOrder: number;
  createdAt: string;
}

interface UserSearchResult {
  id: string;
  email: string;
  displayName: string | null;
}

interface AdminUsersSearchResponse {
  data: UserSearchResult[];
  total: number;
  limit: number;
  offset: number;
}

const CATEGORIES = ["engagement", "mining", "social", "trust", "special"];
const RARITIES = ["common", "rare", "epic", "legendary"];
const CATEGORY_ORDER = [...CATEGORIES];
const RARITY_POWER: Record<string, number> = {
  legendary: 4,
  epic: 3,
  rare: 2,
  common: 1,
};

function toCategoryLabel(category: string) {
  return category
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function toLabel(value: string) {
  return value
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

function getRarityColor(rarity: string) {
  switch (rarity) {
    case "legendary": return "text-yellow-400";
    case "epic": return "text-purple-400";
    case "rare": return "text-blue-400";
    default: return "text-gray-400";
  }
}

export default function BadgesPage() {
  const session = useAdminSession();
  const canMutate = session.effectiveRoles.includes("owner") || session.effectiveRoles.includes("admin");

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [badges, setBadges] = useState<BadgeModel[]>([]);

  const [createOpen, setCreateOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [grantOpen, setGrantOpen] = useState(false);
  const [selectedBadge, setSelectedBadge] = useState<BadgeModel | null>(null);

  // Create form
  const [newName, setNewName] = useState("");
  const [newDescription, setNewDescription] = useState("");
  const [newImageUrl, setNewImageUrl] = useState("");
  const [newCategory, setNewCategory] = useState("engagement");
  const [newRarity, setNewRarity] = useState("common");
  const [newPoints, setNewPoints] = useState("0");
  const [creating, setCreating] = useState(false);

  // Edit form
  const [editName, setEditName] = useState("");
  const [editDescription, setEditDescription] = useState("");
  const [editImageUrl, setEditImageUrl] = useState("");
  const [editCategory, setEditCategory] = useState("engagement");
  const [editRarity, setEditRarity] = useState("common");
  const [editPoints, setEditPoints] = useState("0");
  const [editActive, setEditActive] = useState(true);
  const [editSaving, setEditSaving] = useState(false);

  // Grant form
  const [grantUserIdentifier, setGrantUserIdentifier] = useState("");
  const [grantMatches, setGrantMatches] = useState<UserSearchResult[]>([]);
  const [grantSearchLoading, setGrantSearchLoading] = useState(false);
  const [grantSelected, setGrantSelected] = useState<UserSearchResult | null>(null);
  const [granting, setGranting] = useState(false);
  const [grantFeedback, setGrantFeedback] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  const groupedBadges = useMemo(() => {
    const grouped = new Map<string, BadgeModel[]>();
    for (const badge of badges) {
      const key = badge.category?.trim().toLowerCase() || "uncategorized";
      const list = grouped.get(key);
      if (list) {
        list.push(badge);
      } else {
        grouped.set(key, [badge]);
      }
    }

    return [...grouped.entries()]
      .sort(([a], [b]) => {
        const aIndex = CATEGORY_ORDER.indexOf(a);
        const bIndex = CATEGORY_ORDER.indexOf(b);
        const resolvedA = aIndex === -1 ? Number.MAX_SAFE_INTEGER : aIndex;
        const resolvedB = bIndex === -1 ? Number.MAX_SAFE_INTEGER : bIndex;
        if (resolvedA !== resolvedB) return resolvedA - resolvedB;
        return a.localeCompare(b);
      })
      .map(([category, items]) => ({
        category,
        badges: [...items].sort((left, right) => {
          const leftPower = RARITY_POWER[left.rarity] ?? 0;
          const rightPower = RARITY_POWER[right.rarity] ?? 0;
          if (leftPower !== rightPower) {
            return rightPower - leftPower;
          }
          if (left.pointsRequirement !== right.pointsRequirement) {
            return right.pointsRequirement - left.pointsRequirement;
          }
          if (left.sortOrder !== right.sortOrder) {
            return left.sortOrder - right.sortOrder;
          }
          const createdAtDiff =
            new Date(left.createdAt).getTime() - new Date(right.createdAt).getTime();
          if (createdAtDiff !== 0) {
            return createdAtDiff;
          }
          return left.name.localeCompare(right.name);
        }),
      }));
  }, [badges]);

  function load() {
    setLoading(true);
    setError(null);
    apiFetch<BadgeModel[]>("/admin/badges")
      .then(setBadges)
      .catch((e: unknown) => {
        setBadges([]);
        setError(e instanceof Error ? e.message : "Failed to load badges");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, []);

  useEffect(() => {
    if (!grantOpen) {
      setGrantMatches([]);
      setGrantSearchLoading(false);
      return;
    }
    const query = grantUserIdentifier.trim();
    if (query.length < 2) {
      setGrantMatches([]);
      setGrantSearchLoading(false);
      return;
    }

    const timer = setTimeout(async () => {
      setGrantSearchLoading(true);
      try {
        const response = await apiFetch<AdminUsersSearchResponse>(
          `/admin/users?limit=8&offset=0&status=active&q=${encodeURIComponent(query)}`,
        );
        setGrantMatches(response.data ?? []);
      } catch {
        setGrantMatches([]);
      } finally {
        setGrantSearchLoading(false);
      }
    }, 250);

    return () => clearTimeout(timer);
  }, [grantOpen, grantUserIdentifier]);

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
      setNewName("");
      setNewDescription("");
      setNewImageUrl("");
      setNewCategory("engagement");
      setNewRarity("common");
      setNewPoints("0");
      setCreateOpen(false);
      load();
    } finally {
      setCreating(false);
    }
  }

  function beginEdit(badge: BadgeModel) {
    setSelectedBadge(badge);
    setEditName(badge.name);
    setEditDescription(badge.description);
    setEditImageUrl(badge.imageUrl);
    setEditCategory(badge.category);
    setEditRarity(badge.rarity);
    setEditPoints(badge.pointsRequirement.toString());
    setEditActive(badge.isActive);
    setEditOpen(true);
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
      setEditOpen(false);
      load();
    } finally {
      setEditSaving(false);
    }
  }

  function beginGrant(badge: BadgeModel) {
    setSelectedBadge(badge);
    setGrantUserIdentifier("");
    setGrantMatches([]);
    setGrantSelected(null);
    setGrantFeedback(null);
    setGrantOpen(true);
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
      setGrantOpen(false);
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
          <Button onClick={() => setCreateOpen(true)}>
            <Plus className="h-4 w-4" />
            Create Badge
          </Button>
        ) : null}
      </PageHeader>

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Badge management actions are available to owner and admin roles only.
          </CardContent>
        </Card>
      )}

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}
      {grantFeedback && (
        <Card className={grantFeedback.type === "error" ? "border-red-500/30 bg-red-500/5" : "border-emerald-500/30 bg-emerald-500/5"}>
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

      <Card>
        <CardHeader>
          <CardTitle>All Badges ({badges.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <LoadingSpinner className="py-10" />
          ) : badges.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No badges found.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Category</TableHead>
                  <TableHead>Rarity</TableHead>
                  <TableHead>Points Req.</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Created</TableHead>
                  <TableHead className="w-[100px]" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {groupedBadges.map((group) => (
                  <Fragment key={group.category}>
                    <TableRow className="bg-muted/20">
                      <TableCell colSpan={7} className="py-2">
                        <div className="flex items-center justify-between">
                          <span className="text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground">
                            {toCategoryLabel(group.category)}
                          </span>
                          <Badge variant="outline" className="text-[11px]">
                            {group.badges.length}
                          </Badge>
                        </div>
                      </TableCell>
                    </TableRow>
                    {group.badges.map((badge) => (
                      <TableRow key={badge.id}>
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <Award className={`h-4 w-4 ${getRarityColor(badge.rarity)}`} />
                            <span className="font-medium">{badge.name}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <Badge variant="outline">{toCategoryLabel(badge.category)}</Badge>
                        </TableCell>
                        <TableCell>
                          <span className={`text-sm font-medium ${getRarityColor(badge.rarity)}`}>
                            {toLabel(badge.rarity)}
                          </span>
                        </TableCell>
                        <TableCell className="text-sm">{badge.pointsRequirement}</TableCell>
                        <TableCell>
                          <Badge variant={badge.isActive ? "default" : "secondary"}>
                            {badge.isActive ? "Active" : "Inactive"}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-right text-sm text-muted-foreground">
                          {formatDate(badge.createdAt)}
                        </TableCell>
                        <TableCell>
                          <div className="flex gap-1">
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8"
                              disabled={!canMutate}
                              onClick={() => beginEdit(badge)}
                            >
                              <Edit2 className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="h-8 w-8"
                              disabled={!canMutate}
                              onClick={() => beginGrant(badge)}
                            >
                              <UserPlus className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </Fragment>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Create Dialog */}
      <Dialog open={createOpen} onOpenChange={setCreateOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Create New Badge</DialogTitle>
            <DialogDescription>Add a new achievement badge to the system.</DialogDescription>
          </DialogHeader>
          <form onSubmit={createBadge} className="space-y-4">
            <div>
              <label className="text-sm font-medium">Name</label>
              <Input
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="Founding Member"
                disabled={!canMutate || creating}
              />
            </div>
            <div>
              <label className="text-sm font-medium">Description</label>
              <Textarea
                value={newDescription}
                onChange={(e) => setNewDescription(e.target.value)}
                placeholder="Awarded to the first 100 users"
                disabled={!canMutate || creating}
                rows={3}
              />
            </div>
            <div>
              <label className="text-sm font-medium">Image URL</label>
              <Input
                value={newImageUrl}
                onChange={(e) => setNewImageUrl(e.target.value)}
                placeholder="https://example.com/badge.png"
                disabled={!canMutate || creating}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">Category</label>
                <Select value={newCategory} onValueChange={setNewCategory}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {CATEGORIES.map((cat) => (
                      <SelectItem key={cat} value={cat}>
                        {toCategoryLabel(cat)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="text-sm font-medium">Rarity</label>
                <Select value={newRarity} onValueChange={setNewRarity}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {RARITIES.map((r) => (
                      <SelectItem key={r} value={r}>
                        {toLabel(r)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div>
              <label className="text-sm font-medium">Points Requirement</label>
              <Input
                type="number"
                value={newPoints}
                onChange={(e) => setNewPoints(e.target.value)}
                placeholder="0"
                disabled={!canMutate || creating}
              />
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setCreateOpen(false)} disabled={creating}>
                Cancel
              </Button>
              <Button type="submit" disabled={!canMutate || creating}>
                {creating && <Loader2 className="h-4 w-4 animate-spin" />}
                Create Badge
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Edit Dialog */}
      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent className="max-w-2xl">
          <DialogHeader>
            <DialogTitle>Edit Badge</DialogTitle>
            <DialogDescription>Update badge details.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium">Name</label>
              <Input
                value={editName}
                onChange={(e) => setEditName(e.target.value)}
                disabled={!canMutate || editSaving}
              />
            </div>
            <div>
              <label className="text-sm font-medium">Description</label>
              <Textarea
                value={editDescription}
                onChange={(e) => setEditDescription(e.target.value)}
                disabled={!canMutate || editSaving}
                rows={3}
              />
            </div>
            <div>
              <label className="text-sm font-medium">Image URL</label>
              <Input
                value={editImageUrl}
                onChange={(e) => setEditImageUrl(e.target.value)}
                disabled={!canMutate || editSaving}
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">Category</label>
                <Select value={editCategory} onValueChange={setEditCategory}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {CATEGORIES.map((cat) => (
                      <SelectItem key={cat} value={cat}>
                        {toCategoryLabel(cat)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <label className="text-sm font-medium">Rarity</label>
                <Select value={editRarity} onValueChange={setEditRarity}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {RARITIES.map((r) => (
                      <SelectItem key={r} value={r}>
                        {toLabel(r)}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <div>
              <label className="text-sm font-medium">Points Requirement</label>
              <Input
                type="number"
                value={editPoints}
                onChange={(e) => setEditPoints(e.target.value)}
                disabled={!canMutate || editSaving}
              />
            </div>
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={editActive}
                onChange={(e) => setEditActive(e.target.checked)}
                disabled={!canMutate || editSaving}
                id="editActive"
              />
              <label htmlFor="editActive" className="text-sm font-medium">Active</label>
            </div>
          </div>
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

      {/* Grant Dialog */}
      <Dialog open={grantOpen} onOpenChange={setGrantOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Grant Badge</DialogTitle>
            <DialogDescription>
              Manually grant &quot;{selectedBadge?.name}&quot; badge to a user.
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={grantBadge} className="space-y-4">
            <div>
              <label className="text-sm font-medium">User Email or UUID</label>
              <Input
                value={grantUserIdentifier}
                onChange={(e) => {
                  setGrantUserIdentifier(e.target.value);
                  setGrantSelected(null);
                }}
                placeholder="Search by email or paste user UUID"
                disabled={!canMutate || granting}
              />
              {grantSearchLoading && (
                <p className="mt-2 text-xs text-muted-foreground">Searching users...</p>
              )}
              {!grantSearchLoading && grantMatches.length > 0 && !grantSelected && (
                <div className="mt-2 max-h-40 space-y-1 overflow-auto rounded-md border p-2">
                  {grantMatches.map((entry) => (
                    <button
                      key={entry.id}
                      type="button"
                      className="w-full rounded-sm px-2 py-1 text-left text-sm hover:bg-accent"
                      onClick={() => {
                        setGrantSelected(entry);
                        setGrantUserIdentifier(entry.email);
                        setGrantMatches([]);
                      }}
                    >
                      <span className="font-medium">{entry.displayName ?? entry.email}</span>
                      <span className="ml-2 text-xs text-muted-foreground">{entry.email}</span>
                    </button>
                  ))}
                </div>
              )}
              {grantSelected && (
                <p className="mt-2 text-xs text-emerald-300">
                  Selected: {grantSelected.displayName ?? grantSelected.email} ({grantSelected.id})
                </p>
              )}
            </div>
            <DialogFooter>
              <Button type="button" variant="outline" onClick={() => setGrantOpen(false)} disabled={granting}>
                Cancel
              </Button>
              <Button type="submit" disabled={!canMutate || granting}>
                {granting && <Loader2 className="h-4 w-4 animate-spin" />}
                Grant Badge
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
