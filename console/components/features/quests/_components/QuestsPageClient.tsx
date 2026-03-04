'use client';

import { useMemo } from 'react';
import { AlertCircle, Loader2, Plus } from 'lucide-react';
import { useAdminSession } from '@/components/admin-shell';
import { PageHeader } from '@/components/page-header';
import { Button } from '@/components/ui/button';
import { apiFetch } from '@/lib/api-client';
import { useQuests } from '@/lib/hooks';
import { QuestCreateDialog } from './QuestCreateDialog';
import { QuestEditDialog } from './QuestEditDialog';
import { QuestStats } from './QuestStats';
import { QuestsTable } from './QuestsTable';
import {
  QUEST_CATEGORIES,
  QUEST_TYPES,
  toQuestPayload,
} from './quest-models';

export default function QuestsPageClient() {
  const session = useAdminSession();
  const canManageQuests =
    session.effectiveRoles.includes('owner') ||
    session.effectiveRoles.includes('admin');

  const {
    quests,
    badges,
    isLoading,
    error,
    createOpen,
    editOpen,
    selectedQuest,
    createSubmitError,
    editSubmitError,
    openCreate,
    closeCreate,
    openEdit,
    closeEdit,
    setCreateSubmitError,
    setEditSubmitError,
    refresh,
  } = useQuests();

  const stats = useMemo(() => {
    const active = quests.filter((quest) => quest.isActive).length;
    const autoVerified = quests.filter(
      (quest) => quest.verificationMethod === 'auto',
    ).length;
    const rewardPointsTotal = quests.reduce(
      (total, quest) => total + (quest.rewardPoints ?? 0),
      0,
    );

    return {
      total: quests.length,
      active,
      inactive: quests.length - active,
      autoVerified,
      manualVerified: quests.length - autoVerified,
      rewardPointsTotal,
    };
  }, [quests]);

  async function handleCreateSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setCreateSubmitError(null);

    const payload = toQuestPayload(new FormData(event.currentTarget), false);

    try {
      await apiFetch('/admin/quests', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      closeCreate();
      await refresh();
    } catch (err: unknown) {
      setCreateSubmitError(
        err instanceof Error ? err.message : 'Failed to create quest',
      );
    }
  }

  async function handleEditSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!selectedQuest) {
      return;
    }

    setEditSubmitError(null);

    const payload = toQuestPayload(new FormData(event.currentTarget), true);

    try {
      await apiFetch(`/admin/quests/${selectedQuest.id}`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
      closeEdit();
      await refresh();
    } catch (err: unknown) {
      setEditSubmitError(
        err instanceof Error ? err.message : 'Failed to update quest',
      );
    }
  }

  if (!canManageQuests) {
    return (
      <div className='flex min-h-screen items-center justify-center'>
        <div className='rounded-lg border border-destructive/35 bg-destructive/10 p-6'>
          <p className='text-sm text-destructive-foreground'>
            You do not have permission to manage quests.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className='space-y-6'>
      <PageHeader
        title='Quests'
        description='Manage quests, balance incentives, and monitor verification mix.'>
        <Button onClick={openCreate} size='sm' className='gap-2'>
          <Plus className='h-4 w-4' />
          <span className='hidden sm:inline'>Create Quest</span>
          <span className='sm:hidden'>New</span>
        </Button>
      </PageHeader>

      <QuestStats
        total={stats.total}
        active={stats.active}
        inactive={stats.inactive}
        autoVerified={stats.autoVerified}
        manualVerified={stats.manualVerified}
        rewardPointsTotal={stats.rewardPointsTotal}
      />

      {error ? (
        <div className='rounded-lg border border-destructive/35 bg-destructive/10 p-4'>
          <div className='flex items-start gap-3'>
            <AlertCircle className='h-5 w-5 shrink-0 text-destructive' />
            <p className='text-sm text-destructive-foreground'>{error}</p>
          </div>
        </div>
      ) : null}

      {isLoading ? (
        <div className='flex items-center justify-center py-12'>
          <Loader2 className='h-6 w-6 animate-spin text-primary' />
        </div>
      ) : (
        <QuestsTable
          quests={quests}
          onEdit={openEdit}
          typeLabel={(value) =>
            QUEST_TYPES.find((type) => type.value === value)?.label ?? value
          }
          categoryLabel={(value) =>
            QUEST_CATEGORIES.find((category) => category.value === value)
              ?.label ?? value
          }
        />
      )}

      <QuestCreateDialog
        open={createOpen}
        badges={badges}
        submitError={createSubmitError}
        onOpenChange={(nextOpen) => {
          if (nextOpen) {
            openCreate();
          } else {
            closeCreate();
          }
        }}
        onSubmit={handleCreateSubmit}
      />

      <QuestEditDialog
        open={editOpen}
        quest={selectedQuest}
        badges={badges}
        submitError={editSubmitError}
        onOpenChange={(nextOpen) => {
          if (!nextOpen) {
            closeEdit();
          }
        }}
        onCancel={closeEdit}
        onSubmit={handleEditSubmit}
      />
    </div>
  );
}
