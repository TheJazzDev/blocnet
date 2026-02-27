"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { Loader2 } from "lucide-react";
import { useAdminSession } from "@/components/admin-shell";
import { apiFetch, clientApi, type AdminUserDetail } from "@/lib/api-client";
import { Card, CardContent } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";

// Import all section components
import { UserDetailsHeader } from "./components/UserDetailsHeader";
import { ProfileSection } from "./components/ProfileSection";
import { RolesSection } from "./components/RolesSection";
import { BadgesSection } from "./components/BadgesSection";
import { MiningSection } from "./components/MiningSection";
import { WalletSection } from "./components/WalletSection";
import { QuestsSection } from "./components/QuestsSection";
import { ActivitySection } from "./components/ActivitySection";
import { ProjectsSection } from "./components/ProjectsSection";
import { SocialSection } from "./components/SocialSection";
import { LifecycleSection } from "./components/LifecycleSection";
import { AuditLogSection } from "./components/AuditLogSection";

type AdminBadgeModel = {
  id: string;
  slug: string;
  name: string;
  isActive: boolean;
};

export default function UserManagementPage() {
  const session = useAdminSession();
  const params = useParams();
  const userId = (params?.id as string) ?? "";

  const [user, setUser] = useState<AdminUserDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [pendingConfirmation, setPendingConfirmation] = useState<{
    key: string;
    confirmText: string;
    submit: () => Promise<unknown>;
  } | null>(null);
  const [allBadges, setAllBadges] = useState<AdminBadgeModel[]>([]);
  const [activeTab, setActiveTab] = useState("overview");

  const actorRoles = session.effectiveRoles;
  const actorIsOwner = actorRoles.includes("owner");
  const actorIsAdmin = actorRoles.includes("admin");
  const canViewUsers =
    actorIsOwner || actorIsAdmin || actorRoles.includes("moderator");

  const targetRoles = user?.roles ?? [];
  const targetIsSelf = user?.id === session.id;
  const targetIsOwner = targetRoles.includes("owner");
  const targetIsAdmin = targetRoles.includes("admin");

  const canManageAccount =
    Boolean(user) &&
    (actorIsOwner || (actorIsAdmin && !targetIsOwner && !targetIsAdmin));
  const canEditProfile = canManageAccount && !Boolean(user?.isDeactivated);
  const canManageRoles =
    Boolean(user) &&
    !Boolean(user?.isDeactivated) &&
    (actorIsOwner || (actorIsAdmin && !targetIsOwner && !targetIsAdmin));

  useEffect(() => {
    if (!canViewUsers || !userId) {
      return;
    }

    async function load() {
      setLoading(true);
      setError(null);
      try {
        const [detail, badges] = await Promise.all([
          clientApi.getUser(userId),
          apiFetch<AdminBadgeModel[]>("/admin/badges?includeInactive=true"),
        ]);
        setUser(detail);
        setAllBadges((badges ?? []).filter((entry) => entry.isActive));
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Failed to load user details");
      } finally {
        setLoading(false);
      }
    }

    void load();
  }, [canViewUsers, userId]);

  async function refresh() {
    if (!userId) return;
    const detail = await clientApi.getUser(userId);
    setUser(detail);
  }

  async function executeAction(
    key: string,
    submit: () => Promise<unknown>,
  ) {
    setActionLoading(key);
    setActionError(null);
    try {
      await submit();
      await refresh();
    } catch (e: unknown) {
      setActionError(e instanceof Error ? e.message : "Action failed");
    } finally {
      setActionLoading(null);
    }
  }

  async function runAction(
    key: string,
    submit: () => Promise<unknown>,
    opts?: { confirmText?: string },
  ) {
    if (opts?.confirmText) {
      setPendingConfirmation({
        key,
        confirmText: opts.confirmText,
        submit,
      });
      setConfirmOpen(true);
      return;
    }
    await executeAction(key, submit);
  }

  async function confirmPendingAction() {
    if (!pendingConfirmation) return;
    await executeAction(pendingConfirmation.key, pendingConfirmation.submit);
    setConfirmOpen(false);
    setPendingConfirmation(null);
  }

  // Action handlers
  async function handleUpdateProfile(data: {
    displayName: string | null;
    username: string | null;
    avatarUrl: string | null;
    bio: string | null;
  }) {
    if (!user) return;
    await clientApi.updateUser(user.id, data);
    await refresh();
  }

  async function handleGrantBadge(badgeId: string, badgeName: string) {
    if (!user) return;
    await runAction(
      `grant-badge-${badgeId}`,
      () =>
        apiFetch(`/admin/badges/${badgeId}/grant`, {
          method: "POST",
          body: JSON.stringify({ userIdentifier: user.email }),
        }),
      {
        confirmText: `Grant "${badgeName}" to ${user.email}?`,
      },
    );
  }

  async function handleRevokeBadge(badgeSlug: string, badgeName: string) {
    if (!user) return;
    await runAction(
      `revoke-badge-${badgeSlug}`,
      () =>
        apiFetch(`/admin/badges/users/${user.id}/badges/${badgeSlug}`, {
          method: "DELETE",
        }),
      {
        confirmText: `Revoke "${badgeName}" from ${user.email}?`,
      },
    );
  }

  if (!canViewUsers) {
    return (
      <div className="py-16 text-center text-xs sm:text-sm text-destructive">
        You do not have permission to view user management.
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 className="h-5 w-5 animate-spin" />
      </div>
    );
  }

  if (!user) {
    return (
      <div className="p-4 sm:p-6 space-y-4">
        <p className="text-xs sm:text-sm text-destructive">{error ?? "User not found."}</p>
      </div>
    );
  }

  return (
    <div className="space-y-4 sm:space-y-6 pb-8">
      {/* Sticky Header */}
      <UserDetailsHeader
        user={user}
        actorIsOwner={actorIsOwner}
        canManageAccount={canManageAccount}
        targetIsSelf={targetIsSelf}
        actionLoading={actionLoading}
        onRefresh={refresh}
        onDeactivate={() =>
          runAction(
            "deactivate",
            () => clientApi.deleteUser(user.id),
            { confirmText: `Deactivate ${user.email}? This will soft-delete the account.` },
          )
        }
        onReactivate={() =>
          runAction(
            "reactivate",
            () => clientApi.reactivateUser(user.id),
            { confirmText: `Reactivate ${user.email}?` },
          )
        }
        onHardDelete={() =>
          runAction(
            "hard-delete",
            () => clientApi.hardDeleteUser(user.id),
            {
              confirmText: `Permanently hard delete ${user.email}? This action CANNOT be undone and will remove all user data.`,
            },
          )
        }
      />

      {/* Action Error Display */}
      {actionError && (
        <Card className="border-red-500/30 bg-red-500/5">
          <CardContent className="pt-6 text-xs sm:text-sm text-red-300">
            {actionError}
          </CardContent>
        </Card>
      )}

      {/* Tabbed Content */}
      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList className="grid w-full grid-cols-4 lg:grid-cols-7 gap-1">
          <TabsTrigger value="overview" className="text-xs sm:text-sm">
            Overview
          </TabsTrigger>
          <TabsTrigger value="roles-badges" className="text-xs sm:text-sm">
            Roles & Badges
          </TabsTrigger>
          <TabsTrigger value="financial" className="text-xs sm:text-sm">
            Financial
          </TabsTrigger>
          <TabsTrigger value="mining-quests" className="text-xs sm:text-sm">
            Mining & Quests
          </TabsTrigger>
          <TabsTrigger value="activity" className="text-xs sm:text-sm">
            Activity
          </TabsTrigger>
          <TabsTrigger value="social" className="text-xs sm:text-sm">
            Social
          </TabsTrigger>
          <TabsTrigger value="system" className="text-xs sm:text-sm">
            System
          </TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4 sm:space-y-6 mt-4 sm:mt-6">
          <ProfileSection
            user={user}
            canEdit={canEditProfile}
            onUpdate={handleUpdateProfile}
          />
          <LifecycleSection user={user} />
        </TabsContent>

        {/* Roles & Badges Tab */}
        <TabsContent value="roles-badges" className="space-y-4 sm:space-y-6 mt-4 sm:mt-6">
          <RolesSection
            user={user}
            actorRoles={actorRoles}
            actorIsOwner={actorIsOwner}
            targetIsSelf={targetIsSelf}
            canManageRoles={canManageRoles}
            actionLoading={actionLoading}
            onPromoteToOwner={() =>
              runAction(
                "grant-owner",
                () => clientApi.promoteToOwner(user.id),
                { confirmText: `Grant Owner role to ${user.email}?` },
              )
            }
            onDemoteOwner={() =>
              runAction(
                "revoke-owner",
                () => clientApi.demoteOwner(user.id),
                { confirmText: `Revoke Owner role from ${user.email}?` },
              )
            }
            onPromoteToCoreTeam={() =>
              runAction(
                "grant-core-team",
                () => clientApi.promoteToCoreTeam(user.id),
                { confirmText: `Grant Core Team role to ${user.email}?` },
              )
            }
            onDemoteCoreTeam={() =>
              runAction(
                "revoke-core-team",
                () => clientApi.demoteCoreTeam(user.id),
                { confirmText: `Revoke Core Team role from ${user.email}?` },
              )
            }
            onPromoteToAdmin={() =>
              runAction(
                "grant-admin",
                () => clientApi.promoteToAdmin(user.id),
                { confirmText: `Grant Admin role to ${user.email}?` },
              )
            }
            onDemoteAdmin={() =>
              runAction(
                "revoke-admin",
                () => clientApi.demoteAdmin(user.id),
                { confirmText: `Revoke Admin role from ${user.email}?` },
              )
            }
            onPromoteToModerator={() =>
              runAction(
                "grant-moderator",
                () => clientApi.promoteToModerator(user.id),
                { confirmText: `Grant Moderator role to ${user.email}?` },
              )
            }
            onDemoteModerator={() =>
              runAction(
                "revoke-moderator",
                () => clientApi.demoteModerator(user.id),
                { confirmText: `Revoke Moderator role from ${user.email}?` },
              )
            }
            onPromoteToHunter={() =>
              runAction(
                "grant-hunter",
                () => clientApi.promoteToHunter(user.id),
                { confirmText: `Grant Hunter role to ${user.email}?` },
              )
            }
            onDemoteHunter={() =>
              runAction(
                "revoke-hunter",
                () => clientApi.demoteHunter(user.id),
                { confirmText: `Revoke Hunter role from ${user.email}?` },
              )
            }
          />
          <BadgesSection
            user={user}
            allBadges={allBadges}
            canManage={canManageAccount}
            actionLoading={actionLoading}
            onGrantBadge={handleGrantBadge}
            onRevokeBadge={handleRevokeBadge}
          />
        </TabsContent>

        {/* Financial Tab */}
        <TabsContent value="financial" className="space-y-4 sm:space-y-6 mt-4 sm:mt-6">
          <WalletSection user={user} />
        </TabsContent>

        {/* Mining & Quests Tab */}
        <TabsContent value="mining-quests" className="space-y-4 sm:space-y-6 mt-4 sm:mt-6">
          <MiningSection userId={user.id} />
          <QuestsSection userId={user.id} />
        </TabsContent>

        {/* Activity Tab */}
        <TabsContent value="activity" className="space-y-4 sm:space-y-6 mt-4 sm:mt-6">
          <ActivitySection user={user} />
          <ProjectsSection userId={user.id} />
        </TabsContent>

        {/* Social Tab */}
        <TabsContent value="social" className="space-y-4 sm:space-y-6 mt-4 sm:mt-6">
          <SocialSection user={user} />
        </TabsContent>

        {/* System Tab */}
        <TabsContent value="system" className="space-y-4 sm:space-y-6 mt-4 sm:mt-6">
          <AuditLogSection userId={user.id} />
        </TabsContent>
      </Tabs>

      <Dialog
        open={confirmOpen}
        onOpenChange={(nextOpen) => {
          setConfirmOpen(nextOpen);
          if (!nextOpen) {
            setPendingConfirmation(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Action</DialogTitle>
            <DialogDescription>
              {pendingConfirmation?.confirmText ?? "Please confirm this action."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setConfirmOpen(false)}
              disabled={Boolean(actionLoading)}
            >
              Cancel
            </Button>
            <Button
              variant={
                pendingConfirmation?.key.includes("revoke") ||
                pendingConfirmation?.key.includes("delete") ||
                pendingConfirmation?.key.includes("deactivate")
                  ? "destructive"
                  : "default"
              }
              onClick={() => void confirmPendingAction()}
              disabled={!pendingConfirmation || Boolean(actionLoading)}
            >
              {actionLoading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
