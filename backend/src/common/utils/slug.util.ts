export function normalizeSlug(input: string, fallback = 'item'): string {
  const normalized = input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '');

  return normalized || fallback;
}

export async function generateUniqueSlug(params: {
  source: string;
  desiredSlug?: string | null;
  fallback?: string;
  exists: (slug: string) => Promise<boolean>;
}): Promise<string> {
  const fallback = params.fallback ?? 'item';
  const base = normalizeSlug(params.desiredSlug || params.source, fallback);

  if (!(await params.exists(base))) {
    return base;
  }

  let suffix = 2;
  while (suffix <= 5000) {
    const candidate = `${base}-${suffix}`;
    if (!(await params.exists(candidate))) {
      return candidate;
    }
    suffix += 1;
  }

  throw new Error(`Could not generate unique slug for base "${base}"`);
}
