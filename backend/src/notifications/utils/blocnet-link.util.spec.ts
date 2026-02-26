import { buildBlocnetLink } from './blocnet-link.util';

describe('buildBlocnetLink', () => {
  it('builds update/project/community/notification links', () => {
    expect(buildBlocnetLink('update', 'u1')).toBe(
      'https://blocnet.app/updates/u1',
    );
    expect(buildBlocnetLink('project', 'p1')).toBe(
      'https://blocnet.app/projects/p1',
    );
    expect(buildBlocnetLink('community', 'c1')).toBe(
      'https://blocnet.app/community/c1',
    );
    expect(buildBlocnetLink('notifications')).toBe(
      'https://blocnet.app/notifications',
    );
    expect(buildBlocnetLink('settings_notifications')).toBe(
      'https://blocnet.app/settings/notifications',
    );
  });
});
