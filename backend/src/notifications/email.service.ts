import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { EmailTemplateService } from './email-template.service';
import {
  buildBlocnetLink,
  buildBlocnetLinkFromDeeplink,
} from './utils/blocnet-link.util';

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
    private readonly emailTemplate: EmailTemplateService,
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

    const target = buildBlocnetLinkFromDeeplink(input.deeplink);

    const subject = `Important Blocnet Notification: ${input.title}`;

    const content = `
      <h2 style="margin:0 0 16px 0;color:#0f172a;font-size:20px;font-weight:700;">
        ${escapeHtml(input.title)}
      </h2>
      <p style="margin:0 0 16px 0;color:#334155;font-size:15px;line-height:1.7;">
        ${escapeHtml(input.body)}
      </p>
    `;

    const html = this.emailTemplate.wrapInTemplate({
      subject,
      content,
      options: {
        preheader: input.title,
        showLogo: true,
        showFooter: true,
        showUnsubscribeLink: true,
        ctaButtons: [
          {
            label: 'Open Blocnet',
            url: target,
            primary: true,
          },
        ],
      },
    });

    const text = this.emailTemplate.createSimpleTextEmail({
      greeting: `Hi ${name},`,
      content: `${input.title}\n\n${input.body}`,
      footerLinks: [{ label: 'Open Blocnet', url: target }],
    });

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
          `<p style="margin:0 0 16px 0;color:#334155;font-size:15px;line-height:1.7;">${escapeHtml(chunk).replaceAll('\n', '<br/>')}</p>`,
      )
      .join('');

    const content = `
      <p style="margin:0 0 16px 0;color:#334155;font-size:15px;">Hi <strong>${escapeHtml(input.greetingName)}</strong>,</p>
      <h2 style="margin:0 0 16px 0;color:#0f172a;font-size:22px;font-weight:700;line-height:1.3;">
        ${escapeHtml(input.subject)}
      </h2>
      ${paragraphs}
    `;

    return this.emailTemplate.wrapInTemplate({
      subject: input.subject,
      content,
      options: {
        preheader: input.previewText,
        showLogo: true,
        showFooter: true,
        showUnsubscribeLink: true,
        ctaButtons: [
          {
            label: input.ctaLabel,
            url: input.ctaUrl,
            primary: true,
          },
        ],
      },
    });
  }

  private composeAdminBroadcastText(input: {
    greetingName: string;
    subject: string;
    message: string;
    ctaLabel: string;
    ctaUrl: string;
  }) {
    return this.emailTemplate.createSimpleTextEmail({
      greeting: `Hi ${input.greetingName},`,
      content: `${input.subject}\n\n${input.message.trim()}`,
      footerLinks: [
        { label: input.ctaLabel, url: input.ctaUrl },
        {
          label: 'Manage notifications',
          url: buildBlocnetLink('settings_notifications'),
        },
      ],
    });
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
