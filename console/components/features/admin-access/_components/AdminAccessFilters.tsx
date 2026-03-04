'use client';

import { Search } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { GovernanceFilter, StatusFilter } from './admin-access-types';

type AdminAccessFiltersProps = {
  total: number;
  owners: number;
  devs: number;
  admins: number;
  moderators: number;
  searchInput: string;
  onSearchInputChange: (value: string) => void;
  role: GovernanceFilter;
  onRoleChange: (value: GovernanceFilter) => void;
  status: StatusFilter;
  onStatusChange: (value: StatusFilter) => void;
  limit: number;
  onLimitChange: (value: number) => void;
};

export function AdminAccessFilters({
  total,
  owners,
  devs,
  admins,
  moderators,
  searchInput,
  onSearchInputChange,
  role,
  onRoleChange,
  status,
  onStatusChange,
  limit,
  onLimitChange,
}: AdminAccessFiltersProps) {
  return (
    <>
      <div className='grid gap-4 sm:grid-cols-2 xl:grid-cols-5'>
        <MetricStat label='Total Results' value={total} />
        <MetricStat label='Owners (page)' value={owners} />
        <MetricStat label='Devs (page)' value={devs} />
        <MetricStat label='Admins (page)' value={admins} />
        <MetricStat label='Moderators (page)' value={moderators} />
      </div>

      <Card>
        <CardContent className='pt-6'>
          <div className='grid gap-3 md:grid-cols-5'>
            <div className='relative md:col-span-2'>
              <Search className='pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground' />
              <Input
                value={searchInput}
                onChange={(event) => onSearchInputChange(event.target.value)}
                className='pl-9'
                placeholder='Search by name, email, username, or user ID'
              />
            </div>
            <Select
              value={role}
              onValueChange={(next) => onRoleChange(next as GovernanceFilter)}
            >
              <SelectTrigger>
                <SelectValue placeholder='Governance role' />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value='all'>Owner/Dev/Admin/Moderator</SelectItem>
                <SelectItem value='owner'>Owner only</SelectItem>
                <SelectItem value='dev'>Dev only</SelectItem>
                <SelectItem value='admin'>Admin only</SelectItem>
                <SelectItem value='moderator'>Moderator only</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={status}
              onValueChange={(next) => onStatusChange(next as StatusFilter)}
            >
              <SelectTrigger>
                <SelectValue placeholder='Status' />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value='active'>Active</SelectItem>
                <SelectItem value='deactivated'>Deactivated</SelectItem>
                <SelectItem value='all'>All statuses</SelectItem>
              </SelectContent>
            </Select>
            <Select
              value={String(limit)}
              onValueChange={(next) => onLimitChange(Number(next))}
            >
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
    </>
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
