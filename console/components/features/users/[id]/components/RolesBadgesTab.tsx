"use client";

import { clientApi, type AdminUserDetail } from "@/lib/api-client";
import { RolesSection } from "./RolesSection";
import { BadgesSection } from "./BadgesSection";
import type { useUserManagementPage } from "../_hooks/use-user-management-page";

type PageState = ReturnType<typeof useUserManagementPage>;

type RolesBadgesTabProps = {
  user: AdminUserDetail;
  state: PageState;
};

type RoleAction = {
  key: string;
  label: string;
  submit: (userId: string) => Promise<unknown>;
};

const ROLE_ACTIONS = {
  grantOwner: { key: "grant-owner", label: "Grant Owner role to", submit: clientApi.promoteToOwner },
  revokeOwner: { key: "revoke-owner", label: "Revoke Owner role from", submit: clientApi.demoteOwner },
  grantCoreTeam: { key: "grant-core-team", label: "Grant Core Team role to", submit: clientApi.promoteToCoreTeam },
  revokeCoreTeam: { key: "revoke-core-team", label: "Revoke Core Team role from", submit: clientApi.demoteCoreTeam },
  grantAdmin: { key: "grant-admin", label: "Grant Admin role to", submit: clientApi.promoteToAdmin },
  revokeAdmin: { key: "revoke-admin", label: "Revoke Admin role from", submit: clientApi.demoteAdmin },
  grantCommunityAdmin: { key: "grant-community-admin", label: "Grant Community Admin role to", submit: clientApi.promoteToCommunityAdmin },
  revokeCommunityAdmin: { key: "revoke-community-admin", label: "Revoke Community Admin role from", submit: clientApi.demoteCommunityAdmin },
  grantCommunityModerator: { key: "grant-community-moderator", label: "Grant Community Moderator role to", submit: clientApi.promoteToCommunityModerator },
  revokeCommunityModerator: { key: "revoke-community-moderator", label: "Revoke Community Moderator role from", submit: clientApi.demoteCommunityModerator },
  grantHunter: { key: "grant-hunter", label: "Grant Hunter role to", submit: clientApi.promoteToHunter },
  revokeHunter: { key: "revoke-hunter", label: "Revoke Hunter role from", submit: clientApi.demoteHunter },
} satisfies Record<string, RoleAction>;

export function RolesBadgesTab({ user, state }: RolesBadgesTabProps) {
  const run = (action: RoleAction) => () =>
    state.runAction(action.key, () => action.submit(user.id), {
      confirmText: `${action.label} ${user.email}?`,
    });

  return (
    <>
      <RolesSection
        user={user}
        actorRoles={state.actorRoles}
        actorIsOwner={state.actorIsOwner}
        targetIsSelf={state.targetIsSelf}
        canManageRoles={state.canManageRoles}
        actionLoading={state.actionLoading}
        onPromoteToOwner={run(ROLE_ACTIONS.grantOwner)}
        onDemoteOwner={run(ROLE_ACTIONS.revokeOwner)}
        onPromoteToCoreTeam={run(ROLE_ACTIONS.grantCoreTeam)}
        onDemoteCoreTeam={run(ROLE_ACTIONS.revokeCoreTeam)}
        onPromoteToAdmin={run(ROLE_ACTIONS.grantAdmin)}
        onDemoteAdmin={run(ROLE_ACTIONS.revokeAdmin)}
        onPromoteToCommunityAdmin={run(ROLE_ACTIONS.grantCommunityAdmin)}
        onDemoteCommunityAdmin={run(ROLE_ACTIONS.revokeCommunityAdmin)}
        onPromoteToCommunityModerator={run(ROLE_ACTIONS.grantCommunityModerator)}
        onDemoteCommunityModerator={run(ROLE_ACTIONS.revokeCommunityModerator)}
        onPromoteToHunter={run(ROLE_ACTIONS.grantHunter)}
        onDemoteHunter={run(ROLE_ACTIONS.revokeHunter)}
      />
      <BadgesSection
        user={user}
        allBadges={state.allBadges}
        canManage={state.canManageAccount}
        actionLoading={state.actionLoading}
        onGrantBadge={state.handleGrantBadge}
        onRevokeBadge={state.handleRevokeBadge}
      />
    </>
  );
}
