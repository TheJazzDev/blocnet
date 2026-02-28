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
  ml: {
    enabled: boolean;
    analyzedDecisions: number;
    coverageRate: number;
    avgQuality: number;
    avgActionability: number;
    sentiments: {
      positive: number;
      neutral: number;
      negative: number;
      other: number;
    };
    providers: Array<{
      provider: string;
      count: number;
    }>;
    topTopics: Array<{
      topic: string;
      count: number;
    }>;
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
    ml: {
      quality: number | null;
      sentiment: string | null;
      topics: string[];
      actionability: number | null;
      insights: string[];
      provider: string | null;
    };
  }>;
}

export interface AdminEdgeConfig {
  id: string;
  enabled: boolean;
  mlEnabled: boolean;
  mlUrl: string;
  mlTimeout: number;
  mlProvider: string;
  mlWebSearch: boolean;
  mlOllamaModel: string;
  mlOllamaEmbeddingModel: string;
  mlOllamaTimeout: number;
  mlGroqModel: string;
  mlGeminiModel: string;
  mlGeminiEmbeddingModel: string;
  mlCacheTtl: number;
  mlMaxContentLength: number;
  updatedAt: string;
}

export interface AdminEdgeRecomputeResponse {
  ok: boolean;
  mlEnabled: boolean;
  windowDays: number;
  requestedUsers: number;
  processedUsers: number;
  successfulUsers: number;
  failedUsers: number;
  totalSignals: number;
  details: Array<{
    userId: string;
    ok: boolean;
    totalSignals: number;
    headline: string | null;
    error: string | null;
  }>;
  ranAt: string;
}
