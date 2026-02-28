export interface EdgeBriefDecision {
  decisionId: string;
  edgeScore: number;
  recommendedAction: "act" | "watch" | "ignore" | string;
  title: string;
  projectName: string;
  urgency: "high" | "medium" | "low" | string;
  createdAt: string;
}

export interface EdgeBriefProject {
  projectId: string;
  projectName: string;
  count: number;
  highUrgencyCount: number;
  avgEdgeScore: number;
  lastUpdateAt: string | null;
}

export interface EdgeBriefResponse {
  asOf: string;
  enabled: boolean;
  windowDays: number;
  totalSignals: number;
  highUrgencyCount: number;
  recommendedNowCount: number;
  watchCount: number;
  topProjects: EdgeBriefProject[];
  topDecisions: EdgeBriefDecision[];
  headline: string;
}

export interface EdgeFeedDecision {
  decisionId: string;
  edgeScore: number;
  recommendedAction: "act" | "watch" | "ignore" | string;
  reasonCodes: string[];
  explanationPreview: string;
  components: {
    urgency: number;
    recency: number;
    relevance: number;
    novelty: number;
    penalties: number;
  };
  update: {
    id: string;
    title: string;
    urgency: "high" | "medium" | "low" | string;
    createdAt: string;
    projectId: string;
    projectName: string;
    projectSlug: string;
    secondaryTagIds: string[];
  };
}

export interface EdgeFeedResponse {
  asOf: string;
  enabled: boolean;
  limit: number;
  nextCursor: string | null;
  items: EdgeFeedDecision[];
}

export interface EdgeExplainResponse {
  asOf: string;
  enabled: boolean;
  decisionId: string;
  update?: {
    id: string;
    title: string;
    urgency: "high" | "medium" | "low" | string;
    createdAt: string;
    projectId: string;
    projectName: string;
    projectSlug: string;
    secondaryTagIds: string[];
  };
  explanation?: {
    edgeScore: number;
    recommendedAction: "act" | "watch" | "ignore" | string;
    reasonCodes: string[];
    explanationPreview: string;
    weights: {
      urgency: number;
      recency: number;
      relevance: number;
      novelty: number;
    };
    components: {
      urgency: number;
      recency: number;
      relevance: number;
      novelty: number;
      penalties: number;
    };
    narrative: string;
  };
  message?: string;
}

export interface EdgeFeedbackResponse {
  ok: boolean;
  decisionId: string;
  action: "act" | "watch" | "ignore" | string;
  persisted: boolean;
  feedbackId: string | null;
  recordedAt: string;
}

export interface AdminEdgeOverviewResponse {
  asOf: string;
  enabled: boolean;
  windowDays: number;
  totals: {
    decisions: number;
    uniqueUsers: number;
    uniqueProjects: number;
    avgEdgeScore: number;
    recommendedActionCounts: {
      act: number;
      watch: number;
      ignore: number;
    };
    highUrgencyDecisions: number;
  };
  feedback: {
    total: number;
    act: number;
    watch: number;
    ignore: number;
    feedbackRate: number;
    lastFeedbackAt: string | null;
  };
  telemetry: {
    feedViews: number;
    briefViews: number;
    explainViews: number;
    feedbackEvents: number;
  };
  topProjects: Array<{
    projectId: string;
    projectName: string;
    projectSlug: string;
    decisionCount: number;
    highUrgencyCount: number;
    avgEdgeScore: number;
    lastDecisionAt: string | null;
  }>;
  topReasons: {
    sampledDecisions: number;
    items: Array<{
      reasonCode: string;
      count: number;
    }>;
  };
  topDecisions: Array<{
    decisionId: string;
    edgeScore: number;
    recommendedAction: "act" | "watch" | "ignore" | string;
    reasonCodes: string[];
    explanationPreview: string;
    generatedAt: string;
    user: {
      id: string;
      email: string;
      displayName: string | null;
    };
    project: {
      id: string;
      name: string;
      slug: string;
    };
    update: {
      id: string;
      title: string;
      urgency: "high" | "medium" | "low" | string;
      createdAt: string;
    };
    components: {
      urgency: number;
      recency: number;
      relevance: number;
      novelty: number;
      penalties: number;
    };
  }>;
}

export interface AdminEdgeConfig {
  id: string;
  enabled: boolean;
  updatedAt: string;
}

