import { AppRole } from '../enums/role.enum';
import {
  getAdminGovernanceRole,
  resolveEffectiveRoles,
} from './effective-role';

describe('effective-role resolver', () => {
  it('resolves top governance role by priority', () => {
    expect(
      getAdminGovernanceRole([AppRole.MODERATOR, AppRole.ADMIN]),
    ).toBe(AppRole.ADMIN);
    expect(
      getAdminGovernanceRole([
        AppRole.MODERATOR,
        AppRole.OWNER,
        AppRole.ADMIN,
      ]),
    ).toBe(AppRole.OWNER);
  });

  it('allows owner to downscope to admin and moderator', () => {
    const ownerToAdmin = resolveEffectiveRoles(
      [AppRole.OWNER, AppRole.HUNTER],
      AppRole.ADMIN,
    );
    expect(ownerToAdmin.actingAsRole).toBe(AppRole.ADMIN);
    expect(ownerToAdmin.realRoles).toEqual([AppRole.OWNER, AppRole.HUNTER]);
    expect(ownerToAdmin.effectiveRoles).toEqual([AppRole.HUNTER, AppRole.ADMIN]);

    const ownerToModerator = resolveEffectiveRoles(
      [AppRole.OWNER],
      AppRole.MODERATOR,
    );
    expect(ownerToModerator.actingAsRole).toBe(AppRole.MODERATOR);
    expect(ownerToModerator.effectiveRoles).toEqual([AppRole.MODERATOR]);
  });

  it('allows admin to downscope to moderator only', () => {
    const adminToModerator = resolveEffectiveRoles(
      [AppRole.ADMIN, AppRole.HUNTER],
      AppRole.MODERATOR,
    );
    expect(adminToModerator.actingAsRole).toBe(AppRole.MODERATOR);
    expect(adminToModerator.effectiveRoles).toEqual([
      AppRole.HUNTER,
      AppRole.MODERATOR,
    ]);
  });

  it('blocks upward simulation and invalid role values', () => {
    const moderatorToAdmin = resolveEffectiveRoles(
      [AppRole.MODERATOR],
      AppRole.ADMIN,
    );
    expect(moderatorToAdmin.actingAsRole).toBeNull();
    expect(moderatorToAdmin.effectiveRoles).toEqual([AppRole.MODERATOR]);

    const invalidRole = resolveEffectiveRoles([AppRole.OWNER], 'super_admin');
    expect(invalidRole.actingAsRole).toBeNull();
    expect(invalidRole.effectiveRoles).toEqual([AppRole.OWNER]);
  });
});
