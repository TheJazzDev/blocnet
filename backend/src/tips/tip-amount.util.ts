import { BadRequestException } from '@nestjs/common';

const DECIMAL_PATTERN = /^\d+(?:\.\d+)?$/;

export function parseAtomicAmount(
  raw: string,
  decimals: number,
  field = 'amount',
): bigint {
  const value = raw.trim();
  if (!value || !DECIMAL_PATTERN.test(value)) {
    throw new BadRequestException(`${field} must be a valid positive number`);
  }

  const [wholePart, fractionPart = ''] = value.split('.');
  if (fractionPart.length > decimals) {
    throw new BadRequestException(
      `${field} supports up to ${decimals} decimal places`,
    );
  }

  const whole = BigInt(wholePart);
  const fraction = fractionPart.padEnd(decimals, '0');
  const fractionAtomic = fraction ? BigInt(fraction) : 0n;
  const multiplier = 10n ** BigInt(decimals);
  const result = whole * multiplier + fractionAtomic;

  if (result <= 0n) {
    throw new BadRequestException(`${field} must be greater than 0`);
  }

  return result;
}

export function parseAtomicAmountAllowZero(
  raw: string,
  decimals: number,
  field = 'amount',
): bigint {
  const value = raw.trim();
  if (!value || !DECIMAL_PATTERN.test(value)) {
    throw new BadRequestException(`${field} must be a valid positive number`);
  }

  const [wholePart, fractionPart = ''] = value.split('.');
  if (fractionPart.length > decimals) {
    throw new BadRequestException(
      `${field} supports up to ${decimals} decimal places`,
    );
  }

  const whole = BigInt(wholePart);
  const fraction = fractionPart.padEnd(decimals, '0');
  const fractionAtomic = fraction ? BigInt(fraction) : 0n;
  const multiplier = 10n ** BigInt(decimals);
  const result = whole * multiplier + fractionAtomic;

  if (result < 0n) {
    throw new BadRequestException(`${field} must be zero or greater`);
  }

  return result;
}

export function formatAtomicAmount(value: bigint, decimals: number): string {
  const multiplier = 10n ** BigInt(decimals);
  const sign = value < 0n ? '-' : '';
  const absolute = value < 0n ? -value : value;
  const whole = absolute / multiplier;
  const fraction = absolute % multiplier;

  if (decimals === 0) {
    return `${sign}${whole.toString()}`;
  }

  const fractionRaw = fraction.toString().padStart(decimals, '0');
  const fractionTrimmed = fractionRaw.replace(/0+$/, '');
  if (!fractionTrimmed) {
    return `${sign}${whole.toString()}`;
  }

  return `${sign}${whole.toString()}.${fractionTrimmed}`;
}

export function ceilDivide(numerator: bigint, denominator: bigint): bigint {
  if (denominator <= 0n) {
    throw new BadRequestException('Invalid division denominator');
  }
  if (numerator <= 0n) {
    return 0n;
  }
  return (numerator + denominator - 1n) / denominator;
}
