import { Prisma } from '@prisma/client';
import { WalletQueryService } from './wallet-query.service';
import { WalletAssetPricingService } from './wallet-asset-pricing.service';
import { WalletConfigService } from './wallet-config.service';
import { WalletProvisioningService } from './wallet-provisioning.service';
import { PrismaService } from '../prisma/prisma.service';

/**
 * `GET /wallet/health` is guarded by AuthGuard only, so every signed-in user
 * can call it. These tests pin the response down to user-facing fields and
 * guard against operational detail creeping back in.
 */
describe('WalletQueryService.getWalletHealth', () => {
  const wallet = {
    id: 'wallet-1',
    userId: 'user-1',
    status: 'active',
    address: '0xabc',
    chainId: 97,
    chainEnvironment: 'testnet',
    provider: 'turnkey',
    providerWalletId: 'tk-wallet-abc',
    failureReason: 'provider rejected sub-organization creation',
    provisionedAt: new Date('2026-01-01T00:00:00.000Z'),
  };

  const account = {
    available: new Prisma.Decimal('10.5'),
    pending: new Prisma.Decimal('1'),
    locked: new Prisma.Decimal('0'),
  };

  const walletProvisioningService = {
    ensureWalletForUser: jest.fn().mockResolvedValue(wallet),
    ensureUserLedgerAccount: jest.fn().mockResolvedValue(account),
  } as unknown as WalletProvisioningService;

  const walletConfigService = {
    walletEnabled: true,
    depositsEnabled: true,
    withdrawalsEnabled: false,
    turnkeyMode: 'real',
    turnkeyExecutionMode: 'real',
    bscRpcMainnet: 'https://secret-rpc.example/mainnet-key',
    bscRpcTestnet: 'https://secret-rpc.example/testnet-key',
    bntTokenAddressMainnet: '0xmainnettoken',
    bntTokenAddressTestnet: '0xtestnettoken',
    treasuryWalletIdMainnet: 'treasury-main',
    treasuryWalletIdTestnet: 'treasury-test',
    treasurySweepAddressMainnet: '0xsweepmain',
    treasurySweepAddressTestnet: '0xsweeptest',
  } as unknown as WalletConfigService;

  const prisma = {} as unknown as PrismaService;
  const walletAssetPricingService = {
    getUsdPrices: jest.fn(),
  } as unknown as WalletAssetPricingService;

  let service: WalletQueryService;

  beforeEach(() => {
    service = new WalletQueryService(
      prisma,
      walletConfigService,
      walletProvisioningService,
      walletAssetPricingService,
    );
  });

  it('returns the feature flags, the caller wallet, balances and public chain coordinates', async () => {
    const health = await service.getWalletHealth('user-1');

    expect(health.flags).toEqual({
      walletEnabled: true,
      userWalletEnabled: true,
      depositsEnabled: true,
      withdrawalsEnabled: false,
    });
    expect(health.wallet).toEqual({
      id: 'wallet-1',
      status: 'active',
      address: '0xabc',
      chainId: 97,
      chainEnvironment: 'testnet',
      provisionedAt: wallet.provisionedAt,
    });
    expect(health.balances).toEqual({
      available: '10.5',
      pending: '1',
      locked: '0',
    });
    expect(health.network).toEqual({
      chainEnvironment: 'testnet',
      chainId: 97,
      tokenAddress: '0xtestnettoken',
    });
  });

  it('does not expose custody mode, RPC or treasury state to a signed-in user', async () => {
    const health = await service.getWalletHealth('user-1');

    expect(health.flags).not.toHaveProperty('turnkeyMode');
    expect(health.flags).not.toHaveProperty('turnkeyExecutionMode');
    expect(health.network).not.toHaveProperty('rpcConfigured');
    expect(health.network).not.toHaveProperty('tokenAddressConfigured');
    expect(health.network).not.toHaveProperty('treasuryWalletIdConfigured');
    expect(health.network).not.toHaveProperty(
      'treasurySweepAddressConfigured',
    );
  });

  it('does not expose the custody provider id or provider failure strings', async () => {
    const health = await service.getWalletHealth('user-1');

    expect(health.wallet).not.toHaveProperty('provider');
    expect(health.wallet).not.toHaveProperty('providerWalletId');
    expect(health.wallet).not.toHaveProperty('failureReason');
  });

  it('never serialises an RPC URL anywhere in the payload', async () => {
    const health = await service.getWalletHealth('user-1');

    expect(JSON.stringify(health)).not.toContain('secret-rpc.example');
  });

  it('reports a disabled wallet through userWalletEnabled', async () => {
    (
      walletProvisioningService.ensureWalletForUser as jest.Mock
    ).mockResolvedValueOnce({
      ...wallet,
      status: 'disabled',
    });

    const health = await service.getWalletHealth('user-1');

    expect(health.flags.userWalletEnabled).toBe(false);
  });
});
