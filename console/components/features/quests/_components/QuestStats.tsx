"use client";

type QuestStatsProps = {
  total: number;
  active: number;
  inactive: number;
  autoVerified: number;
  manualVerified: number;
  rewardPointsTotal: number;
};

export function QuestStats({
  total,
  active,
  inactive,
  autoVerified,
  manualVerified,
  rewardPointsTotal,
}: QuestStatsProps) {
  return (
    <div className='grid gap-3 sm:grid-cols-2 xl:grid-cols-5'>
      <StatCell label='Total Quests' value={total.toLocaleString()} />
      <StatCell
        label='Active / Inactive'
        value={`${active.toLocaleString()} / ${inactive.toLocaleString()}`}
      />
      <StatCell
        label='Auto / Manual Verification'
        value={`${autoVerified.toLocaleString()} / ${manualVerified.toLocaleString()}`}
      />
      <StatCell label='Configured Reward Points' value={rewardPointsTotal.toLocaleString()} />
      <StatCell
        label='Average Reward / Quest'
        value={total > 0 ? Math.round(rewardPointsTotal / total).toLocaleString() : '0'}
      />
    </div>
  );
}

function StatCell({ label, value }: { label: string; value: string }) {
  return (
    <div className='rounded-lg border bg-card p-3'>
      <p className='text-xs text-muted-foreground'>{label}</p>
      <p className='text-lg font-semibold'>{value}</p>
    </div>
  );
}
