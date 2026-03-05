export type BlocnetLinkType =
  | 'update'
  | 'project'
  | 'community'
  | 'notifications'
  | 'settings_notifications';

const BASE_URL = 'https://blocnet.app';
const OPEN_PATH = '/open';

function normalizePath(path: string): string {
  const trimmed = path.trim();
  if (!trimmed) return '/';
  const normalized = trimmed.startsWith('/') ? trimmed : `/${trimmed}`;
  if (normalized === '/notification') return '/notifications';
  if (normalized === '/settings/notification') {
    return '/settings/notifications';
  }
  return normalized;
}

function buildOpenLink(path: string): string {
  const normalized = normalizePath(path);
  return `${BASE_URL}${OPEN_PATH}?path=${encodeURIComponent(normalized)}`;
}

function convertSchemeToPath(raw: string): string | null {
  const trimmed = raw.trim();
  if (!trimmed) return null;

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    try {
      const uri = new URL(trimmed);
      if (
        uri.hostname === 'blocnet.app' ||
        uri.hostname === 'www.blocnet.app' ||
        uri.hostname === 'app.blocnet.app' ||
        uri.hostname === 'app.blocknet.app'
      ) {
        return normalizePath(`${uri.pathname}${uri.search}`);
      }
      return trimmed;
    } catch {
      return trimmed;
    }
  }

  const stripped = trimmed
    .replace(/^io\.blocnet\.app:\/\//i, '')
    .replace(/^blocnet:\/\//i, '');
  return normalizePath(stripped);
}

export function buildBlocnetLink(type: BlocnetLinkType, id?: string): string {
  const normalizedId = id?.trim();
  switch (type) {
    case 'update':
      return buildOpenLink(
        normalizedId ? `/updates/${normalizedId}` : '/updates',
      );
    case 'project':
      return buildOpenLink(
        normalizedId ? `/projects/${normalizedId}` : '/projects',
      );
    case 'community':
      return buildOpenLink(
        normalizedId ? `/community/${normalizedId}` : '/community',
      );
    case 'settings_notifications':
      return buildOpenLink('/settings/notifications');
    case 'notifications':
    default:
      return buildOpenLink('/notifications');
  }
}

export function buildBlocnetLinkFromDeeplink(deeplink?: string | null): string {
  const normalized = convertSchemeToPath(deeplink ?? '');
  if (!normalized) {
    return buildBlocnetLink('notifications');
  }
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }
  return buildOpenLink(normalized);
}
