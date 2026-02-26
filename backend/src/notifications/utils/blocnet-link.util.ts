export type BlocnetLinkType =
  | 'update'
  | 'project'
  | 'community'
  | 'notifications'
  | 'settings_notifications';

const BASE_URL = 'https://blocnet.app';

export function buildBlocnetLink(type: BlocnetLinkType, id?: string): string {
  const normalizedId = id?.trim();
  switch (type) {
    case 'update':
      return normalizedId
        ? `${BASE_URL}/updates/${normalizedId}`
        : `${BASE_URL}/updates`;
    case 'project':
      return normalizedId
        ? `${BASE_URL}/projects/${normalizedId}`
        : `${BASE_URL}/projects`;
    case 'community':
      return normalizedId
        ? `${BASE_URL}/community/${normalizedId}`
        : `${BASE_URL}/community`;
    case 'settings_notifications':
      return `${BASE_URL}/settings/notifications`;
    case 'notifications':
    default:
      return `${BASE_URL}/notifications`;
  }
}
