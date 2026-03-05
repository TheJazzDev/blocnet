import { describe, expect, it } from 'vitest';
import {
  buildLocalRolesMatrix,
  canAccessAdminPanel,
  canManageAdmins,
  canManageCommunityAdmins,
  canManageCommunityModerators,
  canMutateWallet,
  diffRoleCapabilities,
  getRoleViewOptions,
  resolveEffectiveRoles,
} from './rbac';

describe('rbac', () => {
  it('allows only owner/dev/admin into admin console', () => {
    expect(canAccessAdminPanel(['owner'])).toBe(true);
    expect(canAccessAdminPanel(['dev'])).toBe(true);
    expect(canAccessAdminPanel(['admin'])).toBe(true);
    expect(canAccessAdminPanel(['community_admin'])).toBe(false);
    expect(canAccessAdminPanel(['community_moderator'])).toBe(false);
    expect(canAccessAdminPanel(['user'])).toBe(false);
  });

  it('allows owner/dev to manage admins', () => {
    expect(canManageAdmins(['owner'])).toBe(true);
    expect(canManageAdmins(['dev'])).toBe(true);
    expect(canManageAdmins(['admin'])).toBe(false);
  });

  it('allows owner/dev/admin to manage community roles and wallet mutation', () => {
    expect(canManageCommunityAdmins(['owner'])).toBe(true);
    expect(canManageCommunityAdmins(['dev'])).toBe(true);
    expect(canManageCommunityAdmins(['admin'])).toBe(true);
    expect(canManageCommunityAdmins(['community_admin'])).toBe(false);

    expect(canManageCommunityModerators(['owner'])).toBe(true);
    expect(canManageCommunityModerators(['dev'])).toBe(true);
    expect(canManageCommunityModerators(['admin'])).toBe(true);
    expect(canManageCommunityModerators(['community_moderator'])).toBe(false);

    expect(canMutateWallet(['owner'])).toBe(true);
    expect(canMutateWallet(['dev'])).toBe(true);
    expect(canMutateWallet(['admin'])).toBe(true);
  });

  it('resolves effective roles for view mode without allowing escalation', () => {
    expect(resolveEffectiveRoles(['owner', 'hunter'], 'dev')).toEqual([
      'hunter',
      'dev',
    ]);
    expect(resolveEffectiveRoles(['owner', 'hunter'], 'admin')).toEqual([
      'hunter',
      'admin',
    ]);
    expect(resolveEffectiveRoles(['dev', 'hunter'], 'admin')).toEqual([
      'hunter',
      'admin',
    ]);
    expect(resolveEffectiveRoles(['admin', 'hunter'], 'community_moderator')).toEqual([
      'admin',
      'hunter',
    ]);
    expect(resolveEffectiveRoles(['community_moderator'], 'admin')).toEqual([
      'community_moderator',
    ]);
    expect(resolveEffectiveRoles(['owner'], 'super')).toEqual(['owner']);
  });

  it('returns correct role-view options', () => {
    expect(getRoleViewOptions(['owner'])).toEqual(['owner', 'dev', 'admin']);
    expect(getRoleViewOptions(['dev'])).toEqual(['dev', 'admin']);
    expect(getRoleViewOptions(['admin'])).toEqual(['admin']);
    expect(getRoleViewOptions(['community_moderator'])).toEqual([]);
    expect(getRoleViewOptions(['hunter'])).toEqual([]);
  });

  it('computes role capability diffs', () => {
    const diff = diffRoleCapabilities('admin', 'owner');
    expect(
      diff.gained.some((entry) => entry.key === 'access.users.reactivate'),
    ).toBe(true);
    expect(diff.removed).toHaveLength(0);
  });

  it('builds local role matrix with governance and space roles', () => {
    const matrix = buildLocalRolesMatrix();
    expect(matrix.governanceRoles.map((entry) => entry.role)).toEqual([
      'owner',
      'dev',
      'admin',
    ]);
    expect(matrix.spaceRoles.map((entry) => entry.role)).toEqual([
      'user',
      'core_team',
      'community_admin',
      'community_moderator',
      'hunter',
    ]);
    expect(matrix.sections.some((entry) => entry.id === 'access')).toBe(true);
  });
});
