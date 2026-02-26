"use client";

import { useState } from "react";
import { Save, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import type { AdminUserDetail } from "@/lib/api-client";
import { PermissionGate } from "./PermissionGate";

type ProfileSectionProps = {
  user: AdminUserDetail;
  canEdit: boolean;
  onUpdate: (data: {
    displayName: string | null;
    username: string | null;
    avatarUrl: string | null;
    bio: string | null;
  }) => Promise<void>;
};

function fmtDate(value: string | null) {
  if (!value) return "—";
  try {
    return new Date(value).toLocaleString();
  } catch {
    return "—";
  }
}

export function ProfileSection({ user, canEdit, onUpdate }: ProfileSectionProps) {
  const [displayName, setDisplayName] = useState(user.displayName ?? "");
  const [username, setUsername] = useState(user.username ?? "");
  const [avatarUrl, setAvatarUrl] = useState(user.avatarUrl ?? "");
  const [bio, setBio] = useState(user.bio ?? "");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSave() {
    setSaving(true);
    setError(null);
    try {
      await onUpdate({
        displayName: displayName.trim() || null,
        username: username.trim().toLowerCase() || null,
        avatarUrl: avatarUrl.trim() || null,
        bio: bio.trim() || null,
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Failed to update profile");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-sm sm:text-base">Profile & Identity</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {error && (
          <div className="rounded-md bg-red-500/10 border border-red-500/30 p-3">
            <p className="text-xs sm:text-sm text-red-300">{error}</p>
          </div>
        )}

        {/* System Fields (Read-only) */}
        <div className="grid gap-3 sm:gap-4 sm:grid-cols-2">
          <div>
            <Label className="text-xs text-muted-foreground">User ID</Label>
            <p className="text-xs sm:text-sm font-mono mt-1 break-all">{user.id}</p>
          </div>
          <div>
            <Label className="text-xs text-muted-foreground">Email</Label>
            <p className="text-xs sm:text-sm mt-1">{user.email}</p>
          </div>
          <div>
            <Label className="text-xs text-muted-foreground">Joined</Label>
            <p className="text-xs sm:text-sm mt-1">{fmtDate(user.createdAt)}</p>
          </div>
          <div>
            <Label className="text-xs text-muted-foreground">Last Seen</Label>
            <p className="text-xs sm:text-sm mt-1">{fmtDate(user.createdAt)}</p>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Referral Information */}
        <div className="space-y-3">
          <h4 className="text-xs sm:text-sm font-semibold">Referral Information</h4>
          <div className="grid gap-3 sm:grid-cols-2">
            <div>
              <Label className="text-xs text-muted-foreground">Referral Code</Label>
              <p className="text-xs sm:text-sm font-mono mt-1">{user.referralCode ?? "—"}</p>
            </div>
            <div>
              <Label className="text-xs text-muted-foreground">Direct Referrals</Label>
              <p className="text-xs sm:text-sm mt-1">{user.counts.directReferrals}</p>
            </div>
            <div className="sm:col-span-2">
              <Label className="text-xs text-muted-foreground">Referred By</Label>
              <p className="text-xs sm:text-sm mt-1">
                {user.referredBy
                  ? `${user.referredBy.email} (Code: ${user.referredBy.referralCode ?? "—"})`
                  : "Direct signup"}
              </p>
              {user.referredAt && (
                <p className="text-xs text-muted-foreground mt-1">
                  Referred at: {fmtDate(user.referredAt)}
                </p>
              )}
            </div>
          </div>
        </div>

        <div className="border-t pt-4" />

        {/* Editable Fields */}
        <PermissionGate
          hasPermission={canEdit}
          requiredRole="Admin"
          reason="Admin access required to edit profile"
          showLock={false}
        >
          <div className="space-y-3">
            <h4 className="text-xs sm:text-sm font-semibold">Editable Fields</h4>
            <div className="grid gap-3">
              <div>
                <Label htmlFor="displayName" className="text-xs sm:text-sm">
                  Display Name
                </Label>
                <Input
                  id="displayName"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  disabled={!canEdit || saving}
                  className="text-xs sm:text-sm"
                />
              </div>
              <div>
                <Label htmlFor="username" className="text-xs sm:text-sm">
                  Username
                </Label>
                <div className="flex items-center gap-2">
                  <span className="text-xs sm:text-sm text-muted-foreground">@</span>
                  <Input
                    id="username"
                    value={username}
                    onChange={(e) => setUsername(e.target.value.toLowerCase())}
                    disabled={!canEdit || saving}
                    className="text-xs sm:text-sm"
                  />
                </div>
              </div>
              <div>
                <Label htmlFor="avatarUrl" className="text-xs sm:text-sm">
                  Avatar URL
                </Label>
                <Input
                  id="avatarUrl"
                  value={avatarUrl}
                  onChange={(e) => setAvatarUrl(e.target.value)}
                  disabled={!canEdit || saving}
                  className="text-xs sm:text-sm"
                  placeholder="https://..."
                />
              </div>
              <div>
                <Label htmlFor="bio" className="text-xs sm:text-sm">
                  Bio
                </Label>
                <Textarea
                  id="bio"
                  rows={3}
                  value={bio}
                  onChange={(e) => setBio(e.target.value)}
                  disabled={!canEdit || saving}
                  className="text-xs sm:text-sm resize-none"
                  placeholder="User bio..."
                />
              </div>
              <Button onClick={handleSave} disabled={!canEdit || saving} size="sm">
                {saving ? (
                  <Loader2 className="mr-2 h-3 w-3 sm:h-4 sm:w-4 animate-spin" />
                ) : (
                  <Save className="mr-2 h-3 w-3 sm:h-4 sm:w-4" />
                )}
                <span className="text-xs sm:text-sm">Save Changes</span>
              </Button>
            </div>
          </div>
        </PermissionGate>

        {!canEdit && (
          <p className="text-xs sm:text-sm text-muted-foreground">
            You have read-only access for this profile.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
