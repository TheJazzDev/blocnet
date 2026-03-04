"use client";

import { useCallback, useEffect } from "react";
import { useAdminAccessStore } from "@/lib/stores/admin-access-store";
import { clientApi, type AdminUser } from "@/lib/api-client";
import type { GovernanceRole } from "@/components/features/admin-access/_components/admin-access-types";

interface UseAdminAccessOptions {
  autoLoad?: boolean;
}

/**
 * Hook to manage admin access (governance roles) with filters and actions
 */
export function useAdminAccess(options: UseAdminAccessOptions = {}) {
  const { autoLoad = true } = options;

  const store = useAdminAccessStore();
  const {
    users,
    total,
    isLoading,
    error,
    searchInput,
    q,
    role,
    status,
    limit,
    offset,
    setUsers,
    setTotal,
    setLoading,
    setError,
    setSearchInput,
    setQ,
  } = store;

  const loadUsers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      if (role === "all") {
        const governanceRoles: GovernanceRole[] = ["owner", "dev", "admin", "moderator"];
        const governancePageSize = 100;

        const fetchAllForRole = async (targetRole: GovernanceRole) => {
          const rows: AdminUser[] = [];
          let nextOffset = 0;
          // Governance user sets are expected to be small, but keep a hard cap.
          while (nextOffset <= 5000) {
            const response = await clientApi.listUsers({
              limit: governancePageSize,
              offset: nextOffset,
              role: targetRole,
              status,
              q,
            });
            rows.push(...response.data);
            if (response.data.length < governancePageSize) break;
            nextOffset += governancePageSize;
          }
          return rows;
        };

        const roleBatches = await Promise.all(
          governanceRoles.map((entry) => fetchAllForRole(entry))
        );
        const byUserId = new Map<string, AdminUser>();
        for (const batch of roleBatches) {
          for (const row of batch) {
            const existing = byUserId.get(row.id);
            if (!existing) {
              byUserId.set(row.id, row);
              continue;
            }
            byUserId.set(row.id, {
              ...row,
              roles: Array.from(new Set([...existing.roles, ...row.roles])),
            });
          }
        }

        const merged = Array.from(byUserId.values()).sort((a, b) => {
          return a.email.localeCompare(b.email);
        });
        setTotal(merged.length);
        setUsers(merged.slice(offset, offset + limit));
      } else {
        const result = await clientApi.listUsers({
          limit,
          offset,
          role,
          status,
          q,
        });
        const filtered = result.data.filter((entry) =>
          entry.roles.includes(role)
        );
        setUsers(filtered);
        setTotal(result.total);
      }
    } catch (e: unknown) {
      setUsers([]);
      setTotal(0);
      setError(
        e instanceof Error ? e.message : "Failed to load admin access members"
      );
    } finally {
      setLoading(false);
    }
  }, [limit, offset, role, status, q, setUsers, setTotal, setLoading, setError]);

  // Debounce search input
  useEffect(() => {
    const timer = setTimeout(() => {
      setQ(searchInput.trim());
      store.setOffset(0);
    }, 300);
    return () => clearTimeout(timer);
  }, [searchInput, setQ, store]);

  // Auto-load when filters change
  useEffect(() => {
    if (autoLoad) {
      void loadUsers();
    }
  }, [autoLoad, loadUsers]);

  return {
    ...store,
    loadUsers,
    refresh: loadUsers,
  };
}
