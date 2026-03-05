'use client';

import { useMemo } from 'react';
import Link from 'next/link';
import { PageHeader } from '@/components/page-header';
import { Button } from '@/components/ui/button';
import { ConfirmRoleDialog } from './ConfirmRoleDialog';
import { useAdminSession } from '@/components/admin-shell';
import { clientApi, type AdminUser } from '@/lib/api-client';
import { canManageAdmins, canManageDevs } from '@/lib/rbac';
import { AdminAccessFilters } from './AdminAccessFilters';
import { AdminAccessTableCard } from './AdminAccessTableCard';
import { useAdminAccess } from '@/lib/hooks';
import {
  GovernanceAction,
} from './admin-access-types';

export default function AdminAccessPage() {
  const session = useAdminSession();
  const actorRoles = session.effectiveRoles;
  const actorIsOwner = actorRoles.includes('owner');
  const actorCanManageDevs = canManageDevs(actorRoles);
  const actorCanManageAdmins = canManageAdmins(actorRoles);

  const {
    users,
    total,
    isLoading,
    error,
    searchInput,
    role,
    status,
    limit,
    offset,
    actionUserId,
    confirmOpen,
    confirmError,
    confirmNote,
    pendingAction,
    setSearchInput,
    setRole,
    setStatus,
    setLimit,
    setOffset,
    setActionUserId,
    setError,
    openConfirmDialog,
    closeConfirmDialog,
    setConfirmError,
    setConfirmNote,
    loadUsers,
  } = useAdminAccess();

  const stats = useMemo(() => {
    const owners = users.filter((entry) => entry.roles.includes('owner')).length;
    const admins = users.filter((entry) => entry.roles.includes('admin')).length;
    const devs = users.filter((entry) => entry.roles.includes('dev')).length;
    return { owners, devs, admins };
  }, [users]);

  const pageStart = total === 0 ? 0 : offset + 1;
  const pageEnd = Math.min(offset + users.length, total);
  const canPrev = offset > 0;
  const canNext = offset + limit < total;

  async function submitGovernanceAction(
    user: AdminUser,
    action: GovernanceAction,
    note?: string,
  ) {
    setActionUserId(user.id);
    setError(null);
    try {
      switch (action) {
        case 'grant_owner':
          await clientApi.promoteToOwner(user.id, note || undefined);
          break;
        case 'revoke_owner':
          await clientApi.demoteOwner(user.id);
          break;
        case 'grant_dev':
          await clientApi.promoteToDev(user.id, note || undefined);
          break;
        case 'revoke_dev':
          await clientApi.demoteDev(user.id);
          break;
        case 'grant_admin':
          await clientApi.promoteToAdmin(user.id, note || undefined);
          break;
        case 'revoke_admin':
          await clientApi.demoteAdmin(user.id);
          break;
      }
      await loadUsers();
    } catch (e: unknown) {
      setError(
        e instanceof Error ? e.message : 'Failed to update admin access role',
      );
      throw e;
    } finally {
      setActionUserId(null);
    }
  }

  async function confirmGovernanceAction() {
    if (!pendingAction) return;
    setConfirmError(null);
    try {
      await submitGovernanceAction(
        pendingAction.user,
        pendingAction.action,
        pendingAction.action.startsWith('grant')
          ? confirmNote.trim() || undefined
          : undefined,
      );
      closeConfirmDialog();
    } catch (e: unknown) {
      setConfirmError(
        e instanceof Error ? e.message : 'Failed to apply role action',
      );
    }
  }

  return (
    <div className='space-y-6'>
      <PageHeader
        title='Admin Panel Access'
        description='Manage governance roles for panel operators only: owner, dev, and admin.'>
        <Button variant='outline' size='sm' asChild>
          <Link href='/users'>Open Members Directory</Link>
        </Button>
        <Button variant='outline' size='sm' asChild>
          <Link href='/roles'>View Role Matrix</Link>
        </Button>
      </PageHeader>

      <AdminAccessFilters
        total={total}
        owners={stats.owners}
        devs={stats.devs}
        admins={stats.admins}
        searchInput={searchInput}
        onSearchInputChange={setSearchInput}
        role={role}
        onRoleChange={setRole}
        status={status}
        onStatusChange={setStatus}
        limit={limit}
        onLimitChange={setLimit}
      />

      <AdminAccessTableCard
        users={users}
        sessionId={session.id}
        loading={isLoading}
        error={error}
        actionUserId={actionUserId}
        actorIsOwner={actorIsOwner}
        actorCanManageDevs={actorCanManageDevs}
        actorCanManageAdmins={actorCanManageAdmins}
        pageStart={pageStart}
        pageEnd={pageEnd}
        total={total}
        canPrev={canPrev}
        canNext={canNext}
        onPrevPage={() => setOffset(Math.max(offset - limit, 0))}
        onNextPage={() => setOffset(offset + limit)}
        onAction={openConfirmDialog}
      />

      <ConfirmRoleDialog
        open={confirmOpen}
        onOpenChange={closeConfirmDialog}
        pendingAction={pendingAction}
        confirmNote={confirmNote}
        confirmError={confirmError}
        actionUserId={actionUserId}
        onConfirm={() => void confirmGovernanceAction()}
        onCancel={closeConfirmDialog}
        onNoteChange={setConfirmNote}
      />
    </div>
  );
}
