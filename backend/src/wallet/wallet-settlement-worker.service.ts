import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { ChainEnvironment } from '@prisma/client';
import { createPublicClient, http, type PublicClient } from 'viem';
import {
  WalletConfigService,
  type WalletDepositNetworkConfig,
} from './wallet-config.service';
import { DatabaseHealthService } from '../prisma/database-health.service';
import { WalletSweepService } from './wallet-sweep.service';
import { WalletWithdrawalSettlementService } from './wallet-withdrawal-settlement.service';

@Injectable()
export class WalletSettlementWorkerService
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(WalletSettlementWorkerService.name);
  private readonly clients = new Map<ChainEnvironment, PublicClient>();

  private intervalHandle: NodeJS.Timeout | null = null;
  private isTickRunning = false;
  private lastDbUnavailableLogAt = 0;

  constructor(
    private readonly walletConfigService: WalletConfigService,
    private readonly databaseHealthService: DatabaseHealthService,
    private readonly walletSweepService: WalletSweepService,
    private readonly walletWithdrawalSettlementService: WalletWithdrawalSettlementService,
  ) {}

  onModuleInit(): void {
    const intervalMs = Math.min(
      this.walletConfigService.depositPollIntervalMs,
      this.walletConfigService.withdrawalPollIntervalMs,
    );

    this.intervalHandle = setInterval(() => {
      void this.tick();
    }, intervalMs);

    void this.tick();
    this.logger.log(
      `Wallet settlement worker started (interval=${intervalMs}ms)`,
    );
  }

  onModuleDestroy(): void {
    if (this.intervalHandle) {
      clearInterval(this.intervalHandle);
      this.intervalHandle = null;
    }
  }

  private async tick(): Promise<void> {
    if (this.isTickRunning) {
      return;
    }

    this.isTickRunning = true;
    try {
      if (!this.walletConfigService.walletEnabled) {
        return;
      }

      const databaseHealthy =
        await this.databaseHealthService.isDatabaseHealthy();
      if (!databaseHealthy) {
        this.logDbUnavailableSkip();
        return;
      }

      if (this.walletConfigService.depositsEnabled) {
        await this.queueDepositSweeps();
        await this.processSweepJobs();
      }

      if (this.walletConfigService.withdrawalsEnabled) {
        await this.processApprovedWithdrawals();
        await this.processBroadcastingWithdrawals();
      }
    } catch (error) {
      this.logger.error(
        `Wallet settlement tick failed: ${this.errorMessage(error)}`,
      );
    } finally {
      this.isTickRunning = false;
    }
  }

  private async queueDepositSweeps(): Promise<void> {
    await this.walletSweepService.queueDepositSweeps();
  }

  private async processSweepJobs(): Promise<void> {
    await this.walletSweepService.processSweepJobs();
  }

  private async processApprovedWithdrawals(): Promise<void> {
    await this.walletWithdrawalSettlementService.processApprovedWithdrawals();
  }

  private async processBroadcastingWithdrawals(): Promise<void> {
    await this.walletWithdrawalSettlementService.processBroadcastingWithdrawals(
      (network) => this.getClient(network),
    );
  }

  private getClient(network: WalletDepositNetworkConfig): PublicClient {
    const existing = this.clients.get(network.chainEnvironment);
    if (existing) {
      return existing;
    }

    const client = createPublicClient({
      transport: http(network.rpcUrl),
    });
    this.clients.set(network.chainEnvironment, client);
    return client;
  }

  private errorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    return String(error);
  }

  private logDbUnavailableSkip() {
    const now = Date.now();
    if (now - this.lastDbUnavailableLogAt < 60_000) {
      return;
    }
    this.lastDbUnavailableLogAt = now;
    this.logger.warn(
      'Skipping settlement tick because database is unavailable.',
    );
  }
}
