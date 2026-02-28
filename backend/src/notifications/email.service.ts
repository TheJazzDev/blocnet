import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { buildBlocnetLink } from './utils/blocnet-link.util';

type AdminBroadcastEmailRecipient = {
  userId: string;
  email: string;
  displayName?: string | null;
  username?: string | null;
};

@Injectable()
export class NotificationEmailService {
  private readonly logger = new Logger(NotificationEmailService.name);

  private readonly resendApiKey: string;
  private readonly fromAddress: string;
  private readonly fromName: string;
  private readonly replyTo: string | null;
  private readonly adminFromAddress: string;
  private readonly adminFromName: string;
  private readonly fromAllowlist: Set<string>;
  private readonly broadcastRatePerMinute: number;
  private readonly logoUrl: string;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    this.resendApiKey =
      this.configService.get<string>('RESEND_API_KEY')?.trim() ?? '';
    this.fromAddress =
      this.configService.get<string>('EMAIL_FROM_ADDRESS')?.trim() ??
      this.configService.get<string>('FROM_EMAIL')?.trim() ??
      '';
    this.fromName =
      this.configService.get<string>('EMAIL_FROM_NAME')?.trim() ??
      'Blocnet Digest';
    this.replyTo =
      this.configService.get<string>('EMAIL_REPLY_TO')?.trim() || null;
    this.adminFromAddress =
      this.configService.get<string>('EMAIL_ADMIN_FROM_ADDRESS')?.trim() ||
      this.fromAddress;
    this.adminFromName =
      this.configService.get<string>('EMAIL_ADMIN_FROM_NAME')?.trim() ||
      'Blocnet Updates';

    this.fromAllowlist = new Set(
      (this.configService.get<string>('EMAIL_FROM_ALLOWLIST') ?? '')
        .split(/[,\n;\s]+/)
        .map((item) => normalizeEmailAddress(item))
        .filter((item): item is string => Boolean(item)),
    );

    if (this.fromAddress) {
      this.fromAllowlist.add(normalizeEmailAddress(this.fromAddress) ?? '');
    }
    if (this.adminFromAddress) {
      this.fromAllowlist.add(
        normalizeEmailAddress(this.adminFromAddress) ?? '',
      );
    }
    this.fromAllowlist.delete('');

    this.broadcastRatePerMinute = clampNumber(
      Number(this.configService.get<string>('EMAIL_BROADCAST_RATE_PER_MINUTE')),
      1,
      600,
      120,
    );
    this.logoUrl =
      this.configService.get<string>('EMAIL_LOGO_URL')?.trim() ||
      'https://blocnet.app/logo2.png';
  }

  getStatus() {
    const configured =
      this.resendApiKey.length > 0 && this.fromAddress.length > 0;
    return {
      configured,
      reason: configured
        ? null
        : 'Missing RESEND_API_KEY or EMAIL_FROM_ADDRESS/FROM_EMAIL',
      defaultFromAddress: this.fromAddress,
      defaultFromName: this.fromName,
      adminFromAddress: this.adminFromAddress,
      adminFromName: this.adminFromName,
      allowedFromAddresses: [...this.fromAllowlist],
      replyTo: this.replyTo,
      broadcastRatePerMinute: this.broadcastRatePerMinute,
    };
  }

  async sendDigestEmail(input: {
    to: string;
    subject: string;
    html: string;
    text: string;
  }) {
    if (!this.isConfigured()) {
      this.logger.warn('Digest email skipped: email provider not configured');
      return { delivered: false, skipped: true };
    }

    await this.sendEmail({
      to: input.to,
      subject: input.subject,
      html: input.html,
      text: input.text,
      fromAddress: this.fromAddress,
      fromName: this.fromName,
      replyTo: this.replyTo,
    });

    return { delivered: true, skipped: false };
  }

  async sendCriticalEmail(input: {
    userId: string;
    title: string;
    body: string;
    deeplink?: string | null;
  }) {
    if (!this.isConfigured()) {
      return { delivered: false, skipped: true };
    }

    const profile = await this.prisma.profile.findUnique({
      where: { id: input.userId },
      select: {
        email: true,
        displayName: true,
        username: true,
        isDeactivated: true,
      },
    });

    if (!profile || profile.isDeactivated || !profile.email.trim()) {
      return { delivered: false, skipped: true };
    }

    const name =
      profile.displayName?.trim() ||
      profile.username?.trim() ||
      profile.email.split('@')[0] ||
      'there';

    const target = input.deeplink?.trim()
      ? `https://blocnet.app${input.deeplink.startsWith('/') ? '' : '/'}${input.deeplink}`
      : buildBlocnetLink('notifications');

    const subject = `Important Blocnet Notification: ${input.title}`;
    const html = `
<!doctype html>
<html>
  <body style="font-family:Arial,sans-serif;color:#0f172a;line-height:1.5;">
    <h2>Hi ${escapeHtml(name)},</h2>
    <p><strong>${escapeHtml(input.title)}</strong></p>
    <p>${escapeHtml(input.body)}</p>
    <p><a href="${target}">Open Blocnet</a></p>
  </body>
</html>
`.trim();

    const text = `Hi ${name},\n\n${input.title}\n${input.body}\n\nOpen Blocnet: ${target}`;

    await this.sendEmail({
      to: profile.email,
      subject,
      html,
      text,
      fromAddress: this.fromAddress,
      fromName: this.fromName,
      replyTo: this.replyTo,
    });

    return { delivered: true, skipped: false };
  }

  async sendAdminBroadcastEmails(input: {
    recipients: AdminBroadcastEmailRecipient[];
    subject: string;
    previewText?: string;
    message: string;
    fromAddress?: string | null;
    fromName?: string | null;
    replyTo?: string | null;
    ctaLabel?: string | null;
    ctaUrl?: string | null;
  }) {
    if (!this.isConfigured()) {
      return {
        delivered: 0,
        failed: 0,
        skipped: input.recipients.length,
        skippedReason: 'email provider not configured',
      };
    }

    if (!input.subject.trim() || !input.message.trim()) {
      throw new Error('Email subject and message are required');
    }

    const fromAddress = this.resolveFromAddress(input.fromAddress ?? null);
    const fromName = this.resolveFromName(input.fromName ?? null);
    const replyTo = normalizeEmailAddress(input.replyTo ?? this.replyTo);
    const ctaLabel = input.ctaLabel?.trim() || 'Open Blocnet App';
    const ctaUrl =
      normalizeHttpUrl(input.ctaUrl) ?? buildBlocnetLink('notifications');
    const previewText = input.previewText?.trim() || input.subject;

    const recipients = uniqueRecipients(input.recipients);
    let delivered = 0;
    let failed = 0;
    let skipped = 0;
    const minIntervalMs = Math.ceil(60_000 / this.broadcastRatePerMinute);

    for (let index = 0; index < recipients.length; index += 1) {
      const recipient = recipients[index];
      const to = normalizeEmailAddress(recipient.email);
      if (!to) {
        skipped += 1;
        continue;
      }

      const name =
        recipient.displayName?.trim() ||
        recipient.username?.trim() ||
        recipient.email.split('@')[0] ||
        'there';
      const html = this.composeAdminBroadcastHtml({
        greetingName: name,
        previewText,
        subject: input.subject.trim(),
        message: input.message.trim(),
        ctaLabel,
        ctaUrl,
      });
      const text = this.composeAdminBroadcastText({
        greetingName: name,
        subject: input.subject.trim(),
        message: input.message.trim(),
        ctaLabel,
        ctaUrl,
      });

      try {
        await this.sendEmail({
          to,
          subject: input.subject.trim(),
          html,
          text,
          fromAddress,
          fromName,
          replyTo,
        });
        delivered += 1;
      } catch (error) {
        failed += 1;
        this.logger.warn(
          `Admin broadcast email failed for ${recipient.userId}: ${
            error instanceof Error ? error.message : String(error)
          }`,
        );
      }

      if (index < recipients.length - 1 && minIntervalMs > 0) {
        await sleep(minIntervalMs);
      }
    }

    return {
      delivered,
      failed,
      skipped,
      skippedReason: null as string | null,
    };
  }

  private isConfigured() {
    return this.resendApiKey.length > 0 && this.fromAddress.length > 0;
  }

  private async sendEmail(input: {
    to: string;
    subject: string;
    html: string;
    text: string;
    fromAddress: string;
    fromName?: string | null;
    replyTo?: string | null;
  }) {
    const payload = {
      from: formatFromHeader(input.fromAddress, input.fromName),
      to: [input.to],
      subject: input.subject,
      html: input.html,
      text: input.text,
      ...(input.replyTo ? { reply_to: input.replyTo } : {}),
    };

    let lastError = '';
    let lastStatusCode: number | null = null;
    const maxAttempts = 5;
    for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.resendApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        let providerMessageId: string | null = null;
        try {
          const parsed = (await response.json()) as { id?: unknown };
          const rawId = parsed?.id;
          if (typeof rawId === 'string' && rawId.trim().length > 0) {
            providerMessageId = rawId.trim();
          }
        } catch {
          providerMessageId = null;
        }

        await this.recordEmailDispatchAudit({
          action: 'ops.email.resend.sent',
          resourceId: providerMessageId,
          metadata: {
            status: 'success',
            provider: 'resend',
            to: input.to,
            from: input.fromAddress,
            subject: input.subject,
            attempt: attempt + 1,
            maxAttempts,
            providerMessageId,
          },
        });
        return;
      }

      const message = await response.text();
      lastStatusCode = response.status;
      lastError = `Resend send failed (${response.status}): ${message}`;
      if (response.status === 429 && attempt < maxAttempts - 1) {
        const retryAfterSeconds = Number(
          response.headers.get('retry-after') ?? '0',
        );
        const retryDelayMs = Number.isFinite(retryAfterSeconds)
          ? Math.max(1, retryAfterSeconds) * 1000
          : 5000;
        await sleep(retryDelayMs);
        continue;
      }

      if (response.status >= 500 && attempt < maxAttempts - 1) {
        await sleep(1000 * (attempt + 1));
        continue;
      }

      throw new Error(lastError);
    }

    await this.recordEmailDispatchAudit({
      action: 'ops.email.resend.failed',
      metadata: {
        status: 'failed',
        provider: 'resend',
        to: input.to,
        from: input.fromAddress,
        subject: input.subject,
        statusCode: lastStatusCode,
        maxAttempts,
        error: truncateText(lastError, 500),
      },
    });

    throw new Error(lastError || 'Email send failed');
  }

  private async recordEmailDispatchAudit(input: {
    action: string;
    resourceId?: string | null;
    metadata: Record<string, unknown>;
  }) {
    try {
      await this.prisma.auditLog.create({
        data: {
          action: input.action,
          resourceType: 'email_dispatch',
          resourceId: input.resourceId ?? null,
          metadata: input.metadata as Prisma.InputJsonValue,
        },
      });
    } catch (error) {
      this.logger.warn(
        `Failed to record email dispatch audit event: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
    }
  }

  private resolveFromAddress(requestedFromAddress: string | null) {
    const requestedNormalized = normalizeEmailAddress(requestedFromAddress);
    const fallback = normalizeEmailAddress(this.adminFromAddress);
    const chosen = requestedNormalized || fallback;

    if (!chosen) {
      throw new Error('Admin from email is not configured');
    }

    if (this.fromAllowlist.size > 0 && !this.fromAllowlist.has(chosen)) {
      throw new Error(
        `From address "${chosen}" is not allowed. Configure EMAIL_FROM_ALLOWLIST.`,
      );
    }

    return chosen;
  }

  private resolveFromName(requestedFromName: string | null) {
    return requestedFromName?.trim() || this.adminFromName || 'Blocnet Updates';
  }

  private composeAdminBroadcastHtml(input: {
    greetingName: string;
    previewText: string;
    subject: string;
    message: string;
    ctaLabel: string;
    ctaUrl: string;
  }) {
    const paragraphs = input.message
      .split(/\r?\n\r?\n/g)
      .map((chunk) => chunk.trim())
      .filter(Boolean)
      .map(
        (chunk) =>
          `<p style="margin:0 0 12px 0;color:#334155;font-size:15px;line-height:1.7;">${escapeHtml(chunk).replaceAll('\n', '<br/>')}</p>`,
      )
      .join('');

    return `
<!doctype html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  </head>
  <body style="margin:0;padding:0;background:#0b1120;font-family:Inter,Arial,sans-serif;">
    <p style="display:none;visibility:hidden;opacity:0;height:0;width:0;overflow:hidden;">${escapeHtml(input.previewText)}</p>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#0b1120;padding:22px 8px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:640px;background:#f8fafc;border-radius:18px;overflow:hidden;border:1px solid #e2e8f0;">
            <tr>
              <td style="padding:20px;background:#0f172a;color:#e2e8f0;">
                <table role="presentation" cellpadding="0" cellspacing="0">
                  <tr>
                    <td style="padding-right:10px;">
                      <img src="${this.logoUrl}" alt="Blocnet" width="40" height="40" style="display:block;border-radius:10px;background:#fff;padding:4px;" />
                    </td>
                    <td style="font-size:16px;font-weight:700;letter-spacing:0.2px;">Blocnet</td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr>
              <td style="padding:22px;">
                <p style="margin:0 0 12px 0;color:#334155;font-size:15px;">Hi ${escapeHtml(input.greetingName)},</p>
                <h2 style="margin:0 0 12px 0;color:#0f172a;font-size:22px;line-height:1.3;">${escapeHtml(input.subject)}</h2>
                ${paragraphs}
                <table role="presentation" cellpadding="0" cellspacing="0" style="margin:10px 0 4px 0;">
                  <tr>
                    <td>
                      <a href="${input.ctaUrl}" style="display:inline-block;background:#0f766e;color:#f8fafc;text-decoration:none;padding:11px 16px;border-radius:10px;font-size:13px;font-weight:700;">${escapeHtml(input.ctaLabel)}</a>
                    </td>
                  </tr>
                </table>
                <p style="margin:18px 0 0 0;padding-top:14px;border-top:1px solid #e2e8f0;color:#64748b;font-size:12px;line-height:1.6;">
                  You received this email because you have a Blocnet account.
                  Manage notifications in-app: <a href="${buildBlocnetLink('settings_notifications')}" style="color:#0f766e;">${buildBlocnetLink('settings_notifications')}</a>
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
`.trim();
  }

  private composeAdminBroadcastText(input: {
    greetingName: string;
    subject: string;
    message: string;
    ctaLabel: string;
    ctaUrl: string;
  }) {
    return [
      `Hi ${input.greetingName},`,
      '',
      input.subject,
      '',
      input.message.trim(),
      '',
      `${input.ctaLabel}: ${input.ctaUrl}`,
      '',
      `Manage notifications: ${buildBlocnetLink('settings_notifications')}`,
    ].join('\n');
  }
}

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function normalizeEmailAddress(value?: string | null): string | null {
  const trimmed = value?.trim();
  if (!trimmed) return null;
  const sanitized = trimmed
    .replace(/^.*<([^>]+)>.*$/, '$1')
    .trim()
    .toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(sanitized)) {
    return null;
  }
  return sanitized;
}

function formatFromHeader(address: string, name?: string | null): string {
  const normalized = normalizeEmailAddress(address);
  if (!normalized) {
    throw new Error(`Invalid from email: ${address}`);
  }
  const trimmedName = name?.trim();
  if (!trimmedName) {
    return normalized;
  }
  const safeName = trimmedName.replaceAll('"', "'");
  return `"${safeName}" <${normalized}>`;
}

function normalizeHttpUrl(value?: string | null): string | null {
  const trimmed = value?.trim();
  if (!trimmed) return null;
  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
      return null;
    }
    return parsed.toString();
  } catch {
    return null;
  }
}

function clampNumber(
  input: number,
  min: number,
  max: number,
  fallback: number,
) {
  if (!Number.isFinite(input)) {
    return fallback;
  }
  return Math.min(Math.max(Math.floor(input), min), max);
}

function uniqueRecipients(recipients: AdminBroadcastEmailRecipient[]) {
  const seen = new Set<string>();
  const unique: AdminBroadcastEmailRecipient[] = [];
  for (const recipient of recipients) {
    const normalized = normalizeEmailAddress(recipient.email);
    if (!normalized || seen.has(normalized)) continue;
    seen.add(normalized);
    unique.push({ ...recipient, email: normalized });
  }
  return unique;
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function truncateText(value: string, maxLength: number) {
  if (value.length <= maxLength) return value;
  return `${value.slice(0, maxLength)}...`;
}
