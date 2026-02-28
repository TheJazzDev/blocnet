import { Injectable, Logger } from '@nestjs/common';
import axios, { AxiosInstance } from 'axios';
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

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get ML configuration from database.
   */
  private async getMLConfig(): Promise<EdgeMLConfig> {
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

    return (
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
      }
    );
  }

  /**
   * Create axios client with current config.
   */
  private async createClient(): Promise<AxiosInstance> {
    const config = await this.getMLConfig();
    return axios.create({
      baseURL: config.mlUrl,
      timeout: config.mlTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    });
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

    try {
      this.logger.debug(`Analyzing content (${content.length} chars)`);
      const client = await this.createClient();

      const response = await client.post<BeeAnalysisResponse>('/analyze', {
        content,
        context,
        require_web_search: requireWebSearch || config.mlWebSearch,
        provider: config.mlProvider === 'auto' ? undefined : config.mlProvider,
      });

      this.logger.debug(
        `Analysis complete: provider=${response.data.provider_used}, quality=${response.data.analysis.quality}`,
      );

      return response.data.analysis;
    } catch (error) {
      this.logger.error(`BEE analysis failed: ${error.message}`, error.stack);
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
  ): Promise<(MLAnalysisResult | null)[]> {
    const config = await this.getMLConfig();

    if (!config.mlEnabled) {
      return contents.map(() => null);
    }

    if (contents.length === 0) {
      return [];
    }

    try {
      this.logger.debug(`Analyzing batch of ${contents.length} items`);
      const client = await this.createClient();

      const requests = contents.map((content, index) => ({
        content,
        context: contexts?.[index],
        require_web_search: config.mlWebSearch,
        provider: config.mlProvider === 'auto' ? undefined : config.mlProvider,
      }));

      const response = await client.post<BeeAnalysisResponse[]>('/analyze/batch', requests);

      this.logger.debug(`Batch analysis complete: ${response.data.length} results`);

      return response.data.map((item, index) => {
        if (item.provider_used === 'error') {
          this.logger.warn(
            `BEE batch item ${index} failed: ${item.analysis.urgency_justification}`,
          );
          return null;
        }

        return item.analysis;
      });
    } catch (error) {
      this.logger.error(`BEE batch analysis failed: ${error.message}`, error.stack);
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
    } catch (error) {
      this.logger.error(`BEE embedding failed: ${error.message}`, error.stack);
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
      const response = await client.get('/health');
      return response.data.status === 'healthy';
    } catch (error) {
      this.logger.error(`BEE health check failed: ${error.message}`);
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
