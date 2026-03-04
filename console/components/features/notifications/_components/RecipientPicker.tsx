'use client';

import { Loader2, Search, X } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';

export interface SelectedUser {
  id: string;
  displayName: string | null;
  email: string;
}

export function RecipientPicker({
  canSend,
  query,
  setQuery,
  onSearch,
  searching,
  searched,
  results,
  onAddUser,
  selectedUsers,
  onRemoveUser,
}: {
  canSend: boolean;
  query: string;
  setQuery: (v: string) => void;
  onSearch: () => void;
  searching: boolean;
  searched: boolean;
  results: SelectedUser[];
  onAddUser: (user: SelectedUser) => void;
  selectedUsers: SelectedUser[];
  onRemoveUser: (id: string) => void;
}) {
  return (
    <div className='space-y-2'>
      <label className='text-sm font-medium'>Add recipients</label>
      <div className='flex gap-2'>
        <div className='relative flex-1'>
          <Search className='absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground' />
          <Input
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                onSearch();
              }
            }}
            placeholder='Name, username or email'
            className='pl-9'
            disabled={!canSend}
          />
        </div>
        <Button
          type='button'
          variant='outline'
          size='sm'
          disabled={!canSend || searching || query.trim().length < 2}
          onClick={onSearch}
          className='shrink-0'>
          {searching ? <Loader2 className='h-4 w-4 animate-spin' /> : 'Search'}
        </Button>
      </div>

      {results.length > 0 && (
        <div className='rounded-lg border bg-popover shadow-md overflow-hidden'>
          {results.map((user) => (
            <button
              key={user.id}
              type='button'
              onClick={() => onAddUser(user)}
              className='w-full flex items-center gap-3 px-3 py-2 text-left hover:bg-accent transition-colors'>
              <div className='h-7 w-7 rounded-full bg-primary/20 flex items-center justify-center text-xs font-bold text-primary shrink-0'>
                {(user.displayName ?? user.email)[0].toUpperCase()}
              </div>
              <div className='min-w-0'>
                <p className='text-sm font-medium truncate'>
                  {user.displayName ?? '—'}
                </p>
                <p className='text-xs text-muted-foreground truncate'>
                  {user.email}
                </p>
              </div>
            </button>
          ))}
        </div>
      )}

      {searched && results.length === 0 && (
        <p className='text-xs text-muted-foreground px-1'>No users found.</p>
      )}

      {selectedUsers.length > 0 && (
        <div className='flex flex-wrap gap-2'>
          {selectedUsers.map((user) => (
            <Badge key={user.id} variant='secondary' className='gap-1.5 pr-1'>
              {user.displayName ?? user.email}
              <button
                type='button'
                onClick={() => onRemoveUser(user.id)}
                className='rounded-full hover:bg-destructive/20 p-0.5'>
                <X className='h-3 w-3' />
              </button>
            </Badge>
          ))}
        </div>
      )}
    </div>
  );
}
