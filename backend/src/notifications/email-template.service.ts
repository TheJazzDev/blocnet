import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { buildBlocnetLink } from './utils/blocnet-link.util';

export type EmailTemplateOptions = {
  preheader?: string;
  showLogo?: boolean;
  showFooter?: boolean;
  showUnsubscribeLink?: boolean;
  ctaButtons?: Array<{
    label: string;
    url: string;
    primary?: boolean;
  }>;
};

@Injectable()
export class EmailTemplateService {
  private readonly logoUrl: string;
  private readonly brandName: string;
  private readonly brandColor: string;
  private readonly supportEmail: string;
  private readonly websiteUrl: string;

  constructor(private readonly configService: ConfigService) {
    this.logoUrl =
      this.configService.get<string>('EMAIL_LOGO_URL')?.trim() ||
      'https://blocnet.app/logo2.png';
    this.brandName = 'Blocnet';
    this.brandColor = '#0f766e'; // Teal-700
    this.supportEmail = 'support@blocnet.app';
    this.websiteUrl = 'https://blocnet.app';
  }

  /**
   * Wraps email content in a professional template with consistent branding
   */
  wrapInTemplate(input: {
    subject: string;
    content: string;
    options?: EmailTemplateOptions;
  }): string {
    const opts = input.options || {};
    const showLogo = opts.showLogo !== false;
    const showFooter = opts.showFooter !== false;
    const preheader = opts.preheader || '';
    const ctaButtons = opts.ctaButtons || [];
    const showUnsubscribeLink = opts.showUnsubscribeLink !== false;
    const manageNotificationsUrl = buildBlocnetLink('settings_notifications');

    return `
<!doctype html>
<html lang="en">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="x-apple-disable-message-reformatting" />
    <title>${this.escapeHtml(input.subject)}</title>
    <style>
      /* Reset styles */
      body {
        margin: 0;
        padding: 0;
        min-width: 100%;
        width: 100% !important;
        height: 100% !important;
        -webkit-text-size-adjust: 100%;
        -ms-text-size-adjust: 100%;
      }

      body, table, td, p, a, li {
        -webkit-text-size-adjust: 100%;
        -ms-text-size-adjust: 100%;
      }

      table {
        border-spacing: 0;
        border-collapse: collapse;
        table-layout: fixed;
        margin: 0 auto;
      }

      img {
        border: 0;
        outline: none;
        text-decoration: none;
        -ms-interpolation-mode: bicubic;
        max-width: 100%;
        height: auto;
        display: block;
      }

      /* Base styles */
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        background-color: #0b1120;
        color: #0f172a;
        line-height: 1.6;
      }

      /* Container styles */
      .email-wrapper {
        width: 100%;
        padding: 20px 10px;
        background: linear-gradient(135deg, #1e293b 0%, #0b1120 50%, #020617 100%);
      }

      .email-container {
        max-width: 600px;
        margin: 0 auto;
        background-color: #ffffff;
        border-radius: 16px;
        overflow: hidden;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
      }

      /* Header styles */
      .email-header {
        background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
        padding: 24px;
        text-align: center;
      }

      .email-logo {
        width: 60px;
        height: 60px;
        margin: 0 auto 12px;
        background: #ffffff;
        border-radius: 12px;
        padding: 8px;
      }

      .email-brand-name {
        color: #f8fafc;
        font-size: 22px;
        font-weight: 700;
        letter-spacing: 0.5px;
        margin: 0;
      }

      /* Content styles */
      .email-content {
        padding: 32px 24px;
      }

      .email-content p {
        margin: 0 0 16px 0;
        color: #334155;
        font-size: 15px;
        line-height: 1.7;
      }

      .email-content h1,
      .email-content h2,
      .email-content h3 {
        color: #0f172a;
        margin: 0 0 16px 0;
        font-weight: 700;
      }

      .email-content h1 {
        font-size: 24px;
        line-height: 1.3;
      }

      .email-content h2 {
        font-size: 20px;
        line-height: 1.4;
      }

      .email-content h3 {
        font-size: 17px;
        line-height: 1.5;
      }

      .email-content ul,
      .email-content ol {
        margin: 0 0 16px 0;
        padding-left: 24px;
      }

      .email-content li {
        margin-bottom: 8px;
        color: #334155;
        font-size: 15px;
      }

      /* CTA Button styles */
      .cta-container {
        margin: 24px 0;
        text-align: center;
      }

      .cta-button {
        display: inline-block;
        padding: 14px 28px;
        margin: 8px 4px;
        background-color: ${this.brandColor};
        color: #ffffff !important;
        text-decoration: none;
        border-radius: 10px;
        font-weight: 700;
        font-size: 15px;
        transition: opacity 0.2s;
      }

      .cta-button:hover {
        opacity: 0.9;
      }

      .cta-button-secondary {
        background-color: #e2e8f0;
        color: #0f172a !important;
      }

      /* Footer styles */
      .email-footer {
        padding: 24px;
        background-color: #f8fafc;
        border-top: 1px solid #e2e8f0;
        text-align: center;
      }

      .footer-content {
        color: #64748b;
        font-size: 13px;
        line-height: 1.6;
        margin: 0 0 12px 0;
      }

      .footer-links {
        margin: 16px 0 8px 0;
      }

      .footer-link {
        color: ${this.brandColor};
        text-decoration: none;
        margin: 0 8px;
        font-size: 13px;
        font-weight: 600;
      }

      .footer-link:hover {
        text-decoration: underline;
      }

      .footer-social {
        margin: 16px 0 0 0;
      }

      .social-link {
        display: inline-block;
        margin: 0 6px;
        color: #64748b;
        text-decoration: none;
      }

      /* Divider */
      .divider {
        height: 1px;
        background-color: #e2e8f0;
        margin: 24px 0;
        border: none;
      }

      /* Mobile responsive */
      @media only screen and (max-width: 600px) {
        .email-wrapper {
          padding: 12px 6px !important;
        }

        .email-container {
          border-radius: 12px !important;
        }

        .email-header {
          padding: 20px 16px !important;
        }

        .email-logo {
          width: 50px !important;
          height: 50px !important;
        }

        .email-brand-name {
          font-size: 18px !important;
        }

        .email-content {
          padding: 24px 16px !important;
        }

        .email-content h1 {
          font-size: 20px !important;
        }

        .email-content h2 {
          font-size: 18px !important;
        }

        .email-content p,
        .email-content li {
          font-size: 14px !important;
        }

        .cta-button {
          display: block !important;
          width: 100% !important;
          margin: 8px 0 !important;
          padding: 12px 20px !important;
        }

        .email-footer {
          padding: 20px 16px !important;
        }
      }
    </style>
  </head>
  <body>
    ${preheader ? `<div style="display:none;visibility:hidden;opacity:0;height:0;width:0;overflow:hidden;mso-hide:all;">${this.escapeHtml(preheader)}</div>` : ''}

    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #1e293b 0%, #0b1120 50%, #020617 100%);">
      <tr>
        <td>
          <div class="email-wrapper">
            <div class="email-container">
              ${
                showLogo
                  ? `
              <!-- Header -->
              <div class="email-header">
                <img src="${this.logoUrl}" alt="${this.brandName}" class="email-logo" width="60" height="60" />
                <h1 class="email-brand-name">${this.brandName}</h1>
              </div>
              `
                  : ''
              }

              <!-- Content -->
              <div class="email-content">
                ${input.content}

                ${
                  ctaButtons.length > 0
                    ? `
                <div class="cta-container">
                  ${ctaButtons
                    .map(
                      (btn) => `
                    <a href="${btn.url}" class="cta-button ${btn.primary === false ? 'cta-button-secondary' : ''}">${this.escapeHtml(btn.label)}</a>
                  `,
                    )
                    .join('')}
                </div>
                `
                    : ''
                }
              </div>

              ${
                showFooter
                  ? `
              <!-- Footer -->
              <div class="email-footer">
                <p class="footer-content">
                  <strong>${this.brandName}</strong><br/>
                  AI-Powered Crypto Intelligence Network
                </p>

                <div class="footer-links">
                  <a href="${this.websiteUrl}" class="footer-link">Website</a>
                  <span style="color:#cbd5e1;">·</span>
                  <a href="${this.websiteUrl}/about" class="footer-link">About</a>
                  <span style="color:#cbd5e1;">·</span>
                  <a href="mailto:${this.supportEmail}" class="footer-link">Support</a>
                  ${
                    showUnsubscribeLink
                      ? `
                  <span style="color:#cbd5e1;">·</span>
                  <a href="${manageNotificationsUrl}" class="footer-link">Manage Notifications</a>
                  `
                      : ''
                  }
                </div>

                <p class="footer-content" style="margin-top:16px;font-size:12px;">
                  You received this email because you have a ${this.brandName} account.
                  ${showUnsubscribeLink ? `<a href="${manageNotificationsUrl}" style="color:${this.brandColor};">Manage your preferences</a>` : ''}
                </p>

                <p class="footer-content" style="margin-top:8px;font-size:12px;color:#94a3b8;">
                  © ${new Date().getFullYear()} ${this.brandName}. All rights reserved.
                </p>
              </div>
              `
                  : ''
              }
            </div>
          </div>
        </td>
      </tr>
    </table>
  </body>
</html>
    `.trim();
  }

  /**
   * Create a simple text-only email with greeting
   */
  createSimpleTextEmail(input: {
    greeting: string;
    content: string;
    footerLinks?: Array<{ label: string; url: string }>;
  }): string {
    const links = input.footerLinks || [];
    const linkText = links.map((l) => `${l.label}: ${l.url}`).join('\n');

    return `
${input.greeting}

${input.content}

---
${this.brandName}
${this.websiteUrl}

${linkText}

© ${new Date().getFullYear()} ${this.brandName}. All rights reserved.
    `.trim();
  }

  private escapeHtml(value: string): string {
    return value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }
}
