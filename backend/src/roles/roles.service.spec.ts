import { AppRole } from '../common/enums/role.enum';
import { RolesService } from './roles.service';

describe('RolesService roles matrix', () => {
  const service = new RolesService({} as any, {} as any);

  it('returns canonical capability matrix with expected role mappings', () => {
    const matrix = service.getRolesMatrix();

    expect(matrix.governanceRoles.map((entry) => entry.role)).toEqual([
      AppRole.OWNER,
      AppRole.ADMIN,
      AppRole.MODERATOR,
    ]);

    const capabilityMap = new Map(
      matrix.sections
        .flatMap((section) => section.capabilities)
        .map((capability) => [capability.key, capability.roles]),
    );

    expect(capabilityMap.get('access.roles.admin.manage')).toEqual([
      AppRole.OWNER,
    ]);
    expect(capabilityMap.get('wallet.withdrawals.review')).toEqual([
      AppRole.OWNER,
      AppRole.ADMIN,
    ]);
    expect(capabilityMap.get('access.applications.proposal.review')).toEqual([
      AppRole.OWNER,
      AppRole.ADMIN,
      AppRole.MODERATOR,
    ]);
    expect(capabilityMap.get('system.settings.mutate')).toEqual([
      AppRole.OWNER,
    ]);

    expect(matrix.spaceRoles).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ role: AppRole.USER }),
        expect.objectContaining({ role: AppRole.CORE_TEAM }),
        expect.objectContaining({ role: AppRole.HUNTER }),
      ]),
    );
  });
});
