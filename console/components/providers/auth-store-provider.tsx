'use client';

import { useEffect } from 'react';
import { useAuthStore } from '@/lib/stores';
import type { AdminMe } from '@/lib/api';

interface AuthStoreProviderProps {
  initialUser: AdminMe;
  children: React.ReactNode;
}

/**
 * Syncs server-side user data to Zustand auth store
 * Call this in your layout after fetching user data server-side
 */
export function AuthStoreProvider({ initialUser, children }: AuthStoreProviderProps) {
  const setUser = useAuthStore((state) => state.setUser);

  useEffect(() => {
    // Sync server user data to Zustand store on mount
    setUser(initialUser);
  }, [initialUser, setUser]);

  return <>{children}</>;
}
