"use client";

import { useParams } from "next/navigation";
import { Loader2 } from "lucide-react";
import { useAdminSession } from "@/components/admin-shell";
import { clientApi } from "@/lib/api-client";
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
import { UserDetailsHeader } from "../components/UserDetailsHeader";
import { ProfileSection } from "../components/ProfileSection";
import { RolesSection } from "../components/RolesSection";
import { BadgesSection } from "../components/BadgesSection";
import { MiningSection } from "../components/MiningSection";
import { WalletSection } from "../components/WalletSection";
import { QuestsSection } from "../components/QuestsSection";
import { ActivitySection } from "../components/ActivitySection";
import { ProjectsSection } from "../components/ProjectsSection";
import { SocialSection } from "../components/SocialSection";
import { LifecycleSection } from "../components/LifecycleSection";
import { AuditLogSection } from "../components/AuditLogSection";
import { ReferralSupportSection } from "../components/ReferralSupportSection";
import { useUserManagementPage } from "../_hooks/use-user-management-page";

export default function UserManagementPageClient() {
  const session = useAdminSession();
  const params = useParams();
  const userId = (params?.id as string) ?? "";
  const state = useUserManagementPage(userId, session);

  if (!state.canViewUsers) {
    return (
      <div className="py-16 text-center text-xs text-destructive sm:text-sm">
        You do not have permission to view user management.
      </div>
    );
  }

  if (state.loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <Loader2 className="h-5 w-5 animate-spin" />
      </div>
    );
  }

  if (!state.user) {
    return (
      <div className="space-y-4 p-4 sm:p-6">
        <p className="text-xs text-destructive sm:text-sm">
          {state.error ?? "User not found."}
        </p>
      </div>
    );
  }

  const user = state.user;

  return (
    <div className="space-y-4 pb-8 sm:space-y-6">
      <UserDetailsHeader
        user={user}
        actorIsOwner={state.actorIsOwner}
        canManageAccount={state.canManageAccount}
        targetIsSelf={state.targetIsSelf}
        actionLoading={state.actionLoading}
        onRefresh={state.refresh}
        onDeactivate={() =>
          state.runAction("deactivate", () => clientApi.deleteUser(user.id), {
            confirmText: `Deactivate ${user.email}? This will soft-delete the account.`,
          })
        }
        onReactivate={() =>
          state.runAction("reactivate", () => clientApi.reactivateUser(user.id), {
            confirmText: `Reactivate ${user.email}?`,
          })
        }
        onHardDelete={() =>
          state.runAction("hard-delete", () => clientApi.hardDeleteUser(user.id), {
            confirmText:
              `Permanently hard delete ${user.email}? This action CANNOT be undone and will remove all user data.`,
          })
        }
      />

      {state.actionError && (
        <Card className="border-red-500/30 bg-red-500/5">
          <CardContent className="pt-6 text-xs text-red-300 sm:text-sm">
            {state.actionError}
          </CardContent>
        </Card>
      )}

      <Tabs
        value={state.activeTab}
        onValueChange={state.setActiveTab}
        className="w-full"
      >
        <TabsList className="grid w-full grid-cols-4 gap-1 lg:grid-cols-7">
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

        <TabsContent value="overview" className="mt-4 space-y-4 sm:mt-6 sm:space-y-6">
          <ProfileSection
            user={user}
            canEdit={state.canEditProfile}
            onUpdate={state.handleUpdateProfile}
          />
          <LifecycleSection user={user} />
        </TabsContent>

        <TabsContent value="roles-badges" className="mt-4 space-y-4 sm:mt-6 sm:space-y-6">
          <RolesSection
            user={user}
            actorRoles={state.actorRoles}
            actorIsOwner={state.actorIsOwner}
            targetIsSelf={state.targetIsSelf}
            canManageRoles={state.canManageRoles}
            actionLoading={state.actionLoading}
            onPromoteToOwner={() =>
              state.runAction("grant-owner", () => clientApi.promoteToOwner(user.id), {
                confirmText: `Grant Owner role to ${user.email}?`,
              })
            }
            onDemoteOwner={() =>
              state.runAction("revoke-owner", () => clientApi.demoteOwner(user.id), {
                confirmText: `Revoke Owner role from ${user.email}?`,
              })
            }
            onPromoteToCoreTeam={() =>
              state.runAction(
                "grant-core-team",
                () => clientApi.promoteToCoreTeam(user.id),
                { confirmText: `Grant Core Team role to ${user.email}?` },
              )
            }
            onDemoteCoreTeam={() =>
              state.runAction(
                "revoke-core-team",
                () => clientApi.demoteCoreTeam(user.id),
                { confirmText: `Revoke Core Team role from ${user.email}?` },
              )
            }
            onPromoteToAdmin={() =>
              state.runAction("grant-admin", () => clientApi.promoteToAdmin(user.id), {
                confirmText: `Grant Admin role to ${user.email}?`,
              })
            }
            onDemoteAdmin={() =>
              state.runAction("revoke-admin", () => clientApi.demoteAdmin(user.id), {
                confirmText: `Revoke Admin role from ${user.email}?`,
              })
            }
            onPromoteToCommunityAdmin={() =>
              state.runAction(
                "grant-community-admin",
                () => clientApi.promoteToCommunityAdmin(user.id),
                { confirmText: `Grant Community Admin role to ${user.email}?` },
              )
            }
            onDemoteCommunityAdmin={() =>
              state.runAction(
                "revoke-community-admin",
                () => clientApi.demoteCommunityAdmin(user.id),
                { confirmText: `Revoke Community Admin role from ${user.email}?` },
              )
            }
            onPromoteToCommunityModerator={() =>
              state.runAction(
                "grant-community-moderator",
                () => clientApi.promoteToCommunityModerator(user.id),
                {
                  confirmText: `Grant Community Moderator role to ${user.email}?`,
                },
              )
            }
            onDemoteCommunityModerator={() =>
              state.runAction(
                "revoke-community-moderator",
                () => clientApi.demoteCommunityModerator(user.id),
                {
                  confirmText: `Revoke Community Moderator role from ${user.email}?`,
                },
              )
            }
            onPromoteToHunter={() =>
              state.runAction("grant-hunter", () => clientApi.promoteToHunter(user.id), {
                confirmText: `Grant Hunter role to ${user.email}?`,
              })
            }
            onDemoteHunter={() =>
              state.runAction("revoke-hunter", () => clientApi.demoteHunter(user.id), {
                confirmText: `Revoke Hunter role from ${user.email}?`,
              })
            }
          />
          <BadgesSection
            user={user}
            allBadges={state.allBadges}
            canManage={state.canManageAccount}
            actionLoading={state.actionLoading}
            onGrantBadge={state.handleGrantBadge}
            onRevokeBadge={state.handleRevokeBadge}
          />
        </TabsContent>

        <TabsContent value="financial" className="mt-4 space-y-4 sm:mt-6 sm:space-y-6">
          <WalletSection user={user} />
        </TabsContent>

        <TabsContent value="mining-quests" className="mt-4 space-y-4 sm:mt-6 sm:space-y-6">
          <MiningSection user={user} />
          <ReferralSupportSection
            user={user}
            canManage={state.canManageAccount}
            onBound={state.refresh}
          />
          <QuestsSection user={user} />
        </TabsContent>

        <TabsContent value="activity" className="mt-4 space-y-4 sm:mt-6 sm:space-y-6">
          <ActivitySection user={user} />
          <ProjectsSection userId={user.id} />
        </TabsContent>

        <TabsContent value="social" className="mt-4 space-y-4 sm:mt-6 sm:space-y-6">
          <SocialSection user={user} />
        </TabsContent>

        <TabsContent value="system" className="mt-4 space-y-4 sm:mt-6 sm:space-y-6">
          <AuditLogSection userId={user.id} />
        </TabsContent>
      </Tabs>

      <Dialog
        open={state.confirmOpen}
        onOpenChange={(nextOpen) => {
          state.setConfirmOpen(nextOpen);
          if (!nextOpen) {
            state.setPendingConfirmation(null);
          }
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Action</DialogTitle>
            <DialogDescription>
              {state.pendingConfirmation?.confirmText ?? "Please confirm this action."}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => state.setConfirmOpen(false)}
              disabled={Boolean(state.actionLoading)}
            >
              Cancel
            </Button>
            <Button
              variant={
                state.pendingConfirmation?.key.includes("revoke") ||
                state.pendingConfirmation?.key.includes("delete") ||
                state.pendingConfirmation?.key.includes("deactivate")
                  ? "destructive"
                  : "default"
              }
              onClick={() => void state.confirmPendingAction()}
              disabled={!state.pendingConfirmation || Boolean(state.actionLoading)}
            >
              {state.actionLoading ? (
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              ) : null}
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
