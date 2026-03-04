'use client';

import { useMemo, useState } from 'react';
import { Check, Circle, Shield, Users2 } from 'lucide-react';
import { PageHeader } from '@/components/page-header';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import { type RolesMatrixResponse } from '@/lib/api-client';
import {
  buildLocalRolesMatrix,
  formatRoleLabel,
  type AdminPanelRole,
  type RoleCapabilityDefinition,
} from '@/lib/rbac';
import { useRolesQuery } from '@/lib/hooks/queries';

function roleBadgeClass(role: AdminPanelRole) {
  if (role === 'owner') return 'border-primary/40 bg-primary/15 text-primary';
  if (role === 'dev')
    return 'border-cyan-400/40 bg-cyan-400/10 text-cyan-300';
  if (role === 'admin')
    return 'border-teal-400/40 bg-teal-400/10 text-teal-300';
  return 'border-amber-500/40 bg-amber-500/10 text-amber-300';
}

function rolePill(role: AdminPanelRole) {
  return (
    <Badge key={role} variant='outline' className={roleBadgeClass(role)}>
      {formatRoleLabel(role)}
    </Badge>
  );
}

export default function RolesPage() {
  const [selectedRole, setSelectedRole] = useState<AdminPanelRole>('owner');

  // TanStack Query hook
  const { data: matrix = buildLocalRolesMatrix(), isLoading: loading } = useRolesQuery();

  const roleOrder = useMemo<AdminPanelRole[]>(() => {
    if (!matrix) return ['owner', 'dev', 'admin', 'moderator'];
    return matrix.governanceRoles
      .map((entry) => entry.role)
      .filter(Boolean) as AdminPanelRole[];
  }, [matrix]);

  const visibleSections = useMemo(() => {
    if (!matrix) return [];
    return matrix.sections.map((section) => ({
      ...section,
      capabilities: section.capabilities.filter((capability) =>
        capability.roles.includes(selectedRole),
      ),
    }));
  }, [matrix, selectedRole]);

  function hasRole(capability: RoleCapabilityDefinition, role: AdminPanelRole) {
    return capability.roles.includes(role);
  }

  return (
    <div className='space-y-6'>
      <PageHeader
        title='Role Matrix'
        description='Capability reference for owner, dev, admin, and moderator governance in the admin console.'
      />

      <div className='grid gap-4 md:grid-cols-3'>
        {(matrix?.governanceRoles ?? []).map((entry) => (
          <Card
            key={entry.role}
            className='border-primary/20 bg-gradient-to-br from-card to-card/70'>
            <CardHeader className='pb-3'>
              <CardTitle className='text-base'>{entry.label}</CardTitle>
              <CardDescription>{entry.description}</CardDescription>
            </CardHeader>
            <CardContent>
              <Button
                variant={selectedRole === entry.role ? 'default' : 'outline'}
                className='w-full'
                onClick={() => setSelectedRole(entry.role)}>
                View {entry.label} Access
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card className='border-teal-500/25 bg-teal-500/5'>
        <CardHeader className='pb-3'>
          <CardTitle className='flex items-center gap-2 text-base'>
            <Users2 className='h-4 w-4 text-teal-300' />
            Space Roles
          </CardTitle>
          <CardDescription>
            User, Core Team, and Hunter are space/capability roles, not admin
            governance roles.
          </CardDescription>
        </CardHeader>
        <CardContent className='flex flex-wrap gap-2 text-sm text-muted-foreground'>
          {(matrix?.spaceRoles ?? []).map((role) => (
            <Badge key={role.role} variant='secondary' className='text-xs'>
              {role.label}
            </Badge>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className='pb-3'>
          <CardTitle className='text-base'>
            {formatRoleLabel(selectedRole)} Capability View
          </CardTitle>
          <CardDescription>
            Jump by role to inspect exactly what this role can access and
            mutate.
          </CardDescription>
          <div className='mt-3 flex flex-wrap gap-2'>
            {roleOrder.map((role) => (
              <Button
                key={role}
                variant={selectedRole === role ? 'default' : 'outline'}
                size='sm'
                onClick={() => setSelectedRole(role)}>
                {formatRoleLabel(role)}
              </Button>
            ))}
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <LoadingSpinner className='py-12' />
          ) : !matrix ? (
            <p className='text-sm text-muted-foreground'>
              Unable to load role matrix.
            </p>
          ) : (
            <div className='space-y-6'>
              {visibleSections.map((section) => (
                <div key={section.id} className='rounded-lg border'>
                  <div className='border-b bg-muted/20 px-4 py-3'>
                    <h3 className='text-sm font-semibold'>{section.label}</h3>
                    <p className='text-xs text-muted-foreground'>
                      {section.description}
                    </p>
                  </div>
                  <div className='overflow-x-auto'>
                    <table className='min-w-full text-sm'>
                      <thead>
                        <tr className='border-b'>
                          <th className='px-4 py-2 text-left font-medium'>
                            Capability
                          </th>
                          <th className='px-4 py-2 text-left font-medium'>
                            Key
                          </th>
                          {roleOrder.map((role) => (
                            <th
                              key={role}
                              className='px-4 py-2 text-center font-medium'>
                              {formatRoleLabel(role)}
                            </th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {section.capabilities.map((capability) => (
                          <tr
                            key={capability.key}
                            className='border-b last:border-0'>
                            <td className='px-4 py-3 align-top'>
                              <p className='font-medium'>{capability.label}</p>
                              <p className='text-xs text-muted-foreground'>
                                {capability.description}
                              </p>
                            </td>
                            <td className='px-4 py-3 align-top'>
                              <code className='rounded bg-muted px-1.5 py-0.5 text-xs'>
                                {capability.key}
                              </code>
                            </td>
                            {roleOrder.map((role) => (
                              <td
                                key={`${capability.key}-${role}`}
                                className='px-4 py-3 text-center align-top'>
                                {hasRole(capability, role) ? (
                                  <Check className='mx-auto h-4 w-4 text-teal-300' />
                                ) : (
                                  <Circle className='mx-auto h-3.5 w-3.5 text-muted-foreground/40' />
                                )}
                              </td>
                            ))}
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              ))}

              {visibleSections.every(
                (entry) => entry.capabilities.length === 0,
              ) && (
                <div className='rounded-lg border border-dashed p-6 text-center text-sm text-muted-foreground'>
                  No capabilities available for this role.
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      <Card className='border-primary/20'>
        <CardHeader className='pb-3'>
          <CardTitle className='flex items-center gap-2 text-base'>
            <Shield className='h-4 w-4 text-primary' />
            Role Summary
          </CardTitle>
        </CardHeader>
        <CardContent className='grid gap-3 md:grid-cols-3'>
          {roleOrder.map((role) => {
            const count =
              matrix?.sections
                .flatMap((section) => section.capabilities)
                .filter((capability) => capability.roles.includes(role))
                .length ?? 0;
            return (
              <div key={role} className='rounded-md border bg-card p-3'>
                <div className='mb-2 flex items-center justify-between'>
                  <p className='text-sm font-medium'>{formatRoleLabel(role)}</p>
                  {rolePill(role)}
                </div>
                <p className='text-2xl font-semibold'>{count}</p>
                <p className='text-xs text-muted-foreground'>
                  capabilities mapped
                </p>
              </div>
            );
          })}
        </CardContent>
      </Card>
    </div>
  );
}
