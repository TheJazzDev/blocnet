'use client';

import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { AlertCircle, Award, CheckCircle2, Edit } from 'lucide-react';
import { QuestModel } from './quest-models';

function formatDate(dateString: string | null): string {
  if (!dateString) return '—';
  try {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  } catch {
    return 'Invalid Date';
  }
}

function questTypeBadgeClass(type: string): string {
  switch (type) {
    case 'internal_action':
      return 'border border-amber-400/30 bg-amber-400/12 text-amber-200';
    case 'social_media':
      return 'border border-fuchsia-400/30 bg-fuchsia-400/12 text-fuchsia-200';
    case 'external_link':
    default:
      return 'border border-sky-400/30 bg-sky-400/12 text-sky-200';
  }
}

function questCategoryBadgeClass(category: string): string {
  switch (category) {
    case 'mining':
      return 'border border-indigo-400/30 bg-indigo-400/12 text-indigo-200';
    case 'engagement':
      return 'border border-emerald-400/30 bg-emerald-400/12 text-emerald-200';
    case 'social':
      return 'border border-pink-400/30 bg-pink-400/12 text-pink-200';
    case 'trust':
      return 'border border-cyan-400/30 bg-cyan-400/12 text-cyan-200';
    case 'special':
    default:
      return 'border border-violet-400/30 bg-violet-400/12 text-violet-200';
  }
}

function verificationBadgeClass(method: string): string {
  return method === 'auto'
    ? 'border border-emerald-400/30 bg-emerald-400/12 text-emerald-200'
    : 'border border-orange-400/30 bg-orange-400/12 text-orange-200';
}

export function QuestsTable({
  quests,
  onEdit,
  typeLabel,
  categoryLabel,
}: {
  quests: QuestModel[];
  onEdit: (quest: QuestModel) => void;
  typeLabel: (value: string) => string;
  categoryLabel: (value: string) => string;
}) {
  return (
    <div className="rounded-lg border bg-card">
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Title</TableHead>
            <TableHead className="hidden md:table-cell">Type</TableHead>
            <TableHead className="hidden lg:table-cell">Category</TableHead>
            <TableHead className="hidden sm:table-cell">Rewards</TableHead>
            <TableHead className="hidden xl:table-cell">Verification</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className="hidden lg:table-cell">Expires</TableHead>
            <TableHead className="text-right">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {quests.length === 0 ? (
            <TableRow>
              <TableCell colSpan={8} className="text-center py-8 text-muted-foreground">
                No quests found. Create your first quest to get started.
              </TableCell>
            </TableRow>
          ) : (
            quests.map((quest) => (
              <TableRow key={quest.id}>
                <TableCell>
                  <div className="space-y-1">
                    <p className="font-medium text-sm">{quest.title}</p>
                    <p className="text-xs text-muted-foreground line-clamp-1">{quest.description}</p>
                  </div>
                </TableCell>
                <TableCell className="hidden md:table-cell">
                  <span
                    className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ${questTypeBadgeClass(quest.type)}`}
                  >
                    {typeLabel(quest.type)}
                  </span>
                </TableCell>
                <TableCell className="hidden lg:table-cell">
                  <span
                    className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ${questCategoryBadgeClass(quest.category)}`}
                  >
                    {categoryLabel(quest.category)}
                  </span>
                </TableCell>
                <TableCell className="hidden sm:table-cell">
                  <div className="flex flex-col gap-1">
                    {quest.rewardPoints > 0 && (
                      <span className="text-xs text-muted-foreground">{quest.rewardPoints} pts</span>
                    )}
                    {quest.rewardBadge && (
                      <div className="flex items-center gap-1">
                        <Award className="h-3 w-3 text-yellow-600" />
                        <span className="text-xs text-muted-foreground">{quest.rewardBadge.name}</span>
                      </div>
                    )}
                  </div>
                </TableCell>
                <TableCell className="hidden xl:table-cell">
                  <span
                    className={`inline-flex items-center rounded-md px-2 py-1 text-xs font-medium ${verificationBadgeClass(
                      quest.verificationMethod,
                    )}`}
                  >
                    {quest.verificationMethod === 'auto' ? 'Auto' : 'Manual'}
                  </span>
                </TableCell>
                <TableCell>
                  {quest.isActive ? (
                    <span className="inline-flex items-center gap-1 rounded-md border border-emerald-400/30 bg-emerald-400/12 px-2 py-1 text-xs font-medium text-emerald-200">
                      <CheckCircle2 className="h-3 w-3" />
                      Active
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 rounded-md border border-zinc-400/30 bg-zinc-400/12 px-2 py-1 text-xs font-medium text-zinc-200">
                      <AlertCircle className="h-3 w-3" />
                      Inactive
                    </span>
                  )}
                </TableCell>
                <TableCell className="hidden lg:table-cell text-xs text-muted-foreground">
                  {formatDate(quest.expiresAt)}
                </TableCell>
                <TableCell className="text-right">
                  <Button variant="ghost" size="sm" onClick={() => onEdit(quest)}>
                    <Edit className="h-4 w-4" />
                  </Button>
                </TableCell>
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>
    </div>
  );
}

