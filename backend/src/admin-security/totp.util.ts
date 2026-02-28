import { createHmac, randomBytes } from 'crypto';

const BASE32_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

function stripBase32Padding(input: string): string {
  return input.replace(/=+$/g, '');
}

function normalizeBase32(input: string): string {
  return stripBase32Padding(input)
    .toUpperCase()
    .replace(/\s+/g, '')
    .replace(/-/g, '');
}

export function base32Encode(bytes: Buffer): string {
  let bits = 0;
  let value = 0;
  let output = '';

  for (const byte of bytes) {
    value = (value << 8) | byte;
    bits += 8;

    while (bits >= 5) {
      output += BASE32_ALPHABET[(value >>> (bits - 5)) & 31];
      bits -= 5;
    }
  }

  if (bits > 0) {
    output += BASE32_ALPHABET[(value << (5 - bits)) & 31];
  }

  return output;
}

export function base32Decode(base32: string): Buffer {
  const normalized = normalizeBase32(base32);
  if (!normalized) {
    return Buffer.alloc(0);
  }

  let bits = 0;
  let value = 0;
  const output: number[] = [];

  for (const char of normalized) {
    const index = BASE32_ALPHABET.indexOf(char);
    if (index < 0) {
      throw new Error('Invalid base32 secret');
    }

    value = (value << 5) | index;
    bits += 5;

    if (bits >= 8) {
      output.push((value >>> (bits - 8)) & 0xff);
      bits -= 8;
    }
  }

  return Buffer.from(output);
}

export function generateTotpSecret(length = 20): string {
  return base32Encode(randomBytes(length));
}

export function buildOtpAuthUrl(input: {
  issuer: string;
  accountName: string;
  secret: string;
  algorithm?: 'SHA1' | 'SHA256' | 'SHA512';
  digits?: number;
  period?: number;
}): string {
  const algorithm = input.algorithm ?? 'SHA1';
  const digits = input.digits ?? 6;
  const period = input.period ?? 30;
  const label = `${input.issuer}:${input.accountName}`;
  const query = new URLSearchParams({
    secret: input.secret,
    issuer: input.issuer,
    algorithm,
    digits: String(digits),
    period: String(period),
  });

  return `otpauth://totp/${encodeURIComponent(label)}?${query.toString()}`;
}

function hotp(secret: Buffer, counter: bigint, digits: number): string {
  const counterBuffer = Buffer.alloc(8);
  counterBuffer.writeBigUInt64BE(counter);

  const hmac = createHmac('sha1', secret).update(counterBuffer).digest();
  const offset = hmac[hmac.length - 1] & 0x0f;

  const binaryCode =
    ((hmac[offset] & 0x7f) << 24) |
    ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) |
    (hmac[offset + 3] & 0xff);

  const otp = binaryCode % 10 ** digits;
  return otp.toString().padStart(digits, '0');
}

function normalizeToken(input: string): string {
  return input.replace(/\s+/g, '').replace(/-/g, '');
}

export function verifyTotpCode(input: {
  secret: string;
  token: string;
  at?: Date;
  stepSeconds?: number;
  digits?: number;
  window?: number;
}): boolean {
  const token = normalizeToken(input.token);
  const digits = input.digits ?? 6;

  if (!/^\d+$/.test(token) || token.length !== digits) {
    return false;
  }

  const secretBytes = base32Decode(input.secret);
  if (!secretBytes.length) {
    return false;
  }

  const stepSeconds = input.stepSeconds ?? 30;
  const window = input.window ?? 1;
  const unixTime = Math.floor((input.at ?? new Date()).getTime() / 1000);
  const counter = BigInt(Math.floor(unixTime / stepSeconds));

  for (let offset = -window; offset <= window; offset += 1) {
    const candidate = hotp(secretBytes, counter + BigInt(offset), digits);
    if (candidate === token) {
      return true;
    }
  }

  return false;
}
