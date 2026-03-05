"use client";

import { useEffect, useMemo, useState } from "react";
import { Copy, Loader2, Plus, Trash2 } from "lucide-react";
import { useAdminSession } from "@/components/admin-shell";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { canMutateSettings } from "@/lib/rbac";
import { clientApi, type ClosedAlphaEmailRecord } from "@/lib/api-client";

export default function ClosedAlphaPageClient() {
  const session = useAdminSession();
  const canMutate = canMutateSettings(session.effectiveRoles);

  const [rows, setRows] = useState<ClosedAlphaEmailRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [mutating, setMutating] = useState(false);
  const [status, setStatus] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [emailDraft, setEmailDraft] = useState("");
  const [bulkEmailsDraft, setBulkEmailsDraft] = useState("");
  const [noteDraft, setNoteDraft] = useState("");

  const sortedRows = useMemo(
    () => [...rows].sort((left, right) => left.email.localeCompare(right.email)),
    [rows],
  );

  async function loadRows() {
    setLoading(true);
    setError(null);
    try {
      const response = await clientApi.listClosedAlphaEmails({
        limit: 200,
        offset: 0,
      });
      setRows(response.data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load allowlist.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadRows();
  }, []);

  function parseEmailInput(raw: string) {
    return Array.from(
      new Set(
        raw
          .split(/[\s,;]+/)
          .map((value) => value.trim().toLowerCase())
          .filter(Boolean),
      ),
    );
  }

  async function addEmail() {
    const email = emailDraft.trim();
    if (!email || mutating) return;

    setMutating(true);
    setStatus(null);
    setError(null);
    try {
      await clientApi.createClosedAlphaEmail({
        email,
        ...(noteDraft.trim().length > 0 ? { note: noteDraft.trim() } : {}),
      });
      setEmailDraft("");
      setNoteDraft("");
      setStatus("Email added to closed alpha allowlist.");
      await loadRows();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to add email.");
    } finally {
      setMutating(false);
    }
  }

  async function addBulkEmails() {
    const emails = parseEmailInput(bulkEmailsDraft);
    if (emails.length === 0 || mutating) return;

    setMutating(true);
    setStatus(null);
    setError(null);
    try {
      const result = await clientApi.createClosedAlphaEmailsBulk({
        emails,
        ...(noteDraft.trim().length > 0 ? { note: noteDraft.trim() } : {}),
      });
      setBulkEmailsDraft("");
      setEmailDraft("");
      setNoteDraft("");
      setStatus(`${result.totalProcessed} email(s) imported into allowlist.`);
      await loadRows();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to import emails.");
    } finally {
      setMutating(false);
    }
  }

  async function updateStatus(id: string, isActive: boolean) {
    if (mutating) return;
    setMutating(true);
    setStatus(null);
    setError(null);
    try {
      await clientApi.updateClosedAlphaEmailStatus(id, { isActive });
      setStatus("Allowlist status updated.");
      await loadRows();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to update status.");
    } finally {
      setMutating(false);
    }
  }

  async function removeEmail(id: string) {
    if (mutating) return;
    setMutating(true);
    setStatus(null);
    setError(null);
    try {
      await clientApi.deleteClosedAlphaEmail(id);
      setStatus("Allowlist email removed.");
      await loadRows();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to remove email.");
    } finally {
      setMutating(false);
    }
  }

  async function copyAllEmails() {
    if (sortedRows.length === 0) return;
    const payload = sortedRows.map((row) => row.email).join("\n");
    try {
      await navigator.clipboard.writeText(payload);
      setStatus(`Copied ${sortedRows.length} email(s).`);
      setError(null);
    } catch {
      setError("Failed to copy all emails. Please copy manually.");
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Closed Alpha"
        description="Manage tester email allowlist for mobile sign-in access."
      />

      {!canMutate && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Read-only mode. Owner/Admin roles are required to mutate allowlist entries.
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Add Allowlist Email</CardTitle>
          <CardDescription>
            Add one email or paste multiple emails at once.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="grid gap-3 md:grid-cols-[2fr_2fr_auto]">
            <div className="space-y-1.5">
              <Label>Email</Label>
              <Input
                placeholder="tester@domain.com"
                value={emailDraft}
                onChange={(event) => setEmailDraft(event.target.value)}
                disabled={!canMutate || mutating}
              />
            </div>
            <div className="space-y-1.5">
              <Label>Note (optional)</Label>
              <Input
                placeholder="QA cohort 1"
                value={noteDraft}
                onChange={(event) => setNoteDraft(event.target.value)}
                disabled={!canMutate || mutating}
              />
            </div>
            <div className="flex items-end">
              <Button
                onClick={() => void addEmail()}
                disabled={!canMutate || mutating || emailDraft.trim().length === 0}
              >
                {mutating ? (
                  <Loader2 className="h-4 w-4 animate-spin" />
                ) : (
                  <Plus className="h-4 w-4" />
                )}
                Add
              </Button>
            </div>
          </div>
          <div className="space-y-1.5">
            <Label>Bulk import emails</Label>
            <Textarea
              placeholder="Paste emails separated by newline, comma, space, or semicolon."
              value={bulkEmailsDraft}
              onChange={(event) => setBulkEmailsDraft(event.target.value)}
              disabled={!canMutate || mutating}
              rows={6}
            />
          </div>
          <div className="flex justify-end">
            <Button
              onClick={() => void addBulkEmails()}
              disabled={!canMutate || mutating || parseEmailInput(bulkEmailsDraft).length === 0}
            >
              {mutating ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Plus className="h-4 w-4" />
              )}
              Import all
            </Button>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <CardTitle className="text-base">Allowlist</CardTitle>
            <Button
              variant="outline"
              onClick={() => void copyAllEmails()}
              disabled={sortedRows.length === 0}
            >
              <Copy className="h-4 w-4" />
              Copy all emails
            </Button>
          </div>
          <CardDescription>{rows.length} email{rows.length === 1 ? "" : "s"} configured.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-3">
          {loading ? (
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <Loader2 className="h-4 w-4 animate-spin" />
              Loading allowlist...
            </div>
          ) : sortedRows.length === 0 ? (
            <p className="text-sm text-muted-foreground">No allowlist emails yet.</p>
          ) : (
            <div className="space-y-2">
              {sortedRows.map((row) => (
                <div
                  key={row.id}
                  className="flex flex-wrap items-center justify-between gap-3 rounded-md border border-border/60 p-3"
                >
                  <div className="min-w-0">
                    <p className="break-all text-sm font-medium">{row.email}</p>
                    <p className="text-xs text-muted-foreground">
                      {row.source} · {new Date(row.createdAt).toLocaleDateString()}
                      {row.note ? ` · ${row.note}` : ""}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Select
                      value={row.isActive ? "active" : "inactive"}
                      onValueChange={(value) =>
                        void updateStatus(row.id, value === "active")
                      }
                      disabled={!canMutate || mutating}
                    >
                      <SelectTrigger className="w-[124px]">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="active">Active</SelectItem>
                        <SelectItem value="inactive">Inactive</SelectItem>
                      </SelectContent>
                    </Select>
                    <Button
                      variant="ghost"
                      onClick={() => void removeEmail(row.id)}
                      disabled={!canMutate || mutating}
                    >
                      <Trash2 className="h-4 w-4" />
                      Remove
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {status ? <p className="text-xs text-emerald-300">{status}</p> : null}
          {error ? <p className="text-xs text-destructive">{error}</p> : null}
        </CardContent>
      </Card>
    </div>
  );
}
