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

export interface EmailStatus {
  configured: boolean;
  reason: string | null;
  allowedFromAddresses: string[];
}

export function EmailForm({
  canSend,
  emailStatus,
  fromAddress,
  fromName,
  replyTo,
  subject,
  previewText,
  message,
  ctaLabel,
  ctaUrl,
  target,
  targetOptions,
  onChangeFromAddress,
  onChangeFromName,
  onChangeReplyTo,
  onChangeSubject,
  onChangePreviewText,
  onChangeMessage,
  onChangeCtaLabel,
  onChangeCtaUrl,
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
  emailStatus: EmailStatus | null;
  fromAddress: string;
  fromName: string;
  replyTo: string;
  subject: string;
  previewText: string;
  message: string;
  ctaLabel: string;
  ctaUrl: string;
  target: BroadcastTarget;
  targetOptions: Array<{ value: BroadcastTarget; label: string; description: string }>;
  onChangeFromAddress: (v: string) => void;
  onChangeFromName: (v: string) => void;
  onChangeReplyTo: (v: string) => void;
  onChangeSubject: (v: string) => void;
  onChangePreviewText: (v: string) => void;
  onChangeMessage: (v: string) => void;
  onChangeCtaLabel: (v: string) => void;
  onChangeCtaUrl: (v: string) => void;
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
      {emailStatus && !emailStatus.configured && (
        <div className='rounded-md border border-amber-500/30 bg-amber-500/10 px-3 py-2 text-xs text-amber-200'>
          Email provider is not configured: {emailStatus.reason ?? 'missing settings'}
        </div>
      )}

      <div className='grid gap-3 md:grid-cols-2'>
        <div className='space-y-1.5'>
          <label className='text-sm font-medium'>From Address</label>
          <Input
            value={fromAddress}
            onChange={(e) => onChangeFromAddress(e.target.value)}
            placeholder='updates@blocnet.app'
            list='email-from-allowlist'
            disabled={!canSend}
          />
          <datalist id='email-from-allowlist'>
            {(emailStatus?.allowedFromAddresses ?? []).map((addr) => (
              <option key={addr} value={addr} />
            ))}
          </datalist>
        </div>
        <div className='space-y-1.5'>
          <label className='text-sm font-medium'>From Name</label>
          <Input
            value={fromName}
            onChange={(e) => onChangeFromName(e.target.value)}
            placeholder='Blocnet Updates'
            maxLength={120}
            disabled={!canSend}
          />
        </div>
      </div>

      <div className='space-y-1.5'>
        <label className='text-sm font-medium'>Reply-To (optional)</label>
        <Input
          value={replyTo}
          onChange={(e) => onChangeReplyTo(e.target.value)}
          placeholder='support@blocnet.app'
          maxLength={320}
          disabled={!canSend}
        />
      </div>

      <div className='space-y-1.5'>
        <label className='text-sm font-medium'>Subject</label>
        <Input
          value={subject}
          onChange={(e) => onChangeSubject(e.target.value)}
          placeholder='Blocnet is now live'
          maxLength={140}
          disabled={!canSend}
        />
      </div>

      <div className='space-y-1.5'>
        <label className='text-sm font-medium'>Preview Text (optional)</label>
        <Input
          value={previewText}
          onChange={(e) => onChangePreviewText(e.target.value)}
          placeholder='Shown in mailbox preview'
          maxLength={140}
          disabled={!canSend}
        />
      </div>

      <div className='space-y-1.5'>
        <label className='text-sm font-medium'>Message</label>
        <Textarea
          value={message}
          onChange={(e) => onChangeMessage(e.target.value)}
          placeholder='Write your announcement message...'
          maxLength={6000}
          rows={8}
          disabled={!canSend}
        />
        <p className='text-xs text-muted-foreground text-right'>{message.length}/6000</p>
      </div>

      <div className='grid gap-3 md:grid-cols-2'>
        <div className='space-y-1.5'>
          <label className='text-sm font-medium'>CTA Label (optional)</label>
          <Input
            value={ctaLabel}
            onChange={(e) => onChangeCtaLabel(e.target.value)}
            placeholder='Open Blocnet App'
            maxLength={40}
            disabled={!canSend}
          />
        </div>
        <div className='space-y-1.5'>
          <label className='text-sm font-medium'>CTA URL (optional)</label>
          <Input
            value={ctaUrl}
            onChange={(e) => onChangeCtaUrl(e.target.value)}
            placeholder='https://blocnet.app/notifications'
            maxLength={2048}
            disabled={!canSend}
          />
        </div>
      </div>

      <div className='space-y-1.5'>
        <label className='text-sm font-medium'>Audience</label>
        <div className='grid grid-cols-2 gap-2'>
          {targetOptions.map((opt) => (
            <button
              key={`email-${opt.value}`}
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
        disabled={
          !canSend ||
          !subject.trim() ||
          !message.trim() ||
          !fromAddress.trim() ||
          (target === 'specific' && selectedUsers.length === 0) ||
          (emailStatus != null && !emailStatus.configured)
        }
        className='w-full'>
        <Send className='h-4 w-4' />
        Send Email Broadcast
      </Button>
    </form>
  );
}

