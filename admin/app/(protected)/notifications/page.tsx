"use client";

import { FormEvent, useState } from "react";
import { Loader2, Search, Send, X } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { PageHeader } from "@/components/page-header";
import { useAdminSession } from "@/components/admin-shell";
import { clientApi } from "@/lib/api-client";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

type BroadcastTarget = "all" | "hunters" | "users" | "specific";

interface SelectedUser {
  id: string;
  displayName: string | null;
  email: string;
}

const TARGET_OPTIONS: { value: BroadcastTarget; label: string; description: string }[] = [
  { value: "all", label: "All Users", description: "Every registered user" },
  { value: "hunters", label: "Hunters & Admins", description: "Users with hunter, admin, or owner role" },
  { value: "users", label: "Regular Users", description: "Users with only the base user role" },
  { value: "specific", label: "Specific People", description: "Search and pick individual users" },
];

interface BroadcastResult {
  insertedCount: number;
  sentCount: number;
  failureCount: number;
  recipientCount: number;
  skipped: boolean;
}

export default function NotificationsPage() {
  const session = useAdminSession();

  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [target, setTarget] = useState<BroadcastTarget>("all");
  const [selectedUsers, setSelectedUsers] = useState<SelectedUser[]>([]);

  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<SelectedUser[]>([]);
  const [searching, setSearching] = useState(false);

  const [confirmOpen, setConfirmOpen] = useState(false);
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<BroadcastResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const canSend = session.roles.some((r) => r === "admin" || r === "owner");

  const [searched, setSearched] = useState(false);

  async function handleSearch(q?: string) {
    const query = (q ?? searchQuery).trim();
    if (query.length < 2) return;
    setSearching(true);
    setSearched(false);
    try {
      const res = await clientApi.listUsers({ q: query, limit: 10 });
      setSearchResults(
        (res.data ?? []).map((u: any) => ({
          id: u.id,
          displayName: u.displayName ?? null,
          email: u.email,
        })),
      );
    } catch {
      setSearchResults([]);
    } finally {
      setSearching(false);
      setSearched(true);
    }
  }

  function addUser(user: SelectedUser) {
    if (!selectedUsers.find((u) => u.id === user.id)) {
      setSelectedUsers((prev) => [...prev, user]);
    }
    setSearchQuery("");
    setSearchResults([]);
    setSearched(false);
  }

  function removeUser(id: string) {
    setSelectedUsers((prev) => prev.filter((u) => u.id !== id));
  }

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!canSend || !title.trim() || !body.trim()) return;
    if (target === "specific" && selectedUsers.length === 0) return;
    setError(null);
    setResult(null);
    setConfirmOpen(true);
  }

  async function confirmSend() {
    setSending(true);
    setError(null);
    try {
      const res = await clientApi.broadcastNotification({
        title: title.trim(),
        body: body.trim(),
        target,
        userIds: target === "specific" ? selectedUsers.map((u) => u.id) : undefined,
      });
      setResult(res);
      setTitle("");
      setBody("");
      setSelectedUsers([]);
      setTarget("all");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to send notification");
    } finally {
      setSending(false);
      setConfirmOpen(false);
    }
  }

  const selectedTargetOption = TARGET_OPTIONS.find((o) => o.value === target)!;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Push Notifications"
        description="Broadcast notifications to users via push and in-app delivery."
      />

      {!canSend && (
        <Card className="border-amber-500/30 bg-amber-500/5">
          <CardContent className="pt-6 text-sm text-amber-200">
            Sending notifications requires admin or owner role.
          </CardContent>
        </Card>
      )}

      {result && (
        <Card className="border-green-500/30 bg-green-500/5">
          <CardContent className="pt-6">
            <p className="text-sm font-medium text-green-400">Notification sent successfully</p>
            <div className="mt-2 flex flex-wrap gap-3 text-xs text-muted-foreground">
              <span>Recipients: <strong className="text-foreground">{result.recipientCount}</strong></span>
              <span>Push sent: <strong className="text-foreground">{result.sentCount}</strong></span>
              {result.failureCount > 0 && (
                <span>Push failed: <strong className="text-destructive">{result.failureCount}</strong></span>
              )}
              <span>In-app created: <strong className="text-foreground">{result.insertedCount}</strong></span>
              {result.skipped && <span className="text-amber-400">FCM skipped (not configured)</span>}
            </div>
          </CardContent>
        </Card>
      )}

      {error && (
        <Card className="border-destructive/30 bg-destructive/5">
          <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
        </Card>
      )}

      <div className="grid gap-6 lg:grid-cols-3">
        {/* Compose form */}
        <div className="lg:col-span-2">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Compose</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-sm font-medium">Title</label>
                  <Input
                    value={title}
                    onChange={(e) => setTitle(e.target.value)}
                    placeholder="Notification title"
                    maxLength={100}
                    disabled={!canSend}
                  />
                  <p className="text-xs text-muted-foreground text-right">{title.length}/100</p>
                </div>

                <div className="space-y-1.5">
                  <label className="text-sm font-medium">Message</label>
                  <Textarea
                    value={body}
                    onChange={(e) => setBody(e.target.value)}
                    placeholder="Notification body"
                    maxLength={500}
                    rows={3}
                    disabled={!canSend}
                  />
                  <p className="text-xs text-muted-foreground text-right">{body.length}/500</p>
                </div>

                {/* Target selector */}
                <div className="space-y-1.5">
                  <label className="text-sm font-medium">Audience</label>
                  <div className="grid grid-cols-2 gap-2">
                    {TARGET_OPTIONS.map((opt) => (
                      <button
                        key={opt.value}
                        type="button"
                        onClick={() => setTarget(opt.value)}
                        disabled={!canSend}
                        className={`rounded-lg border p-3 text-left transition-colors ${
                          target === opt.value
                            ? "border-primary bg-primary/10 text-primary"
                            : "border-border bg-card text-muted-foreground hover:border-primary/40 hover:text-foreground"
                        }`}
                      >
                        <p className="text-sm font-medium">{opt.label}</p>
                        <p className="text-xs mt-0.5 opacity-70">{opt.description}</p>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Specific user search */}
                {target === "specific" && (
                  <div className="space-y-2">
                    <label className="text-sm font-medium">Add recipients</label>
                    <div className="flex gap-2">
                      <div className="relative flex-1">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                        <Input
                          value={searchQuery}
                          onChange={(e) => {
                            setSearchQuery(e.target.value);
                            setSearched(false);
                            setSearchResults([]);
                          }}
                          onKeyDown={(e) => {
                            if (e.key === "Enter") {
                              e.preventDefault();
                              handleSearch();
                            }
                          }}
                          placeholder="Name, username or email — press Enter to search"
                          className="pl-9"
                          disabled={!canSend}
                        />
                      </div>
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        disabled={!canSend || searching || searchQuery.trim().length < 2}
                        onClick={() => handleSearch()}
                        className="shrink-0"
                      >
                        {searching ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          "Search"
                        )}
                      </Button>
                    </div>

                    {searchResults.length > 0 && (
                      <div className="rounded-lg border bg-popover shadow-md overflow-hidden">
                        {searchResults.map((user) => (
                          <button
                            key={user.id}
                            type="button"
                            onClick={() => addUser(user)}
                            className="w-full flex items-center gap-3 px-3 py-2 text-left hover:bg-accent transition-colors"
                          >
                            <div className="h-7 w-7 rounded-full bg-primary/20 flex items-center justify-center text-xs font-bold text-primary shrink-0">
                              {(user.displayName ?? user.email)[0].toUpperCase()}
                            </div>
                            <div className="min-w-0">
                              <p className="text-sm font-medium truncate">
                                {user.displayName ?? "—"}
                              </p>
                              <p className="text-xs text-muted-foreground truncate">{user.email}</p>
                            </div>
                          </button>
                        ))}
                      </div>
                    )}

                    {searched && searchResults.length === 0 && (
                      <p className="text-xs text-muted-foreground px-1">
                        No users found for &quot;{searchQuery}&quot;.
                      </p>
                    )}

                    {selectedUsers.length > 0 && (
                      <div className="flex flex-wrap gap-2">
                        {selectedUsers.map((user) => (
                          <Badge key={user.id} variant="secondary" className="gap-1.5 pr-1">
                            {user.displayName ?? user.email}
                            <button
                              type="button"
                              onClick={() => removeUser(user.id)}
                              className="rounded-full hover:bg-destructive/20 p-0.5"
                            >
                              <X className="h-3 w-3" />
                            </button>
                          </Badge>
                        ))}
                      </div>
                    )}
                  </div>
                )}

                <Button
                  type="submit"
                  disabled={
                    !canSend ||
                    !title.trim() ||
                    !body.trim() ||
                    (target === "specific" && selectedUsers.length === 0)
                  }
                  className="w-full"
                >
                  <Send className="h-4 w-4" />
                  Send Notification
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>

        {/* Preview */}
        <div>
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Preview</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="rounded-xl border bg-card p-4 shadow-sm space-y-1">
                <div className="flex items-center gap-2 mb-2">
                  <div className="h-6 w-6 rounded-md bg-primary/20 flex items-center justify-center">
                    <span className="text-[10px] font-bold text-primary">B</span>
                  </div>
                  <span className="text-xs font-medium text-muted-foreground">Blocnet</span>
                  <span className="text-xs text-muted-foreground ml-auto">now</span>
                </div>
                <p className="text-sm font-semibold leading-tight">
                  {title || <span className="text-muted-foreground italic">Notification title</span>}
                </p>
                <p className="text-xs text-muted-foreground leading-relaxed">
                  {body || <span className="italic">Notification body message</span>}
                </p>
              </div>

              <div className="mt-4 space-y-2 text-xs text-muted-foreground">
                <div className="flex justify-between">
                  <span>Audience</span>
                  <span className="font-medium text-foreground">{selectedTargetOption.label}</span>
                </div>
                {target === "specific" && (
                  <div className="flex justify-between">
                    <span>Recipients</span>
                    <span className="font-medium text-foreground">{selectedUsers.length} selected</span>
                  </div>
                )}
                <div className="flex justify-between">
                  <span>Delivery</span>
                  <span className="font-medium text-foreground">Push + In-app</span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Confirm dialog */}
      <Dialog open={confirmOpen} onOpenChange={setConfirmOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Send notification?</DialogTitle>
            <DialogDescription>
              This will send a push notification and create an in-app notification for{" "}
              <strong>
                {target === "specific"
                  ? `${selectedUsers.length} selected user${selectedUsers.length !== 1 ? "s" : ""}`
                  : selectedTargetOption.label.toLowerCase()}
              </strong>
              . This cannot be undone.
            </DialogDescription>
          </DialogHeader>
          <div className="rounded-lg border bg-muted/40 p-3 space-y-1">
            <p className="text-sm font-semibold">{title}</p>
            <p className="text-xs text-muted-foreground">{body}</p>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmOpen(false)} disabled={sending}>
              Cancel
            </Button>
            <Button onClick={confirmSend} disabled={sending}>
              {sending && <Loader2 className="h-4 w-4 animate-spin" />}
              Confirm & Send
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
