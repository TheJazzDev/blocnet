'use client';

import { Badge } from '@/components/ui/badge';
import { ShieldAlert, ShieldCheck, User } from 'lucide-react';

export function GovernanceRolePills({ roles }: { roles: string[] }) {
  const items: ('owner' | 'dev' | 'admin' | 'moderator')[] = [];
  if (roles.includes('owner')) items.push('owner');
  if (roles.includes('dev')) items.push('dev');
  if (roles.includes('admin')) items.push('admin');
  if (roles.includes('moderator')) items.push('moderator');

  if (items.length === 0) {
    return (
      <Badge variant="secondary">
        <User className="mr-1 h-3 w-3" />
        None
      </Badge>
    );
  }

  return (
    <div className="flex flex-wrap gap-1.5">
      {items.map((role) => {
        if (role === 'owner') {
          return (
            <Badge
              key={role}
              className="border-primary/35 bg-primary/15 text-primary"
              variant="outline"
            >
              <ShieldCheck className="mr-1 h-3 w-3" />
              Owner
            </Badge>
          );
        }
        if (role === 'admin') {
          return (
            <Badge
              key={role}
              className="border-teal-500/35 bg-teal-500/10 text-teal-300"
              variant="outline"
            >
              <ShieldCheck className="mr-1 h-3 w-3" />
              Admin
            </Badge>
          );
        }
        if (role === 'dev') {
          return (
            <Badge
              key={role}
              className="border-cyan-500/35 bg-cyan-500/10 text-cyan-300"
              variant="outline"
            >
              <ShieldCheck className="mr-1 h-3 w-3" />
              Dev
            </Badge>
          );
        }
        return (
          <Badge
            key={role}
            className="border-amber-500/20 bg-amber-500/10 text-amber-400"
            variant="outline"
          >
            <ShieldAlert className="mr-1 h-3 w-3" />
            Moderator
          </Badge>
        );
      })}
    </div>
  );
}
