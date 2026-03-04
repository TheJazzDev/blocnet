import { Injectable, Logger } from '@nestjs/common';
import axios, { AxiosError, AxiosInstance } from 'axios';
import { PrismaService } from '../prisma/prisma.service';
import { EDGE_CONFIG_ID } from './edge-engine.utils';

/**
 * ML analysis result from BEE service.
 */
export interface MLAnalysisResult {
  quality: number; // 0-1
  sentiment: 'positive' | 'neutral' | 'negative';
  topics: string[];
  urgency_justification: string;
  actionability: number; // 0-1
  key_insights: string[];
  web_context_used: boolean;
}

/**
 * BEE service response for analysis.
 */
export interface BeeAnalysisResponse {
  analysis: MLAnalysisResult;
  provider_used: string;
  cached: boolean;
}

/**
 * Embedding result from BEE service.
 */
export interface BeeEmbeddingResponse {
  embedding: {
    embedding: number[];
    model: string;
    dimensions: number;
  };
  provider_used: string;
  cached: boolean;
}

type EdgeMLConfig = {
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
};

/**
 * ML Client Service
 *
 * Integrates NestJS backend with BEE ML service for AI-powered content analysis.
 * Reads configuration from EdgeConfig database table (runtime admin-controlled settings).
 * Provides fallback to default scoring if BEE is unavailable.
 */
@Injectable()
export class MLClientService {
  private readonly logger = new Logger(MLClientService.name);
  private static readonly CONFIG_CACHE_TTL_MS = 30_000;
  private static readonly CIRCUIT_FAIL_THRESHOLD = 3;
  private static readonly CIRCUIT_OPEN_MS = 45_000;
  private configCache: EdgeMLConfig | null = null;
  private configCacheExpiresAt = 0;
  private consecutiveMlFailures = 0;
  private mlCircuitOpenUntil = 0;

  constructor(private readonly prisma: PrismaService) {}

  private formatError(error: unknown): { message: string; stack?: string } {
    if (error instanceof Error) {
      return { message: error.message, stack: error.stack };
    }
    return { message: String(error) };
  }

  /**
   * Get ML configuration from database.
   */
  private async getMLConfig(): Promise<EdgeMLConfig> {
    const now = Date.now();
    if (this.configCache && now < this.configCacheExpiresAt) {
      return this.configCache;
    }

    const config = await this.prisma.edgeConfig.findUnique({
      where: { id: EDGE_CONFIG_ID },
      select: {
        mlEnabled: true,
        mlUrl: true,
        mlTimeout: true,
        mlProvider: true,
        mlWebSearch: true,
        mlOllamaModel: true,
        mlOllamaEmbeddingModel: true,
        mlOllamaTimeout: true,
        mlGroqModel: true,
        mlGeminiModel: true,
        mlGeminiEmbeddingModel: true,
        mlCacheTtl: true,
        mlMaxContentLength: true,
      },
    });

    const resolved =
      config ?? {
        mlEnabled: false,
        mlUrl: 'http://localhost:8083',
        mlTimeout: 10000,
        mlProvider: 'auto',
        mlWebSearch: false,
        mlOllamaModel: 'llama3.3:70b',
        mlOllamaEmbeddingModel: 'nomic-embed-text',
        mlOllamaTimeout: 120000,
        mlGroqModel: 'llama-3.3-70b-versatile',
        mlGeminiModel: 'gemini-2.0-flash-exp',
        mlGeminiEmbeddingModel: 'models/text-embedding-004',
        mlCacheTtl: 86400,
        mlMaxContentLength: 10000,
      };

    this.configCache = resolved;
    this.configCacheExpiresAt = now + MLClientService.CONFIG_CACHE_TTL_MS;
    return resolved;
  }

  /**
   * Create axios client with current config.
   */
  private async createClient(timeoutOverrideMs?: number): Promise<AxiosInstance> {
    const config = await this.getMLConfig();
    return axios.create({
      baseURL: config.mlUrl,
      timeout: timeoutOverrideMs ?? config.mlTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  private isCircuitOpen(): boolean {
    return Date.now() < this.mlCircuitOpenUntil;
  }

  private registerMlSuccess(): void {
    this.consecutiveMlFailures = 0;
    this.mlCircuitOpenUntil = 0;
  }

  private registerMlFailure(error: unknown): void {
    if (!this.isRecoverableMlNetworkError(error)) {
      return;
    }

    this.consecutiveMlFailures += 1;
    if (this.consecutiveMlFailures >= MLClientService.CIRCUIT_FAIL_THRESHOLD) {
      this.mlCircuitOpenUntil = Date.now() + MLClientService.CIRCUIT_OPEN_MS;
      this.logger.warn(
        `ML circuit opened for ${MLClientService.CIRCUIT_OPEN_MS}ms after ${this.consecutiveMlFailures} recoverable failure(s)`,
      );
    }
  }

  private isRecoverableMlNetworkError(error: unknown): boolean {
    const axiosError = error as AxiosError | undefined;
    const code = axiosError?.code?.toUpperCase() ?? '';
    const message = (axiosError?.message ?? String(error)).toUpperCase();

    return (
      code.includes('ENOTFOUND') ||
      code.includes('ECONNREFUSED') ||
      code.includes('ETIMEDOUT') ||
      code.includes('EAI_AGAIN') ||
      message.includes('ENOTFOUND') ||
      message.includes('ECONNREFUSED') ||
      message.includes('ETIMEDOUT') ||
      message.includes('EAI_AGAIN')
    );
  }

  /**
   * Analyze update content using BEE ML service.
   *
   * @param content - Update content to analyze
   * @param context - Optional context (web data, user prefs)
   * @param requireWebSearch - Whether to use web search
   * @returns ML analysis result or null if failed/disabled
   */
  async analyzeContent(
    content: string,
    context?: Record<string, any>,
    requireWebSearch = false,
    timeoutMs?: number,
  ): Promise<MLAnalysisResult | null> {
    const config = await this.getMLConfig();

    if (!config.mlEnabled) {
      this.logger.debug('BEE ML is disabled, skipping analysis');
      return null;
    }

    if (!content || content.trim().length === 0) {
      this.logger.warn('Empty content provided for analysis');
      return null;
    }

    if (this.isCircuitOpen()) {
      this.logger.warn('ML circuit is open, skipping content analysis');
      return null;
    }

    try {
      this.logger.debug(`Analyzing content (${content.length} chars)`);
      const client = await this.createClient(timeoutMs);

      const response = await client.post<BeeAnalysisResponse>('/analyze', {
        content,
        context,
        require_web_search: requireWebSearch || config.mlWebSearch,
        provider: config.mlProvider === 'auto' ? undefined : config.mlProvider,
      });

      this.logger.debug(
        `Analysis complete: provider=${response.data.provider_used}, quality=${response.data.analysis.quality}`,
      );
      this.registerMlSuccess();

      return response.data.analysis;
    } catch (error: unknown) {
      this.registerMlFailure(error);
      const formatted = this.formatError(error);
      this.logger.error(
        `BEE analysis failed: ${formatted.message}`,
        formatted.stack,
      );
      return null; // Fallback to default scoring
    }
  }

  /**
   * Analyze multiple updates in batch.
   *
   * @param contents - Array of update contents
   * @param contexts - Optional array of contexts (same length as contents)
   * @returns Array of analysis results (null for failed items)
   */
  async analyzeBatch(
    contents: string[],
    contexts?: Record<string, any>[],
    timeoutMs?: number,
  ): Promise<(MLAnalysisResult | null)[]> {
    const config = await this.getMLConfig();

    if (!config.mlEnabled) {
      return contents.map(() => null);
    }

    if (contents.length === 0) {
      return [];
    }

    if (this.isCircuitOpen()) {
      this.logger.warn('ML circuit is open, skipping batch analysis');
      return contents.map(() => null);
    }

    try {
      this.logger.debug(`Analyzing batch of ${contents.length} items`);
      const client = await this.createClient(timeoutMs);

      const requests = contents.map((content, index) => ({
        content,
        context: contexts?.[index],
        require_web_search: config.mlWebSearch,
        provider: config.mlProvider === 'auto' ? undefined : config.mlProvider,
      }));

      const response = await client.post<BeeAnalysisResponse[]>(
        '/analyze/batch',
        requests,
      );

      this.logger.debug(
        `Batch analysis complete: ${response.data.length} results`,
      );
      this.registerMlSuccess();

      return response.data.map((item, index) => {
        if (item.provider_used === 'error') {
          this.logger.warn(
            `BEE batch item ${index} failed: ${item.analysis.urgency_justification}`,
          );
          return null;
        }

        return item.analysis;
      });
    } catch (error: unknown) {
      this.registerMlFailure(error);
      const formatted = this.formatError(error);
      this.logger.error(
        `BEE batch analysis failed: ${formatted.message}`,
        formatted.stack,
      );
      return contents.map(() => null); // Fallback to default scoring
    }
  }

  /**
   * Generate embedding for text.
   *
   * @param text - Text to embed
   * @returns Embedding vector or null if failed/disabled
   */
  async generateEmbedding(text: string): Promise<number[] | null> {
    const config = await this.getMLConfig();

    if (!config.mlEnabled) {
      return null;
    }

    if (!text || text.trim().length === 0) {
      return null;
    }

    try {
      this.logger.debug(`Generating embedding (${text.length} chars)`);
      const client = await this.createClient();

      const response = await client.post<BeeEmbeddingResponse>('/embed', {
        text,
      });

      this.logger.debug(
        `Embedding generated: model=${response.data.embedding.model}, dims=${response.data.embedding.dimensions}`,
      );

      return response.data.embedding.embedding;
    } catch (error: unknown) {
      const formatted = this.formatError(error);
      this.logger.error(
        `BEE embedding failed: ${formatted.message}`,
        formatted.stack,
      );
      return null;
    }
  }

  /**
   * Check BEE service health.
   *
   * @returns True if healthy, false otherwise
   */
  async checkHealth(): Promise<boolean> {
    const config = await this.getMLConfig();

    if (!config.mlEnabled) {
      return false;
    }

    try {
      const client = await this.createClient();
      const response = await client.get<{ status?: string }>('/health');
      return response.data.status === 'healthy';
    } catch (error: unknown) {
      const formatted = this.formatError(error);
      this.logger.error(`BEE health check failed: ${formatted.message}`);
      return false;
    }
  }

  /**
   * Check if BEE ML is enabled (fetches current config from database).
   */
  async isEnabled(): Promise<boolean> {
    const config = await this.getMLConfig();
    return config.mlEnabled;
  }
}
