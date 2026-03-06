'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { ChevronLeft, ChevronRight, Loader2, Search } from 'lucide-react';
import { useDebounce } from '@/lib/hooks';
import { useAdminSession } from '@/components/admin-shell';
import { clientApi, type AdminUser } from '@/lib/api-client';
import {
  canManageCommunityAdmins,
  canManageCommunityModerators,
} from '@/lib/rbac';
import { PageHeader } from '@/components/page-header';
import { Card, CardContent } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { AccountStatusBadge } from '@/components/features/admin-access/_components/AccountStatusBadge';

type CommunityRoleFilter = 'all' | 'community_admin' | 'community_moderator';
type StatusFilter = 'all' | 'active' | 'deactivated';
type CommunityRoleAction =
  | 'grant_community_admin'
  | 'revoke_community_admin'
  | 'grant_community_moderator'
  | 'revoke_community_moderator';

type PendingRoleAction = {
  user: AdminUser;
  action: CommunityRoleAction;
} | null;

export default function CommunityAccessPageClient() {
  const session = useAdminSession();
  const actorRoles = session.effectiveRoles;
  const actorCanManageCommunityAdmins = canManageCommunityAdmins(actorRoles);
  const actorCanManageCommunityModerators = canManageCommunityModerators(
    actorRoles,
  );

  const [searchInput, setSearchInput] = useState('');
  const [role, setRole] = useState<CommunityRoleFilter>('all');
  const [status, setStatus] = useState<StatusFilter>('active');
  const [limit, setLimit] = useState(25);
  const [offset, setOffset] = useState(0);
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [actionUserId, setActionUserId] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmError, setConfirmError] = useState<string | null>(null);
  const [confirmNote, setConfirmNote] = useState('');
  const [pendingAction, setPendingAction] = useState<PendingRoleAction>(null);

  const q = useDebounce(searchInput.trim(), 300);

  const loadUsers = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await clientApi.listUsers({
        limit,
        offset,
        role: role === 'all' ? undefined : role,
        status,
        q: q || undefined,
      });

      const data =
        role === 'all'
          ? response.data
          : response.data.filter((entry) => entry.roles.includes(role));

      setUsers(data);
      setTotal(response.total);
    } catch (e: unknown) {
      setUsers([]);
      setTotal(0);
      setError(
        e instanceof Error ? e.message : 'Failed to load community access users',
      );
    } finally {
      setIsLoading(false);
    }
  }, [limit, offset, q, role, status]);

  useEffect(() => {
    setOffset(0);
  }, [q, role, status, limit]);

  useEffect(() => {
    void loadUsers();
  }, [loadUsers]);

  const stats = useMemo(() => {
    const communityAdmins = users.filter((entry) =>
      entry.roles.includes('community_admin'),
    ).length;
    const communityModerators = users.filter((entry) =>
      entry.roles.includes('community_moderator'),
    ).length;
    return { communityAdmins, communityModerators };
  }, [users]);

  const pageStart = total === 0 ? 0 : offset + 1;
  const pageEnd = Math.min(offset + users.length, total);
  const canPrev = offset > 0;
  const canNext = offset + limit < total;

  const openConfirmDialog = (user: AdminUser, action: CommunityRoleAction) => {
    setPendingAction({ user, action });
    setConfirmError(null);
    setConfirmNote('');
    setConfirmOpen(true);
  };

  const closeConfirmDialog = () => {
    setConfirmOpen(false);
    setPendingAction(null);
    setConfirmError(null);
    setConfirmNote('');
  };

  const submitCommunityRoleAction = async () => {
    if (!pendingAction) return;
    setActionUserId(pendingAction.user.id);
    setConfirmError(null);
    try {
      switch (pendingAction.action) {
        case 'grant_community_admin':
          await clientApi.promoteToCommunityAdmin(
            pendingAction.user.id,
            confirmNote.trim() || undefined,
          );
          break;
        case 'revoke_community_admin':
          await clientApi.demoteCommunityAdmin(pendingAction.user.id);
          break;
        case 'grant_community_moderator':
          await clientApi.promoteToCommunityModerator(
            pendingAction.user.id,
            confirmNote.trim() || undefined,
          );
          break;
        case 'revoke_community_moderator':
          await clientApi.demoteCommunityModerator(pendingAction.user.id);
          break;
      }
      closeConfirmDialog();
      await loadUsers();
    } catch (e: unknown) {
      setConfirmError(
        e instanceof Error ? e.message : 'Failed to update community role',
      );
    } finally {
      setActionUserId(null);
    }
  };

  return (
    <div className='space-y-6'>
      <PageHeader
        title='Community Access'
        description='Manage community_admin and community_moderator role assignments.'>
        <Button variant='outline' size='sm' asChild>
          <Link href='/users'>Open Members Directory</Link>
        </Button>
        <Button variant='outline' size='sm' asChild>
          <Link href='/community'>Open Community Moderation</Link>
        </Button>
      </PageHeader>

      <div className='grid gap-4 sm:grid-cols-2 xl:grid-cols-3'>
        <MetricStat label='Total Results' value={total} />
        <MetricStat label='Community Admins (page)' value={stats.communityAdmins} />
        <MetricStat
          label='Community Moderators (page)'
          value={stats.communityModerators}
        />
      </div>

      <Card>
        <CardContent className='pt-6'>
          <div className='grid gap-3 md:grid-cols-5'>
            <div className='relative md:col-span-2'>
              <Search className='pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground' />
              <Input
                value={searchInput}
                onChange={(event) => setSearchInput(event.target.value)}
                className='pl-9'
                placeholder='Search by name, email, username, or user ID'
              />
            </div>
            <Select
              value={role}
              onValueChange={(next) => setRole(next as CommunityRoleFilter)}>
              <SelectTrigger>
                <SelectValue placeholder='Community role' />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value='all'>All users</SelectItem>
                <SelectItem value='community_admin'>Community admins only</SelectItem>
                <SelectItem value='community_moderator'>
                  Community moderators only
                </SelectItem>
              </SelectContent>
            </Select>
            <Select value={status} onValueChange={(next) => setStatus(next as StatusFilter)}>
              <SelectTrigger>
                <SelectValue placeholder='Status' />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value='active'>Active</SelectItem>
                <SelectItem value='deactivated'>Deactivated</SelectItem>
                <SelectItem value='all'>All statuses</SelectItem>
              </SelectContent>
            </Select>
            <Select value={String(limit)} onValueChange={(next) => setLimit(Number(next))}>
              <SelectTrigger>
                <SelectValue placeholder='Page size' />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value='25'>25 / page</SelectItem>
                <SelectItem value='50'>50 / page</SelectItem>
                <SelectItem value='100'>100 / page</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className='pt-6'>
          {isLoading ? (
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
                  <TableHead>Community Roles</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className='w-[360px]'>Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.map((user) => {
                  const hasCommunityAdmin = user.roles.includes('community_admin');
                  const hasCommunityModerator = user.roles.includes('community_moderator');
                  const actionDisabled = actionUserId === user.id;
                  const disabled = user.isDeactivated || actionDisabled;

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
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className='flex flex-wrap gap-1.5'>
                          {hasCommunityAdmin ? (
                            <span className='rounded-md border border-cyan-500/30 bg-cyan-500/12 px-2 py-0.5 text-[11px] font-semibold text-cyan-300'>
                              Community Admin
                            </span>
                          ) : null}
                          {hasCommunityModerator ? (
                            <span className='rounded-md border border-teal-500/30 bg-teal-500/12 px-2 py-0.5 text-[11px] font-semibold text-teal-300'>
                              Community Moderator
                            </span>
                          ) : null}
                          {!hasCommunityAdmin && !hasCommunityModerator ? (
                            <span className='text-xs text-muted-foreground'>None</span>
                          ) : null}
                        </div>
                      </TableCell>
                      <TableCell>
                        <AccountStatusBadge isDeactivated={user.isDeactivated} />
                      </TableCell>
                      <TableCell>
                        <div className='flex flex-wrap gap-2'>
                          {actorCanManageCommunityAdmins ? (
                            <Button
                              variant={hasCommunityAdmin ? 'destructive' : 'outline'}
                              size='sm'
                              disabled={disabled}
                              onClick={() =>
                                openConfirmDialog(
                                  user,
                                  hasCommunityAdmin
                                    ? 'revoke_community_admin'
                                    : 'grant_community_admin',
                                )
                              }>
                              {actionDisabled ? (
                                <Loader2 className='mr-2 h-4 w-4 animate-spin' />
                              ) : null}
                              {hasCommunityAdmin
                                ? 'Revoke Community Admin'
                                : 'Grant Community Admin'}
                            </Button>
                          ) : null}
                          {actorCanManageCommunityModerators ? (
                            <Button
                              variant={hasCommunityModerator ? 'destructive' : 'outline'}
                              size='sm'
                              disabled={disabled}
                              onClick={() =>
                                openConfirmDialog(
                                  user,
                                  hasCommunityModerator
                                    ? 'revoke_community_moderator'
                                    : 'grant_community_moderator',
                                )
                              }>
                              {actionDisabled ? (
                                <Loader2 className='mr-2 h-4 w-4 animate-spin' />
                              ) : null}
                              {hasCommunityModerator
                                ? 'Revoke Community Moderator'
                                : 'Grant Community Moderator'}
                            </Button>
                          ) : null}
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
              <Button
                variant='outline'
                size='sm'
                disabled={!canPrev || isLoading}
                onClick={() => setOffset(Math.max(offset - limit, 0))}>
                <ChevronLeft className='h-4 w-4' />
                Prev
              </Button>
              <Button
                variant='outline'
                size='sm'
                disabled={!canNext || isLoading}
                onClick={() => setOffset(offset + limit)}>
                Next
                <ChevronRight className='h-4 w-4' />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      <Dialog
        open={confirmOpen}
        onOpenChange={(nextOpen) => {
          setConfirmOpen(nextOpen);
          if (!nextOpen) closeConfirmDialog();
        }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Role Action</DialogTitle>
            <DialogDescription>
              {pendingAction
                ? `Apply ${pendingAction.action.replaceAll('_', ' ')} for ${pendingAction.user.email}?`
                : 'Confirm role action.'}
            </DialogDescription>
          </DialogHeader>

          {pendingAction?.action.startsWith('grant') ? (
            <div className='space-y-2'>
              <p className='text-sm text-muted-foreground'>
                Optional note for audit log
              </p>
              <Textarea
                rows={3}
                value={confirmNote}
                onChange={(event) => setConfirmNote(event.target.value)}
                placeholder='Reason/context for this role grant'
              />
            </div>
          ) : null}

          {confirmError ? (
            <p className='text-sm text-destructive'>{confirmError}</p>
          ) : null}

          <DialogFooter>
            <Button
              variant='outline'
              onClick={closeConfirmDialog}
              disabled={Boolean(actionUserId)}>
              Cancel
            </Button>
            <Button
              variant={
                pendingAction?.action.startsWith('revoke')
                  ? 'destructive'
                  : 'default'
              }
              onClick={() => void submitCommunityRoleAction()}
              disabled={!pendingAction || Boolean(actionUserId)}>
              {actionUserId ? <Loader2 className='mr-2 h-4 w-4 animate-spin' /> : null}
              Confirm
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function MetricStat({ label, value }: { label: string; value: number }) {
  return (
    <Card>
      <CardContent className='pt-6'>
        <p className='text-sm text-muted-foreground'>{label}</p>
        <p className='text-2xl font-bold'>{value}</p>
      </CardContent>
    </Card>
  );
}
