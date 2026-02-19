import { BadRequestException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

export const DECIMAL_ZERO = new Prisma.Decimal(0);

export function parsePositiveDecimal(
  value: string | number,
  fieldName: string,
): Prisma.Decimal {
  let decimal: Prisma.Decimal;
  try {
    decimal = new Prisma.Decimal(value);
  } catch {
    throw new BadRequestException(`${fieldName} must be a valid decimal value`);
  }

  if (decimal.lte(DECIMAL_ZERO)) {
    throw new BadRequestException(`${fieldName} must be greater than zero`);
  }

  return decimal;
}

export function decimalMin(
  left: Prisma.Decimal,
  right: Prisma.Decimal,
): Prisma.Decimal {
  return left.lte(right) ? left : right;
}

export function decimalMax(
  left: Prisma.Decimal,
  right: Prisma.Decimal,
): Prisma.Decimal {
  return left.gte(right) ? left : right;
}

export function toDecimalString(
  value: Prisma.Decimal | string | number | null | undefined,
): string {
  if (value === null || value === undefined) {
    return '0';
  }

  if (value instanceof Prisma.Decimal) {
    return value.toString();
  }

  return new Prisma.Decimal(value).toString();
}
