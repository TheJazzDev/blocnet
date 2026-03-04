'use client';

import { FormEvent } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { RecipientPicker } from './RecipientPicker';
import { Send } from 'lucide-react';

type BroadcastTarget = 'all' | 'hunters' | 'users' | 'specific';

export interface SelectedUser {
  id: string;
  displayName: string | null;
  email: string;
}

export function PushForm({
  canSend,
  title,
  body,
  target,
  targetOptions,
  onChangeTitle,
  onChangeBody,
  onChangeTarget,
  selectedUsers,
  searchQuery,
  setSearchQuery,
  searching,
  searched,
  searchResults,
  onSearch,
  onAddUser,
  onRemoveUser,
  onSubmit,
}: {
  canSend: boolean;
  title: string;
  body: string;
  target: BroadcastTarget;
  targetOptions: Array<{ value: BroadcastTarget; label: string; description: string }>;
  onChangeTitle: (v: string) => void;
  onChangeBody: (v: string) => void;
  onChangeTarget: (v: BroadcastTarget) => void;
  selectedUsers: SelectedUser[];
  searchQuery: string;
  setSearchQuery: (v: string) => void;
  searching: boolean;
  searched: boolean;
  searchResults: SelectedUser[];
  onSearch: () => void;
  onAddUser: (u: SelectedUser) => void;
  onRemoveUser: (id: string) => void;
  onSubmit: () => void;
}) {
  function submit(e: FormEvent) {
    e.preventDefault();
    onSubmit();
  }

  return (
    <form onSubmit={submit} className='space-y-4'>
      <div className='space-y-1.5'>
        <label className='text-sm font-medium'>Title</label>
        <Input
          value={title}
          onChange={(e) => onChangeTitle(e.target.value)}
          placeholder='Notification title'
          maxLength={100}
          disabled={!canSend}
        />
        <p className='text-xs text-muted-foreground text-right'>{title.length}/100</p>
      </div>

      <div className='space-y-1.5'>
        <label className='text-sm font-medium'>Message</label>
        <Textarea
          value={body}
          onChange={(e) => onChangeBody(e.target.value)}
          placeholder='Notification body'
          maxLength={500}
          rows={3}
          disabled={!canSend}
        />
        <p className='text-xs text-muted-foreground text-right'>{body.length}/500</p>
      </div>

      <div className='space-y-1.5'>
        <label className='text-sm font-medium'>Audience</label>
        <div className='grid grid-cols-2 gap-2'>
          {targetOptions.map((opt) => (
            <button
              key={opt.value}
              type='button'
              onClick={() => onChangeTarget(opt.value)}
              disabled={!canSend}
              className={`rounded-lg border p-3 text-left transition-colors ${
                target === opt.value
                  ? 'border-primary bg-primary/10 text-primary'
                  : 'border-border bg-card text-muted-foreground hover:border-primary/40 hover:text-foreground'
              }`}>
              <p className='text-sm font-medium'>{opt.label}</p>
              <p className='text-xs mt-0.5 opacity-70'>{opt.description}</p>
            </button>
          ))}
        </div>
      </div>

      {target === 'specific' && (
        <RecipientPicker
          canSend={canSend}
          query={searchQuery}
          setQuery={setSearchQuery}
          onSearch={onSearch}
          searching={searching}
          searched={searched}
          results={searchResults}
          onAddUser={onAddUser}
          selectedUsers={selectedUsers}
          onRemoveUser={onRemoveUser}
        />
      )}

      <Button
        type='submit'
        disabled={!canSend || !title.trim() || !body.trim() || (target === 'specific' && selectedUsers.length === 0)}
        className='w-full'>
        <Send className='h-4 w-4' />
        Send Notification
      </Button>
    </form>
  );
}

