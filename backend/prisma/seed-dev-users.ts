import { RoleName } from '@prisma/client';

export type SeedUserKey =
  | 'owner'
  | 'adminAlpha'
  | 'adminDelta'
  | 'hunterNexa'
  | 'hunterSage'
  | 'memberRae'
  | 'memberKai'
  | 'memberMila';

export type SeedUser = {
  key: SeedUserKey;
  id: string;
  email: string;
  displayName: string;
  /** Applied only when the profile has no username yet. */
  username: string;
  roles: RoleName[];
};

const fallbackOwnerId = '8c244a0e-71f4-4a39-8d30-3d32f2ee9012';
const fallbackOwnerEmail = 'owner@blocknet.local';

/** The profiles `seed.dev.ts` creates, with the owner taken from the env. */
export function buildSeedDevUsers(env: NodeJS.ProcessEnv): SeedUser[] {
  const ownerUserId = env.OWNER_USER_ID?.trim() || fallbackOwnerId;
  const ownerEmail = env.OWNER_EMAIL?.trim() || fallbackOwnerEmail;

  return [
    {
      key: 'owner',
      id: ownerUserId,
      email: ownerEmail,
      displayName: 'Jazzdev',
      username: 'jazzdev',
      roles: [RoleName.owner, RoleName.user],
    },
    {
      key: 'adminAlpha',
      id: '2ebbe14f-8ab4-4bd4-a705-524192fca2e1',
      email: 'admin.alpha@blocknet.local',
      displayName: 'Admin Alpha',
      username: 'admin_alpha',
      roles: [RoleName.admin, RoleName.user],
    },
    {
      key: 'adminDelta',
      id: 'cb3f28af-b140-4e67-a495-378bc6f5f84f',
      email: 'admin.delta@blocknet.local',
      displayName: 'Admin Delta',
      username: 'admin_delta',
      roles: [RoleName.admin, RoleName.user],
    },
    {
      key: 'hunterNexa',
      id: '6d4ec119-bbb0-4d5a-b72e-569c5fb73916',
      email: 'hunter.nexa@blocknet.local',
      displayName: 'Hunter Nexa',
      username: 'hunter_nexa',
      roles: [RoleName.hunter, RoleName.user],
    },
    {
      key: 'hunterSage',
      id: '006a2a8f-f88c-4fc1-a895-0f8d6ceb35f4',
      email: 'hunter.sage@blocknet.local',
      displayName: 'Hunter Sage',
      username: 'hunter_sage',
      roles: [RoleName.hunter, RoleName.user],
    },
    {
      key: 'memberRae',
      id: 'af4976a2-93e8-4d6f-810d-b9171d8c2ea9',
      email: 'member.rae@blocknet.local',
      displayName: 'Member Rae',
      username: 'member_rae',
      roles: [RoleName.user],
    },
    {
      key: 'memberKai',
      id: '870f8a2f-4f5d-46de-abf3-f8ad58f99f8a',
      email: 'member.kai@blocknet.local',
      displayName: 'Member Kai',
      username: 'member_kai',
      roles: [RoleName.user],
    },
    {
      key: 'memberMila',
      id: '47efea2e-fb8c-487f-9683-fd4cb0e9df8d',
      email: 'member.mila@blocknet.local',
      displayName: 'Member Mila',
      username: 'member_mila',
      roles: [RoleName.user],
    },
  ];
}
