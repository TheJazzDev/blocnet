"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { clientApi, type AdminSocialCredential } from "@/lib/api-client";
import {
  EMPTY_FORM,
  normalizeOptional,
  toEditForm,
  type CredentialFormState,
} from "../_lib/social-credentials";

export function useSocialCredentials(
  effectiveRoles: string[],
  realRoles: string[],
) {
  const router = useRouter();
  const isOwner = useMemo(
    () => realRoles.includes("owner") || effectiveRoles.includes("owner"),
    [effectiveRoles, realRoles],
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
  const [deleteTarget, setDeleteTarget] = useState<AdminSocialCredential | null>(
    null,
  );
  const [deleteSaving, setDeleteSaving] = useState(false);

  async function loadRows() {
    setLoading(true);
    setError(null);
    setStatus(null);
    try {
      const payload = await clientApi.listSocialCredentials();
      setRows(payload.data ?? []);
    } catch (err) {
      setRows([]);
      setError(err instanceof Error ? err.message : "Failed to load social credentials");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!isOwner) {
      router.replace("/dashboard");
      return;
    }
    void loadRows();
  }, [isOwner, router]);

  useEffect(() => {
    if (!isOwner) {
      setLoading(false);
    }
  }, [isOwner]);

  function resetMessages() {
    setError(null);
    setStatus(null);
  }

  function openCreateDialog() {
    setCreateForm(EMPTY_FORM);
    setCreateOpen(true);
    resetMessages();
  }

  function openEditDialog(row: AdminSocialCredential) {
    setEditTarget(row);
    setEditForm(toEditForm(row));
    setEditOpen(true);
    resetMessages();
  }

  function openDeleteDialog(row: AdminSocialCredential) {
    setDeleteTarget(row);
    setDeleteOpen(true);
    resetMessages();
  }

  async function submitCreate(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!isOwner || createSaving) return;
    if (!createForm.provider.trim() || !createForm.password) {
      setError("Provider and password are required.");
      return;
    }

    setCreateSaving(true);
    resetMessages();
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
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to create credential");
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
    resetMessages();
    try {
      const updated = await clientApi.updateSocialCredential(editTarget.id, {
        provider: editForm.provider.trim(),
        accountLabel: normalizeOptional(editForm.accountLabel),
        username: normalizeOptional(editForm.username),
        password: editForm.password ? editForm.password : undefined,
        notes: normalizeOptional(editForm.notes),
      });
      setRows((prev) =>
        prev.map((entry) => (entry.id === updated.id ? updated : entry)),
      );
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
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update credential");
    } finally {
      setEditSaving(false);
    }
  }

  async function confirmDelete() {
    if (!isOwner || deleteSaving || !deleteTarget) return;
    setDeleteSaving(true);
    resetMessages();
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
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to delete credential");
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
      setRevealed((prev) => ({ ...prev, [row.id]: payload.password }));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to reveal password");
    } finally {
      setBusyId((prev) => (prev === row.id ? null : prev));
    }
  }

  return {
    isOwner,
    rows,
    loading,
    status,
    error,
    revealed,
    busyId,
    createOpen,
    setCreateOpen,
    createForm,
    setCreateForm,
    createSaving,
    editOpen,
    setEditOpen,
    editForm,
    setEditForm,
    editSaving,
    deleteOpen,
    setDeleteOpen,
    deleteTarget,
    deleteSaving,
    openCreateDialog,
    openEditDialog,
    openDeleteDialog,
    submitCreate,
    submitEdit,
    confirmDelete,
    toggleReveal,
  };
}
