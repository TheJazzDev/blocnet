'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { findActiveGroupLabel, type NavGroup } from './sidebar-nav-items';

const STORAGE_KEY = 'blocnet-console.sidebar-groups';

type OpenState = Record<string, boolean>;

function readStoredState(): OpenState {
  if (typeof window === 'undefined') return {};
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return {};
    const parsed: unknown = JSON.parse(raw);
    if (!parsed || typeof parsed !== 'object') return {};
    return Object.fromEntries(
      Object.entries(parsed as Record<string, unknown>).filter(
        ([, value]) => typeof value === 'boolean',
      ),
    ) as OpenState;
  } catch {
    return {};
  }
}

function writeStoredState(state: OpenState) {
  if (typeof window === 'undefined') return;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // localStorage may be unavailable (private mode, quota); ignore.
  }
}

/**
 * Collapsible sidebar group state. The group containing the active route
 * starts open; every manual toggle is persisted in localStorage. Navigating
 * into a collapsed group re-opens it.
 */
export function useSidebarGroups(groups: NavGroup[], pathname: string) {
  const activeGroup = useMemo(
    () => findActiveGroupLabel(groups, pathname),
    [groups, pathname],
  );
  const [openState, setOpenState] = useState<OpenState>({});
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    const stored = readStoredState();
    setOpenState(activeGroup ? { ...stored, [activeGroup]: true } : stored);
    setHydrated(true);
    // Only on mount: later route changes are handled below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!hydrated || !activeGroup) return;
    setOpenState((prev) =>
      prev[activeGroup] ? prev : { ...prev, [activeGroup]: true },
    );
  }, [activeGroup, hydrated]);

  useEffect(() => {
    if (!hydrated) return;
    writeStoredState(openState);
  }, [hydrated, openState]);

  const isOpen = useCallback(
    (label: string) => openState[label] ?? label === activeGroup,
    [activeGroup, openState],
  );

  const setOpen = useCallback((label: string, open: boolean) => {
    setOpenState((prev) => ({ ...prev, [label]: open }));
  }, []);

  return { activeGroup, isOpen, setOpen };
}
