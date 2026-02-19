import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class WalletConfigService {
  constructor(private readonly configService: ConfigService) {}

  get walletEnabled(): boolean {
    return this.configService.get<boolean>('WALLET_ENABLED') ?? false;
  }

  get depositsEnabled(): boolean {
    return this.configService.get<boolean>('DEPOSITS_ENABLED') ?? false;
  }

  get withdrawalsEnabled(): boolean {
    return this.configService.get<boolean>('WITHDRAWALS_ENABLED') ?? false;
  }

  get bscTestnetChainId(): number {
    return this.configService.get<number>('BSC_CHAIN_ID_TESTNET') ?? 97;
  }

  get bscMainnetChainId(): number {
    return this.configService.get<number>('BSC_CHAIN_ID_MAINNET') ?? 56;
  }
}
