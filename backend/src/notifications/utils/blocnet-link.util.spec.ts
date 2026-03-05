import {
  buildBlocnetLink,
  buildBlocnetLinkFromDeeplink,
} from './blocnet-link.util';

describe('buildBlocnetLink', () => {
  it('builds update/project/community/notification links', () => {
    expect(buildBlocnetLink('update', 'u1')).toBe(
      'https://blocnet.app/open?path=%2Fupdates%2Fu1',
    );
    expect(buildBlocnetLink('project', 'p1')).toBe(
      'https://blocnet.app/open?path=%2Fprojects%2Fp1',
    );
    expect(buildBlocnetLink('community', 'c1')).toBe(
      'https://blocnet.app/open?path=%2Fcommunity%2Fc1',
    );
    expect(buildBlocnetLink('notifications')).toBe(
      'https://blocnet.app/open?path=%2Fnotifications',
    );
    expect(buildBlocnetLink('settings_notifications')).toBe(
      'https://blocnet.app/open?path=%2Fsettings%2Fnotifications',
    );
  });

  it('builds open links from deeplinks', () => {
    expect(buildBlocnetLinkFromDeeplink('/updates/u1')).toBe(
      'https://blocnet.app/open?path=%2Fupdates%2Fu1',
    );
    expect(buildBlocnetLinkFromDeeplink('io.blocnet.app://updates/u1')).toBe(
      'https://blocnet.app/open?path=%2Fupdates%2Fu1',
    );
    expect(
      buildBlocnetLinkFromDeeplink('https://blocnet.app/community/c1'),
    ).toBe('https://blocnet.app/open?path=%2Fcommunity%2Fc1');
    expect(buildBlocnetLinkFromDeeplink('https://example.com/somewhere')).toBe(
      'https://example.com/somewhere',
    );
    expect(
      buildBlocnetLinkFromDeeplink('https://app.blocnet.app/notification'),
    ).toBe('https://blocnet.app/open?path=%2Fnotifications');
    expect(
      buildBlocnetLinkFromDeeplink('https://app.blocknet.app/notification'),
    ).toBe('https://blocnet.app/open?path=%2Fnotifications');
  });
});
