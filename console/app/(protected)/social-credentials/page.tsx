"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { Eye, EyeOff, Loader2, Pencil, Plus, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useAdminSession } from "@/components/admin-shell";
import { PageHeader } from "@/components/page-header";
import { clientApi, type AdminSocialCredential } from "@/lib/api-client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";

type CredentialFormState = {
  provider: string;
  accountLabel: string;
  username: string;
  password: string;
  notes: string;
};

const EMPTY_FORM: CredentialFormState = {
  provider: "",
  accountLabel: "",
  username: "",
  password: "",
  notes: "",
};

function normalizeOptional(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function prettyProvider(provider: string): string {
  return provider
    .split(/[_\-\s]+/)
    .filter(Boolean)
    .map((entry) => entry[0].toUpperCase() + entry.slice(1))
    .join(" ");
}

export default function SocialCredentialsPage() {
  const session = useAdminSession();
  const router = useRouter();
  const isOwner = useMemo(
    () => session.realRoles.includes("owner") || session.effectiveRoles.includes("owner"),
    [session.effectiveRoles, session.realRoles],
  );

  const [rows, setRows] = useState<AdminSocialCredential[]>([]);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [revealed, setRevealed] = useState<Record<string, string>>({});
  const [busyId, setBusyId] = useState<string | null>(null);

  const [createOpen, setCreateOpen] = useState(false);
  const [createForm, setCreateForm] = useState<CredentialFormState>(EMPTY_FORM);
  const [createSaving, setCreateSaving] = useState(false);

  const [editOpen, setEditOpen] = useState(false);
  const [editTarget, setEditTarget] = useState<AdminSocialCredential | null>(null);
  const [editForm, setEditForm] = useState<CredentialFormState>(EMPTY_FORM);
  const [editSaving, setEditSaving] = useState(false);

  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<AdminSocialCredential | null>(null);
  const [deleteSaving, setDeleteSaving] = useState(false);

  async function loadRows() {
    setLoading(true);
    setError(null);
    setStatus(null);
    try {
      const payload = await clientApi.listSocialCredentials();
      setRows(payload.data ?? []);
    } catch (e: unknown) {
      setRows([]);
      setError(e instanceof Error ? e.message : "Failed to load social credentials");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!isOwner) {
      router.replace("/dashboard");
      return;
    }
  }, [isOwner, router]);

  useEffect(() => {
    if (!isOwner) {
      setLoading(false);
      return;
    }
    void loadRows();
  }, [isOwner]);

  function openCreateDialog() {
    setCreateForm(EMPTY_FORM);
    setCreateOpen(true);
    setError(null);
    setStatus(null);
  }

  function openEditDialog(row: AdminSocialCredential) {
    setEditTarget(row);
    setEditForm({
      provider: row.provider,
      accountLabel: row.accountLabel ?? "",
      username: row.username ?? "",
      password: "",
      notes: row.notes ?? "",
    });
    setEditOpen(true);
    setError(null);
    setStatus(null);
  }

  function openDeleteDialog(row: AdminSocialCredential) {
    setDeleteTarget(row);
    setDeleteOpen(true);
    setError(null);
    setStatus(null);
  }

  async function submitCreate(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!isOwner || createSaving) return;
    if (!createForm.provider.trim() || !createForm.password) {
      setError("Provider and password are required.");
      return;
    }

    setCreateSaving(true);
    setError(null);
    setStatus(null);
    try {
      const created = await clientApi.createSocialCredential({
        provider: createForm.provider.trim(),
        accountLabel: normalizeOptional(createForm.accountLabel),
        username: normalizeOptional(createForm.username),
        password: createForm.password,
        notes: normalizeOptional(createForm.notes),
      });
      setRows((prev) => [created, ...prev]);
      setCreateOpen(false);
      setCreateForm(EMPTY_FORM);
      setStatus("Credential created.");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to create credential");
    } finally {
      setCreateSaving(false);
    }
  }

  async function submitEdit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!isOwner || editSaving || !editTarget) return;
    if (!editForm.provider.trim()) {
      setError("Provider is required.");
      return;
    }

    setEditSaving(true);
    setError(null);
    setStatus(null);
    try {
      const updated = await clientApi.updateSocialCredential(editTarget.id, {
        provider: editForm.provider.trim(),
        accountLabel: normalizeOptional(editForm.accountLabel),
        username: normalizeOptional(editForm.username),
        password: editForm.password ? editForm.password : undefined,
        notes: normalizeOptional(editForm.notes),
      });
      setRows((prev) => prev.map((entry) => (entry.id === updated.id ? updated : entry)));
      setRevealed((prev) => {
        if (!prev[updated.id]) return prev;
        const next = { ...prev };
        delete next[updated.id];
        return next;
      });
      setEditOpen(false);
      setEditTarget(null);
      setEditForm(EMPTY_FORM);
      setStatus("Credential updated.");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to update credential");
    } finally {
      setEditSaving(false);
    }
  }

  async function confirmDelete() {
    if (!isOwner || deleteSaving || !deleteTarget) return;

    setDeleteSaving(true);
    setError(null);
    setStatus(null);
    try {
      await clientApi.deleteSocialCredential(deleteTarget.id);
      setRows((prev) => prev.filter((entry) => entry.id !== deleteTarget.id));
      setRevealed((prev) => {
        if (!prev[deleteTarget.id]) return prev;
        const next = { ...prev };
        delete next[deleteTarget.id];
        return next;
      });
      setStatus("Credential deleted.");
      setDeleteOpen(false);
      setDeleteTarget(null);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to delete credential");
    } finally {
      setDeleteSaving(false);
    }
  }

  async function toggleReveal(row: AdminSocialCredential) {
    const existing = revealed[row.id];
    if (existing !== undefined) {
      setRevealed((prev) => {
        const next = { ...prev };
        delete next[row.id];
        return next;
      });
      return;
    }

    setBusyId(row.id);
    setError(null);
    try {
      const payload = await clientApi.revealSocialCredentialPassword(row.id);
      setRevealed((prev) => ({
        ...prev,
        [row.id]: payload.password,
      }));
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to reveal password");
    } finally {
      setBusyId((prev) => (prev === row.id ? null : prev));
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Social Credentials"
        description="Owner-only encrypted vault for social media account credentials."
      >
        {isOwner && (
          <Button onClick={openCreateDialog}>
            <Plus className="h-4 w-4" />
            Add Credential
          </Button>
        )}
      </PageHeader>

      {!isOwner ? (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Owner role is required to view or mutate social credentials.
          </CardContent>
        </Card>
      ) : (
        <>
          <Card className="border-primary/20 bg-primary/5">
            <CardHeader className="pb-3">
              <CardTitle className="text-base">Vault Controls</CardTitle>
              <CardDescription>
                Passwords are encrypted at rest and masked by default.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-2 text-xs text-muted-foreground">
              <p>Use View to reveal an entry temporarily.</p>
              <p>Create, update, or delete entries as credentials rotate.</p>
            </CardContent>
          </Card>

          {error && (
            <Card className="border-destructive/40 bg-destructive/10">
              <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
            </Card>
          )}

          {status && (
            <Card className="border-emerald-500/30 bg-emerald-500/10">
              <CardContent className="pt-6 text-sm text-emerald-300">{status}</CardContent>
            </Card>
          )}

          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-base">Stored Credentials</CardTitle>
              <CardDescription>{rows.length} record(s)</CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex items-center justify-center py-12">
                  <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" />
                </div>
              ) : rows.length === 0 ? (
                <p className="py-8 text-sm text-muted-foreground">
                  No credentials added yet.
                </p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Provider</TableHead>
                      <TableHead>Account</TableHead>
                      <TableHead>Username</TableHead>
                      <TableHead>Password</TableHead>
                      <TableHead>Updated</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {rows.map((row) => {
                      const visiblePassword = revealed[row.id];
                      return (
                        <TableRow key={row.id}>
                          <TableCell>
                            <Badge variant="outline">{prettyProvider(row.provider)}</Badge>
                          </TableCell>
                          <TableCell>{row.accountLabel || "-"}</TableCell>
                          <TableCell>{row.username || "-"}</TableCell>
                          <TableCell className="font-mono text-xs">
                            {visiblePassword ?? row.passwordMasked}
                          </TableCell>
                          <TableCell className="text-xs text-muted-foreground">
                            {new Date(row.updatedAt).toLocaleString()}
                          </TableCell>
                          <TableCell className="text-right">
                            <div className="flex justify-end gap-2">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => void toggleReveal(row)}
                                disabled={busyId === row.id}
                              >
                                {busyId === row.id ? (
                                  <Loader2 className="h-4 w-4 animate-spin" />
                                ) : visiblePassword ? (
                                  <EyeOff className="h-4 w-4" />
                                ) : (
                                  <Eye className="h-4 w-4" />
                                )}
                                {visiblePassword ? "Hide" : "View"}
                              </Button>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => openEditDialog(row)}
                              >
                                <Pencil className="h-4 w-4" />
                                Edit
                              </Button>
                              <Button
                                variant="destructive"
                                size="sm"
                                onClick={() => openDeleteDialog(row)}
                              >
                                <Trash2 className="h-4 w-4" />
                                Delete
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </>
      )}

      <Dialog open={createOpen} onOpenChange={setCreateOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Credential</DialogTitle>
            <DialogDescription>Add a new social account credential record.</DialogDescription>
          </DialogHeader>
          <form className="space-y-4" onSubmit={(event) => void submitCreate(event)}>
            <div className="space-y-2">
              <Label htmlFor="create-provider">Provider</Label>
              <Input
                id="create-provider"
                value={createForm.provider}
                onChange={(event) =>
                  setCreateForm((prev) => ({ ...prev, provider: event.target.value }))
                }
                placeholder="x, instagram, tiktok, playstore"
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="create-account-label">Account Label</Label>
              <Input
                id="create-account-label"
                value={createForm.accountLabel}
                onChange={(event) =>
                  setCreateForm((prev) => ({ ...prev, accountLabel: event.target.value }))
                }
                placeholder="blocnetapp@gmail.com"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="create-username">Username</Label>
              <Input
                id="create-username"
                value={createForm.username}
                onChange={(event) =>
                  setCreateForm((prev) => ({ ...prev, username: event.target.value }))
                }
                placeholder="@blocnet_app"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="create-password">Password</Label>
              <Input
                id="create-password"
                type="password"
                value={createForm.password}
                onChange={(event) =>
                  setCreateForm((prev) => ({ ...prev, password: event.target.value }))
                }
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="create-notes">Notes</Label>
              <Textarea
                id="create-notes"
                rows={3}
                value={createForm.notes}
                onChange={(event) =>
                  setCreateForm((prev) => ({ ...prev, notes: event.target.value }))
                }
                placeholder="Optional context"
              />
            </div>
            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setCreateOpen(false)}
                disabled={createSaving}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={createSaving}>
                {createSaving && <Loader2 className="h-4 w-4 animate-spin" />}
                Save Credential
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={editOpen} onOpenChange={setEditOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Credential</DialogTitle>
            <DialogDescription>
              Update account details. Leave password empty to keep existing value.
            </DialogDescription>
          </DialogHeader>
          <form className="space-y-4" onSubmit={(event) => void submitEdit(event)}>
            <div className="space-y-2">
              <Label htmlFor="edit-provider">Provider</Label>
              <Input
                id="edit-provider"
                value={editForm.provider}
                onChange={(event) =>
                  setEditForm((prev) => ({ ...prev, provider: event.target.value }))
                }
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-account-label">Account Label</Label>
              <Input
                id="edit-account-label"
                value={editForm.accountLabel}
                onChange={(event) =>
                  setEditForm((prev) => ({ ...prev, accountLabel: event.target.value }))
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-username">Username</Label>
              <Input
                id="edit-username"
                value={editForm.username}
                onChange={(event) =>
                  setEditForm((prev) => ({ ...prev, username: event.target.value }))
                }
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-password">New Password</Label>
              <Input
                id="edit-password"
                type="password"
                value={editForm.password}
                onChange={(event) =>
                  setEditForm((prev) => ({ ...prev, password: event.target.value }))
                }
                placeholder="Leave empty to keep current"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="edit-notes">Notes</Label>
              <Textarea
                id="edit-notes"
                rows={3}
                value={editForm.notes}
                onChange={(event) =>
                  setEditForm((prev) => ({ ...prev, notes: event.target.value }))
                }
              />
            </div>
            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setEditOpen(false)}
                disabled={editSaving}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={editSaving}>
                {editSaving && <Loader2 className="h-4 w-4 animate-spin" />}
                Update Credential
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={deleteOpen} onOpenChange={setDeleteOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Credential?</DialogTitle>
            <DialogDescription>
              This will permanently remove{" "}
              <span className="font-medium text-foreground">
                {deleteTarget ? prettyProvider(deleteTarget.provider) : "this credential"}
              </span>
              . This action cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setDeleteOpen(false)}
              disabled={deleteSaving}
            >
              Cancel
            </Button>
            <Button variant="destructive" onClick={() => void confirmDelete()} disabled={deleteSaving}>
              {deleteSaving && <Loader2 className="h-4 w-4 animate-spin" />}
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
