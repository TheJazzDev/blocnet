'use client';

import { Badge } from '@/components/ui/badge';

export function AccountStatusBadge({ isDeactivated }: { isDeactivated: boolean }) {
  if (isDeactivated) {
    return <Badge className="bg-red-500/15 text-red-300">Deactivated</Badge>;
  }
  return <Badge className="bg-emerald-500/15 text-emerald-300">Active</Badge>;
}

