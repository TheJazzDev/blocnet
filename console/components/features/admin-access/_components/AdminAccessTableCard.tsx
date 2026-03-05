'use client';

import { ChevronLeft, ChevronRight, Loader2 } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import type { AdminUser } from '@/lib/api-client';
import { AccountStatusBadge } from './AccountStatusBadge';
import { GovernanceRolePills } from './RolePills';
import { GovernanceAction, getInitials } from './admin-access-types';

type AdminAccessTableCardProps = {
  users: AdminUser[];
  sessionId: string;
  loading: boolean;
  error: string | null;
  actionUserId: string | null;
  actorIsOwner: boolean;
  actorCanManageDevs: boolean;
  actorCanManageAdmins: boolean;
  pageStart: number;
  pageEnd: number;
  total: number;
  canPrev: boolean;
  canNext: boolean;
  onPrevPage: () => void;
  onNextPage: () => void;
  onAction: (user: AdminUser, action: GovernanceAction) => void;
};

export function AdminAccessTableCard({
  users,
  sessionId,
  loading,
  error,
  actionUserId,
  actorIsOwner,
  actorCanManageDevs,
  actorCanManageAdmins,
  pageStart,
  pageEnd,
  total,
  canPrev,
  canNext,
  onPrevPage,
  onNextPage,
  onAction,
}: AdminAccessTableCardProps) {
  return (
    <Card>
      <CardContent className='pt-6'>
        {loading ? (
          <LoadingSpinner className='py-10' />
        ) : error ? (
          <p className='py-8 text-center text-sm text-destructive'>{error}</p>
        ) : users.length === 0 ? (
          <p className='py-8 text-center text-sm text-muted-foreground'>
            No users found.
          </p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Member</TableHead>
                <TableHead>Governance Role</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className='w-[320px]'>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {users.map((user) => {
                const targetIsSelf = user.id === sessionId;
                const hasOwner = user.roles.includes('owner');
                const hasDev = user.roles.includes('dev');
                const hasAdmin = user.roles.includes('admin');
                const actionDisabled = actionUserId === user.id;
                const disabled = targetIsSelf || user.isDeactivated || actionDisabled;

                return (
                  <TableRow key={user.id}>
                    <TableCell>
                      <div className='min-w-0'>
                        <p className='truncate font-medium'>
                          {user.displayName ?? user.email.split('@')[0]}
                        </p>
                        <p className='truncate text-xs text-muted-foreground'>
                          {user.email}
                          {user.username ? ` · @${user.username}` : ''}
                        </p>
                        <p className='truncate text-[11px] text-muted-foreground'>
                          {getInitials(user.displayName, user.email)} · {user.id}
                        </p>
                      </div>
                    </TableCell>
                    <TableCell>
                      <GovernanceRolePills roles={user.roles} />
                    </TableCell>
                    <TableCell>
                      <AccountStatusBadge isDeactivated={user.isDeactivated} />
                    </TableCell>
                    <TableCell>
                      <div className='flex flex-wrap gap-2'>
                        {actorIsOwner && (
                          <ActionButton
                            active={hasOwner}
                            disabled={disabled}
                            actionDisabled={actionDisabled}
                            onClick={() => onAction(user, hasOwner ? 'revoke_owner' : 'grant_owner')}
                            activeLabel='Revoke Owner'
                            inactiveLabel='Grant Owner'
                          />
                        )}
                        {actorCanManageDevs && (
                          <ActionButton
                            active={hasDev}
                            disabled={disabled}
                            actionDisabled={actionDisabled}
                            onClick={() => onAction(user, hasDev ? 'revoke_dev' : 'grant_dev')}
                            activeLabel='Revoke Dev'
                            inactiveLabel='Grant Dev'
                          />
                        )}
                        {actorCanManageAdmins && (
                          <ActionButton
                            active={hasAdmin}
                            disabled={disabled}
                            actionDisabled={actionDisabled}
                            onClick={() => onAction(user, hasAdmin ? 'revoke_admin' : 'grant_admin')}
                            activeLabel='Revoke Admin'
                            inactiveLabel='Grant Admin'
                          />
                        )}
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        )}

        <div className='mt-4 flex flex-col items-start justify-between gap-3 text-sm text-muted-foreground md:flex-row md:items-center'>
          <p>
            Showing {pageStart}-{pageEnd} of {total}
          </p>
          <div className='flex items-center gap-2'>
            <Button variant='outline' size='sm' disabled={!canPrev || loading} onClick={onPrevPage}>
              <ChevronLeft className='h-4 w-4' />
              Prev
            </Button>
            <Button variant='outline' size='sm' disabled={!canNext || loading} onClick={onNextPage}>
              Next
              <ChevronRight className='h-4 w-4' />
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function ActionButton({
  active,
  disabled,
  actionDisabled,
  onClick,
  activeLabel,
  inactiveLabel,
}: {
  active: boolean;
  disabled: boolean;
  actionDisabled: boolean;
  onClick: () => void;
  activeLabel: string;
  inactiveLabel: string;
}) {
  return (
    <Button
      variant={active ? 'destructive' : 'outline'}
      size='sm'
      disabled={disabled}
      onClick={onClick}
    >
      {actionDisabled ? <Loader2 className='mr-2 h-4 w-4 animate-spin' /> : null}
      {active ? activeLabel : inactiveLabel}
    </Button>
  );
}
