export const DEFAULT_PAGE_SIZE = 30;
export const MAX_PAGE_SIZE = 100;

export interface PaginationResult {
  limit: number;
  offset: number;
}

export function normalizePagination(
  offset?: number,
  limit?: number,
  defaultLimit = DEFAULT_PAGE_SIZE,
  maxLimit = MAX_PAGE_SIZE,
): PaginationResult {
  const safeLimit =
    Number.isFinite(limit) && typeof limit === 'number'
      ? Math.min(Math.max(limit, 1), maxLimit)
      : defaultLimit;
  const safeOffset =
    Number.isFinite(offset) && typeof offset === 'number'
      ? Math.max(offset, 0)
      : 0;

  return { limit: safeLimit, offset: safeOffset };
}
