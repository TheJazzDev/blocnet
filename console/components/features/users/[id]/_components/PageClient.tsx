"use client";

import { useParams } from "next/navigation";
import { Loader2 } from "lucide-react";
import { useAdminSession } from "@/components/admin-shell";
import { clientApi } from "@/lib/api-client";
import { Card, CardContent } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { UserDetailsHeader } from "../components/UserDetailsHeader";
import { ProfileSection } from "../components/ProfileSection";
import { LevelSection } from "../components/LevelSection";
import { RolesBadgesTab } from "../components/RolesBadgesTab";
import { MiningSection } from "../components/MiningSection";
import { WalletSection } from "../components/WalletSection";
import { QuestsSection } from "../components/QuestsSection";
import { ActivitySection } from "../components/ActivitySection";
import { ProjectsSection } from "../components/ProjectsSection";
import { SocialSection } from "../components/SocialSection";
import { LifecycleSection } from "../components/LifecycleSection";
import { AuditLogSection } from "../components/AuditLogSection";
import { ReferralSupportSection } from "../components/ReferralSupportSection";
import { UserConfirmDialog } from "../components/UserConfirmDialog";
import { useUserManagementPage } from "../_hooks/use-user-management-page";
import {
  UNIMPLEMENTED_SECTIONS_VISIBLE,
  USER_DETAIL_TABS,
  isUserDetailTabVisible,
} from "./user-detail-tabs";

const TAB_CONTENT_CLASS = "mt-4 space-y-4 sm:mt-6 sm:space-y-6";

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
  const activeTab = isUserDetailTabVisible(state.activeTab)
    ? state.activeTab
    : USER_DETAIL_TABS[0].value;

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

      <Tabs value={activeTab} onValueChange={state.setActiveTab} className="w-full">
        {/* Scrolls sideways instead of wrapping into misaligned rows (F-05). */}
        <TabsList className="flex h-auto w-full justify-start gap-1 overflow-x-auto whitespace-nowrap [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          {USER_DETAIL_TABS.map((tab) => (
            <TabsTrigger
              key={tab.value}
              value={tab.value}
              className="shrink-0 text-xs sm:text-sm"
            >
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>

        <TabsContent value="overview" className={TAB_CONTENT_CLASS}>
          <ProfileSection
            user={user}
            canEdit={state.canEditProfile}
            onUpdate={state.handleUpdateProfile}
          />
          <LevelSection level={user.currentLevel ?? null} />
          {UNIMPLEMENTED_SECTIONS_VISIBLE && <LifecycleSection user={user} />}
        </TabsContent>

        <TabsContent value="roles-badges" className={TAB_CONTENT_CLASS}>
          <RolesBadgesTab user={user} state={state} />
        </TabsContent>

        <TabsContent value="financial" className={TAB_CONTENT_CLASS}>
          <WalletSection user={user} />
        </TabsContent>

        <TabsContent value="mining-quests" className={TAB_CONTENT_CLASS}>
          <MiningSection user={user} />
          <ReferralSupportSection
            user={user}
            canManage={state.canManageAccount}
            onBound={state.refresh}
          />
          <QuestsSection user={user} />
        </TabsContent>

        {UNIMPLEMENTED_SECTIONS_VISIBLE && (
          <>
            <TabsContent value="activity" className={TAB_CONTENT_CLASS}>
              <ActivitySection user={user} />
              <ProjectsSection userId={user.id} />
            </TabsContent>

            <TabsContent value="social" className={TAB_CONTENT_CLASS}>
              <SocialSection user={user} />
            </TabsContent>

            <TabsContent value="system" className={TAB_CONTENT_CLASS}>
              <AuditLogSection userId={user.id} />
            </TabsContent>
          </>
        )}
      </Tabs>

      <UserConfirmDialog
        open={state.confirmOpen}
        confirmText={state.pendingConfirmation?.confirmText ?? null}
        actionKey={state.pendingConfirmation?.key ?? null}
        loading={Boolean(state.actionLoading)}
        onOpenChange={(nextOpen) => {
          state.setConfirmOpen(nextOpen);
          if (!nextOpen) {
            state.setPendingConfirmation(null);
          }
        }}
        onConfirm={() => void state.confirmPendingAction()}
      />
    </div>
  );
}
