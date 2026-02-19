"use client";

import { FormEvent, useEffect, useState } from "react";
import { Edit2, Loader2, Plus } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { PageHeader } from "@/components/page-header";
import { Badge } from "@/components/ui/badge";
import { useAdminSession } from "@/components/admin-shell";
import { canManageTags } from "@/lib/rbac";
import { clientApi, type Tag } from "@/lib/api-client";
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

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

function TableSkeleton() {
  return (
    <div className="space-y-3">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="flex items-center gap-4 py-2">
          <Skeleton className="h-4 w-24" />
          <Skeleton className="h-4 w-28" />
          <Skeleton className="ml-auto h-4 w-20" />
        </div>
      ))}
    </div>
  );
}

export default function TagsPage() {
  const session = useAdminSession();
  const canMutate = canManageTags(session.roles);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [primaryTags, setPrimaryTags] = useState<Tag[]>([]);
  const [secondaryTags, setSecondaryTags] = useState<Tag[]>([]);

  const [newPrimaryName, setNewPrimaryName] = useState("");
  const [newSecondaryName, setNewSecondaryName] = useState("");
  const [creatingPrimary, setCreatingPrimary] = useState(false);
  const [creatingSecondary, setCreatingSecondary] = useState(false);

  const [editOpen, setEditOpen] = useState(false);
  const [editType, setEditType] = useState<"primary" | "secondary">("primary");
  const [editTag, setEditTag] = useState<Tag | null>(null);
  const [editName, setEditName] = useState("");
  const [editSaving, setEditSaving] = useState(false);

  function load() {
    setLoading(true);
    setError(null);
    Promise.all([clientApi.listPrimaryTags(), clientApi.listSecondaryTags()])
      .then(([primary, secondary]) => {
        setPrimaryTags(primary);
        setSecondaryTags(secondary);
      })
      .catch((e: unknown) => {
        setPrimaryTags([]);
        setSecondaryTags([]);
        setError(e instanceof Error ? e.message : "Failed to load tags");
      })
      .finally(() => setLoading(false));
  }

  useEffect(() => {
    load();
  }, []);

  async function createPrimary(e: FormEvent) {
    e.preventDefault();
    if (!canMutate) return;
    const name = newPrimaryName.trim();
    if (!name) return;

    setCreatingPrimary(true);
    try {
      await clientApi.createPrimaryTag({ name });
      setNewPrimaryName("");
      load();
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
      await clientApi.createSecondaryTag({ name });
      setNewSecondaryName("");
      load();
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
        await clientApi.updatePrimaryTag(editTag.id, { name });
      } else {
        await clientApi.updateSecondaryTag(editTag.id, { name });
      }
      setEditOpen(false);
      load();
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
            Tag create/edit actions are available to owner and admin roles only.
          </CardContent>
        </Card>
      )}

      {error && (
        <Card>
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Primary Tags</CardTitle>
            <form className="mt-3 flex gap-2" onSubmit={createPrimary}>
              <Input
                value={newPrimaryName}
                onChange={(e) => setNewPrimaryName(e.target.value)}
                placeholder="Add primary tag"
                disabled={!canMutate || creatingPrimary}
              />
              <Button type="submit" disabled={!canMutate || creatingPrimary}>
                {creatingPrimary ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
                Add
              </Button>
            </form>
          </CardHeader>
          <CardContent>
            {loading ? (
              <TableSkeleton />
            ) : primaryTags.length === 0 ? (
              <p className="py-8 text-center text-sm text-muted-foreground">No primary tags found.</p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Slug</TableHead>
                    <TableHead className="text-right">Created</TableHead>
                    <TableHead className="w-[40px]" />
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {primaryTags.map((tag) => (
                    <TableRow key={tag.id}>
                      <TableCell>
                        <Badge variant="secondary">{tag.name}</Badge>
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">{tag.slug}</TableCell>
                      <TableCell className="text-right text-sm text-muted-foreground">
                        {formatDate(tag.createdAt)}
                      </TableCell>
                      <TableCell>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8"
                          disabled={!canMutate}
                          onClick={() => beginEdit("primary", tag)}
                        >
                          <Edit2 className="h-4 w-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Secondary Tags</CardTitle>
            <form className="mt-3 flex gap-2" onSubmit={createSecondary}>
              <Input
                value={newSecondaryName}
                onChange={(e) => setNewSecondaryName(e.target.value)}
                placeholder="Add secondary tag"
                disabled={!canMutate || creatingSecondary}
              />
              <Button type="submit" disabled={!canMutate || creatingSecondary}>
                {creatingSecondary ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
                Add
              </Button>
            </form>
          </CardHeader>
          <CardContent>
            {loading ? (
              <TableSkeleton />
            ) : secondaryTags.length === 0 ? (
              <p className="py-8 text-center text-sm text-muted-foreground">No secondary tags found.</p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Name</TableHead>
                    <TableHead>Slug</TableHead>
                    <TableHead className="text-right">Created</TableHead>
                    <TableHead className="w-[40px]" />
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {secondaryTags.map((tag) => (
                    <TableRow key={tag.id}>
                      <TableCell>
                        <Badge variant="secondary">{tag.name}</Badge>
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">{tag.slug}</TableCell>
                      <TableCell className="text-right text-sm text-muted-foreground">
                        {formatDate(tag.createdAt)}
                      </TableCell>
                      <TableCell>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8"
                          disabled={!canMutate}
                          onClick={() => beginEdit("secondary", tag)}
                        >
                          <Edit2 className="h-4 w-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
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
