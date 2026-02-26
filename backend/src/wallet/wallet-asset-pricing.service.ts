import { Injectable, Logger } from '@nestjs/common';
import { Prisma, WalletAsset } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { getDefaultPriceProviderId, WALLET_ASSETS } from './wallet-asset.util';

type PriceSource = 'live' | 'fallback';

type CachedPrice = {
  usdPrice: string;
  source: PriceSource;
  providerId: string | null;
  expiresAt: number;
};

@Injectable()
export class WalletAssetPricingService {
  private readonly logger = new Logger(WalletAssetPricingService.name);
  private readonly cache = new Map<WalletAsset, CachedPrice>();
  private static readonly CACHE_TTL_MS = 60_000;
  private static readonly DEFAULT_TIMEOUT_MS = 3500;

  constructor(private readonly prisma: PrismaService) {}

  async listPriceConfigs() {
    return this.prisma.walletAssetPriceConfig.findMany({
      orderBy: { asset: 'asc' },
    });
  }

  async updatePriceConfig(
    asset: WalletAsset,
    input: {
      providerId?: string | null;
      fallbackUsdPrice?: string;
      isActive?: boolean;
    },
  ) {
    const updated = await this.prisma.walletAssetPriceConfig.upsert({
      where: { asset },
      update: {
        ...(input.providerId !== undefined
          ? { providerId: input.providerId?.trim() || null }
          : {}),
        ...(input.fallbackUsdPrice !== undefined
          ? {
              fallbackUsdPrice: this.parseNonNegativeDecimal(
                input.fallbackUsdPrice,
              ),
            }
          : {}),
        ...(input.isActive !== undefined ? { isActive: input.isActive } : {}),
      },
      create: {
        asset,
        providerId:
          input.providerId?.trim() || getDefaultPriceProviderId(asset),
        fallbackUsdPrice:
          input.fallbackUsdPrice !== undefined
            ? this.parseNonNegativeDecimal(input.fallbackUsdPrice)
            : new Prisma.Decimal(0),
        isActive: input.isActive ?? true,
      },
    });

    this.cache.delete(asset);
    return updated;
  }

  async getUsdPrice(asset: WalletAsset) {
    const now = Date.now();
    const cached = this.cache.get(asset);
    if (cached && cached.expiresAt > now) {
      return {
        asset,
        usdPrice: cached.usdPrice,
        source: cached.source,
        providerId: cached.providerId,
      };
    }

    const config = await this.resolveConfig(asset);
    const fallbackUsd = config.fallbackUsdPrice.toString();
    const providerId = config.providerId?.trim() || null;

    if (!config.isActive || !providerId) {
      this.cache.set(asset, {
        usdPrice: fallbackUsd,
        source: 'fallback',
        providerId,
        expiresAt: now + WalletAssetPricingService.CACHE_TTL_MS,
      });
      return {
        asset,
        usdPrice: fallbackUsd,
        source: 'fallback' as PriceSource,
        providerId,
      };
    }

    const live = await this.fetchUsdPrice(providerId);
    if (live !== null) {
      this.cache.set(asset, {
        usdPrice: live,
        source: 'live',
        providerId,
        expiresAt: now + WalletAssetPricingService.CACHE_TTL_MS,
      });
      return {
        asset,
        usdPrice: live,
        source: 'live' as PriceSource,
        providerId,
      };
    }

    this.cache.set(asset, {
      usdPrice: fallbackUsd,
      source: 'fallback',
      providerId,
      expiresAt: now + WalletAssetPricingService.CACHE_TTL_MS,
    });
    return {
      asset,
      usdPrice: fallbackUsd,
      source: 'fallback' as PriceSource,
      providerId,
    };
  }

  async getUsdPrices(assets: WalletAsset[] = WALLET_ASSETS) {
    const entries = await Promise.all(
      assets.map(
        async (asset) => [asset, await this.getUsdPrice(asset)] as const,
      ),
    );
    return Object.fromEntries(entries) as Record<
      WalletAsset,
      {
        asset: WalletAsset;
        usdPrice: string;
        source: PriceSource;
        providerId: string | null;
      }
    >;
  }

  private async resolveConfig(asset: WalletAsset) {
    const existing = await this.prisma.walletAssetPriceConfig.findUnique({
      where: { asset },
    });
    if (existing) return existing;

    return this.prisma.walletAssetPriceConfig.create({
      data: {
        asset,
        providerId: getDefaultPriceProviderId(asset),
        fallbackUsdPrice: new Prisma.Decimal(0),
        isActive: true,
      },
    });
  }

  private async fetchUsdPrice(providerId: string): Promise<string | null> {
    const controller = new AbortController();
    const timeoutHandle = setTimeout(
      () => controller.abort(),
      WalletAssetPricingService.DEFAULT_TIMEOUT_MS,
    );

    try {
      const response = await fetch(
        `https://api.coingecko.com/api/v3/simple/price?ids=${encodeURIComponent(
          providerId,
        )}&vs_currencies=usd`,
        { signal: controller.signal },
      );

      if (!response.ok) {
        return null;
      }

      const payload = (await response.json()) as Record<
        string,
        { usd?: number }
      >;
      const usd = payload?.[providerId]?.usd;
      if (typeof usd !== 'number' || !Number.isFinite(usd) || usd < 0) {
        return null;
      }

      return usd.toString();
    } catch (error) {
      this.logger.debug(
        `Price lookup failed provider=${providerId} reason=${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return null;
    } finally {
      clearTimeout(timeoutHandle);
    }
  }

  private parseNonNegativeDecimal(value: string): Prisma.Decimal {
    let decimal: Prisma.Decimal;
    try {
      decimal = new Prisma.Decimal(value);
    } catch {
      throw new Error('fallbackUsdPrice must be a valid decimal');
    }
    if (decimal.lt(new Prisma.Decimal(0))) {
      throw new Error('fallbackUsdPrice cannot be negative');
    }
    return decimal;
  }
}
