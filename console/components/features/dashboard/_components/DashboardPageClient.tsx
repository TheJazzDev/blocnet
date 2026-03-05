'use client';

import Link from 'next/link';
import {
  FileCheck,
  FolderKanban,
  Loader2,
  RefreshCw,
  Sparkles,
  TrendingUp,
  Users,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { PageHeader } from '@/components/page-header';
import { DashboardStatsGrid } from './DashboardStatsGrid';
import { OperationalQueueCard } from './OperationalQueueCard';
import { EconomySnapshotCard } from './EconomySnapshotCard';
import { BeeSnapshotCard } from './BeeSnapshotCard';
import { DecisionDrilldownCard } from './DecisionDrilldownCard';
import { RecentActivityCard } from './RecentActivityCard';
import { QuickStatsCard } from './QuickStatsCard';
import { useDashboardData } from './use-dashboard-data';

export default function DashboardPageClient() {
  const {
    stats,
    walletHealth,
    activityLogs,
    edgeBrief,
    edgeExplain,
    edgeExplainLoading,
    selectedDecisionId,
    activityPage,
    activityHasNext,
    activityLoading,
    loading,
    refreshing,
    loadError,
    edgeTelemetry,
    loadDashboard,
    openEdgeDecision,
    loadActivityPage,
  } = useDashboardData();

  const statCards = stats
    ? [
        {
          title: 'Total Projects',
          value: stats.totalProjects.toLocaleString(),
          change: `${stats.totalUpdates} updates published`,
          icon: FolderKanban,
        },
        {
          title: 'Total Users',
          value: stats.totalUsers.toLocaleString(),
          change: `${stats.activeUsers.toLocaleString()} active`,
          icon: Users,
        },
        {
          title: 'Pending Queue',
          value: (stats.pendingAdminApps + stats.pendingProposals).toString(),
          change: `${stats.pendingAdminApps} role apps · ${stats.pendingProposals} proposals`,
          icon: FileCheck,
        },
        {
          title: 'Total Content',
          value: (stats.totalUpdates + stats.totalComments).toLocaleString(),
          change: `${stats.totalComments} comments`,
          icon: TrendingUp,
        },
      ]
    : [];

  const activeRate =
    stats && stats.totalUsers > 0
      ? (stats.activeUsers / stats.totalUsers) * 100
      : 0;

  return (
    <div className='space-y-6'>
      <PageHeader
        title='Dashboard'
        description='Operations command center for content, governance, health, and Edge intelligence.'>
        <Button variant='outline' asChild>
          <Link href='/edge-engine'>
            <Sparkles className='h-4 w-4' />
            Open Edge Engine
          </Link>
        </Button>
        <Button
          variant='outline'
          onClick={() => void loadDashboard(false)}
          disabled={loading || refreshing}>
          {refreshing ? (
            <Loader2 className='h-4 w-4 animate-spin' />
          ) : (
            <RefreshCw className='h-4 w-4' />
          )}
          Refresh
        </Button>
      </PageHeader>

      {loadError ? (
        <Card className='border-destructive/30'>
          <CardContent className='pt-6 text-sm text-destructive'>
            {loadError}
          </CardContent>
        </Card>
      ) : null}

      <DashboardStatsGrid loading={loading} statCards={statCards} />

      <OperationalQueueCard loading={loading} stats={stats} activeRate={activeRate} />

      <EconomySnapshotCard loading={loading} walletHealth={walletHealth} />

      <div className='grid gap-4 xl:grid-cols-3'>
        <BeeSnapshotCard
          loading={loading}
          edgeBrief={edgeBrief}
          edgeTelemetry={edgeTelemetry}
        />
        <DecisionDrilldownCard
          loading={loading}
          edgeBrief={edgeBrief}
          edgeExplain={edgeExplain}
          edgeExplainLoading={edgeExplainLoading}
          selectedDecisionId={selectedDecisionId}
          onOpenDecision={openEdgeDecision}
        />
      </div>

      <RecentActivityCard
        loading={loading}
        activityLogs={activityLogs}
        activityPage={activityPage}
        activityHasNext={activityHasNext}
        activityLoading={activityLoading}
        onPrevPage={() => loadActivityPage(activityPage - 1)}
        onNextPage={() => loadActivityPage(activityPage + 1)}
      />

      <QuickStatsCard loading={loading} stats={stats} />
    </div>
  );
}
