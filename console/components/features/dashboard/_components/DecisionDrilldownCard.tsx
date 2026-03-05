'use client';

import Link from 'next/link';
import { Sparkles } from 'lucide-react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { LoadingSpinner } from '@/components/ui/loading-spinner';
import type { EdgeBriefResponse, EdgeExplainResponse } from '@/lib/api-client';
import { MetricCell } from './MetricCell';

type DecisionDrilldownCardProps = {
  loading: boolean;
  edgeBrief: EdgeBriefResponse | null;
  edgeExplain: EdgeExplainResponse | null;
  edgeExplainLoading: boolean;
  selectedDecisionId: string | null;
  onOpenDecision: (decisionId: string) => Promise<void>;
};

export function DecisionDrilldownCard({
  loading,
  edgeBrief,
  edgeExplain,
  edgeExplainLoading,
  selectedDecisionId,
  onOpenDecision,
}: DecisionDrilldownCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className='flex items-center gap-2 text-base'>
          <Sparkles className='h-4 w-4' />
          Decision Drilldown
        </CardTitle>
        <CardDescription>
          Reason codes and component scores for top Edge decisions.
        </CardDescription>
      </CardHeader>
      <CardContent className='space-y-3'>
        {loading ? (
          <LoadingSpinner className='py-6' />
        ) : edgeBrief?.topDecisions.length ? (
          <>
            <div className='space-y-2'>
              {edgeBrief.topDecisions.slice(0, 4).map((decision) => (
                <button
                  key={decision.decisionId}
                  type='button'
                  onClick={() => void onOpenDecision(decision.decisionId)}
                  className='w-full rounded-md border p-2 text-left transition hover:bg-muted/40'>
                  <p className='truncate text-xs font-medium'>{decision.title}</p>
                  <div className='mt-1 flex items-center justify-between gap-2 text-[11px] text-muted-foreground'>
                    <span className='truncate'>{decision.projectName}</span>
                    <Badge variant='outline' className='text-[10px]'>
                      {decision.recommendedAction}
                    </Badge>
                  </div>
                </button>
              ))}
            </div>

            {selectedDecisionId || edgeExplainLoading ? (
              <div className='rounded-md border p-2'>
                <div className='mb-2 flex items-center justify-between'>
                  <p className='text-xs font-semibold'>Inspector</p>
                  {selectedDecisionId ? (
                    <span className='truncate text-[10px] text-muted-foreground'>
                      {selectedDecisionId}
                    </span>
                  ) : null}
                </div>
                {edgeExplainLoading ? (
                  <LoadingSpinner className='py-2' />
                ) : edgeExplain?.explanation ? (
                  <div className='space-y-2 text-[11px]'>
                    <p className='text-muted-foreground'>
                      {edgeExplain.explanation.narrative}
                    </p>
                    <div className='grid grid-cols-2 gap-2'>
                      <MetricCell
                        label='Score'
                        value={edgeExplain.explanation.edgeScore.toFixed(3)}
                        hint=''
                      />
                      <MetricCell
                        label='Action'
                        value={edgeExplain.explanation.recommendedAction}
                        hint=''
                      />
                      <MetricCell
                        label='Urgency'
                        value={edgeExplain.explanation.components.urgency.toFixed(
                          3,
                        )}
                        hint=''
                      />
                      <MetricCell
                        label='Recency'
                        value={edgeExplain.explanation.components.recency.toFixed(
                          3,
                        )}
                        hint=''
                      />
                      <MetricCell
                        label='Relevance'
                        value={edgeExplain.explanation.components.relevance.toFixed(
                          3,
                        )}
                        hint=''
                      />
                      <MetricCell
                        label='Novelty'
                        value={edgeExplain.explanation.components.novelty.toFixed(
                          3,
                        )}
                        hint=''
                      />
                      <MetricCell
                        label='Penalties'
                        value={edgeExplain.explanation.components.penalties.toFixed(
                          3,
                        )}
                        hint=''
                      />
                    </div>
                    <div className='flex flex-wrap gap-1.5'>
                      {edgeExplain.explanation.reasonCodes.map((reason) => (
                        <Badge key={reason} variant='outline' className='text-[10px]'>
                          {reason}
                        </Badge>
                      ))}
                    </div>
                  </div>
                ) : (
                  <p className='text-[11px] text-muted-foreground'>
                    Explanation unavailable.
                  </p>
                )}
              </div>
            ) : null}

            <Button variant='outline' className='w-full' asChild>
              <Link href='/edge-engine'>Open Full Edge Console</Link>
            </Button>
          </>
        ) : (
          <p className='text-sm text-muted-foreground'>
            No top decisions available yet.
          </p>
        )}
      </CardContent>
    </Card>
  );
}
