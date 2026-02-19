import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash } from 'crypto';
import {
  CreateCustodyWalletInput,
  CustodyAdapter,
  CustodyWalletRecord,
} from './custody.adapter';

@Injectable()
export class TurnkeyCustodyAdapter implements CustodyAdapter {
  constructor(private readonly configService: ConfigService) {}

  private createMockWallet(input: CreateCustodyWalletInput): CustodyWalletRecord {
    const hash = createHash('sha256')
      .update(`${input.userId}:${input.idempotencyKey}`)
      .digest('hex');

    return {
      providerWalletId: `mock_${hash.slice(0, 24)}`,
      address: `0x${hash.slice(0, 40)}`,
    };
  }

  async createWallet(
    input: CreateCustodyWalletInput,
  ): Promise<CustodyWalletRecord> {
    const devMock = this.configService.get<boolean>('TURNKEY_DEV_MOCK') ?? false;
    const nodeEnv = this.configService.get<string>('NODE_ENV') ?? 'development';

    if (devMock) {
      return this.createMockWallet(input);
    }

    // Real Turnkey request signing is not wired yet. For non-production
    // environments, always return deterministic mock wallets so product flows
    // stay testable without custody credentials.
    if (nodeEnv !== 'production') {
      return this.createMockWallet(input);
    }

    const organizationId = this.configService.get<string>(
      'TURNKEY_ORGANIZATION_ID',
    );
    const apiPublicKey = this.configService.get<string>('TURNKEY_API_PUBLIC_KEY');
    const apiPrivateKey = this.configService.get<string>(
      'TURNKEY_API_PRIVATE_KEY',
    );

    if (!organizationId || !apiPublicKey || !apiPrivateKey) {
      throw new ServiceUnavailableException(
        'Turnkey credentials are not configured',
      );
    }

    // TODO: replace with signed Turnkey wallet creation request when
    // production API credentials + signing flow are fully configured.
    throw new ServiceUnavailableException(
      `Turnkey wallet provisioning is not active yet (userId=${input.userId})`,
    );
  }
}
