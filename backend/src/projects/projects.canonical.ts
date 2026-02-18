import { BadRequestException } from '@nestjs/common';

export function toSlug(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-');
}

export function normalizeName(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function normalizeSymbol(symbol?: string): string | undefined {
  if (!symbol) return undefined;
  const next = symbol.trim().toUpperCase();
  return next.length > 0 ? next : undefined;
}

export function toWebsiteDomain(rawUrl?: string): string | undefined {
  if (!rawUrl || rawUrl.trim() === '') return undefined;

  try {
    const url = new URL(rawUrl.trim());
    const hostname = url.hostname.trim().toLowerCase();
    const normalized = hostname.startsWith('www.')
      ? hostname.slice(4)
      : hostname;
    return normalized || undefined;
  } catch {
    throw new BadRequestException('Invalid websiteUrl');
  }
}
