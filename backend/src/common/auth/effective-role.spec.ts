import { AppRole } from '../enums/role.enum';
import {
  getAdminGovernanceRole,
  resolveEffectiveRoles,
} from './effective-role';

describe('effective-role resolver', () => {
  it('resolves top governance role by priority', () => {
    expect(
      getAdminGovernanceRole([AppRole.COMMUNITY_MODERATOR, AppRole.DEV]),
    ).toBe(AppRole.DEV);
    expect(
      getAdminGovernanceRole([
        AppRole.COMMUNITY_MODERATOR,
        AppRole.OWNER,
        AppRole.DEV,
        AppRole.ADMIN,
      ]),
    ).toBe(AppRole.OWNER);
  });

  it('allows owner to downscope to dev and admin', () => {
    const ownerToDev = resolveEffectiveRoles([AppRole.OWNER], AppRole.DEV);
    expect(ownerToDev.actingAsRole).toBe(AppRole.DEV);
    expect(ownerToDev.effectiveRoles).toEqual([AppRole.DEV]);

    const ownerToAdmin = resolveEffectiveRoles(
      [AppRole.OWNER, AppRole.HUNTER],
      AppRole.ADMIN,
    );
    expect(ownerToAdmin.actingAsRole).toBe(AppRole.ADMIN);
    expect(ownerToAdmin.realRoles).toEqual([AppRole.OWNER, AppRole.HUNTER]);
    expect(ownerToAdmin.effectiveRoles).toEqual([
      AppRole.HUNTER,
      AppRole.ADMIN,
    ]);
  });

  it('does not allow admin to downscope below admin governance', () => {
    const adminToModerator = resolveEffectiveRoles(
      [AppRole.ADMIN, AppRole.HUNTER],
      AppRole.COMMUNITY_MODERATOR,
    );
    expect(adminToModerator.actingAsRole).toBeNull();
    expect(adminToModerator.effectiveRoles).toEqual([
      AppRole.ADMIN,
      AppRole.HUNTER,
    ]);
  });

  it('allows dev to downscope to admin only', () => {
    const devToAdmin = resolveEffectiveRoles(
      [AppRole.DEV, AppRole.HUNTER],
      AppRole.ADMIN,
    );
    expect(devToAdmin.actingAsRole).toBe(AppRole.ADMIN);
    expect(devToAdmin.effectiveRoles).toEqual([AppRole.HUNTER, AppRole.ADMIN]);
  });

  it('blocks upward simulation and invalid role values', () => {
    const moderatorToAdmin = resolveEffectiveRoles(
      [AppRole.COMMUNITY_MODERATOR],
      AppRole.ADMIN,
    );
    expect(moderatorToAdmin.actingAsRole).toBeNull();
    expect(moderatorToAdmin.effectiveRoles).toEqual([
      AppRole.COMMUNITY_MODERATOR,
    ]);

    const invalidRole = resolveEffectiveRoles([AppRole.OWNER], 'super_admin');
    expect(invalidRole.actingAsRole).toBeNull();
    expect(invalidRole.effectiveRoles).toEqual([AppRole.OWNER]);
  });
});
