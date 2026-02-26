import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { buildBlocnetLink } from './utils/blocnet-link.util';

@Injectable()
export class NotificationEmailService {
  private readonly logger = new Logger(NotificationEmailService.name);

  private readonly resendApiKey: string;
  private readonly fromAddress: string;
  private readonly replyTo: string | null;

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
    this.replyTo =
      this.configService.get<string>('EMAIL_REPLY_TO')?.trim() || null;
  }

  getStatus() {
    const configured =
      this.resendApiKey.length > 0 && this.fromAddress.length > 0;
    return {
      configured,
      reason: configured
        ? null
        : 'Missing RESEND_API_KEY or EMAIL_FROM_ADDRESS/FROM_EMAIL',
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
    });

    return { delivered: true, skipped: false };
  }

  private isConfigured() {
    return this.resendApiKey.length > 0 && this.fromAddress.length > 0;
  }

  private async sendEmail(input: {
    to: string;
    subject: string;
    html: string;
    text: string;
  }) {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.resendApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: this.fromAddress,
        to: [input.to],
        subject: input.subject,
        html: input.html,
        text: input.text,
        ...(this.replyTo ? { reply_to: this.replyTo } : {}),
      }),
    });

    if (!response.ok) {
      const message = await response.text();
      throw new Error(`Resend send failed (${response.status}): ${message}`);
    }
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
