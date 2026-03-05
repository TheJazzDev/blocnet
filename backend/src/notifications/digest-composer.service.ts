import { Injectable } from '@nestjs/common';
import { EmailTemplateService } from './email-template.service';
import { buildBlocnetLink } from './utils/blocnet-link.util';

type DigestUpdate = {
  updateId: string;
  title: string;
  projectName: string;
  createdAt: Date;
};

type DigestProject = {
  projectId: string;
  projectName: string;
  newCount: number;
  highCount: number;
};

type DigestCommunityPost = {
  id: string;
  contentPreview: string;
  likesCount: number;
  commentsCount: number;
  author: {
    name: string;
  };
};

export type DigestSummaryPayload = {
  missedHighUrgency: DigestUpdate[];
  activeProjects: DigestProject[];
  topCommunityPosts: DigestCommunityPost[];
};

export type DigestRecipient = {
  displayName?: string | null;
  username?: string | null;
  email: string;
};

export type DigestComposedEmail = {
  hasContent: boolean;
  subject: string;
  preheader: string;
  html: string;
  text: string;
};

type DigestCadenceLabel = 'daily' | 'weekly';

@Injectable()
export class DigestComposerService {
  constructor(private readonly emailTemplate: EmailTemplateService) {}

  compose(input: {
    recipient: DigestRecipient;
    summary: DigestSummaryPayload;
    cadence?: DigestCadenceLabel;
    windowDays?: number;
    asOf?: Date;
  }): DigestComposedEmail {
    const asOf = input.asOf ?? new Date();
    const cadence: DigestCadenceLabel = input.cadence ?? 'daily';
    const windowDays = Math.max(
      1,
      input.windowDays ?? (cadence === 'weekly' ? 7 : 1),
    );
    const missed = input.summary.missedHighUrgency.slice(0, 5);
    const activeProjects = input.summary.activeProjects.slice(0, 5);
    const topThreads = input.summary.topCommunityPosts.slice(0, 3);

    const hasContent =
      missed.length > 0 || activeProjects.length > 0 || topThreads.length > 0;

    const monthDay = new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
    }).format(asOf);

    const cadenceLabel = cadence === 'weekly' ? 'Weekly' : 'Daily';
    const subject = `Your Blocnet ${cadenceLabel} Digest · ${monthDay}`;
    const preheader = `${missed.length} high-priority updates, ${activeProjects.length} active projects, ${topThreads.length} top threads`;
    const digestWindowLabel =
      cadence === 'weekly'
        ? `the last ${windowDays} days`
        : 'the last 24 hours';

    if (!hasContent) {
      return {
        hasContent,
        subject,
        preheader,
        html: '',
        text: '',
      };
    }

    const normalizedDisplayName = normalizeText(input.recipient.displayName);
    const normalizedUsername = normalizeText(input.recipient.username);
    const greetingName = normalizedDisplayName
      ? normalizedDisplayName
      : normalizedUsername
        ? `@${normalizedUsername}`
        : 'there';

    // Build content sections
    const contentSections: string[] = [];

    // Greeting
    contentSections.push(`
      <p style="margin:0 0 8px 0;font-size:17px;color:#334155;">Hi <strong>${escapeHtml(greetingName)}</strong>,</p>
      <p style="margin:0 0 20px 0;font-size:15px;color:#64748b;">Here's what you missed in ${digestWindowLabel}.</p>
    `);

    // Missed High Urgency Updates
    if (missed.length > 0) {
      contentSections.push(`
        <h2 style="margin:24px 0 12px 0;color:#0f172a;font-size:18px;font-weight:700;">
          ⚠️ Missed High Urgency Updates
        </h2>
      `);

      missed.forEach((item) => {
        contentSections.push(`
          <div style="margin:0 0 12px 0;padding:16px;background:#fef2f2;border:1px solid #fecaca;border-radius:12px;">
            <p style="margin:0 0 6px 0;color:#0f172a;font-size:15px;font-weight:700;line-height:1.4;">
              ${escapeHtml(item.title)}
            </p>
            <p style="margin:0 0 10px 0;color:#64748b;font-size:13px;">
              ${escapeHtml(item.projectName)} · ${escapeHtml(relativeTime(item.createdAt, asOf))}
            </p>
            <a href="${buildBlocnetLink('update', item.updateId)}" style="color:#0f766e;text-decoration:none;font-size:13px;font-weight:700;">
              View Update →
            </a>
          </div>
        `);
      });
    }

    // Most Active Projects
    if (activeProjects.length > 0) {
      contentSections.push(`
        <h2 style="margin:24px 0 12px 0;color:#0f172a;font-size:18px;font-weight:700;">
          📊 Most Active Projects
        </h2>
      `);

      activeProjects.forEach((item) => {
        contentSections.push(`
          <div style="margin:0 0 12px 0;padding:16px;background:#f0fdfa;border:1px solid#ccfbf1;border-radius:12px;">
            <p style="margin:0 0 6px 0;color:#0f172a;font-size:15px;font-weight:700;line-height:1.4;">
              ${escapeHtml(item.projectName)}
            </p>
            <p style="margin:0 0 10px 0;color:#64748b;font-size:13px;">
              <strong>${item.newCount}</strong> new updates · <strong>${item.highCount}</strong> high urgency
            </p>
            <a href="${buildBlocnetLink('project', item.projectId)}" style="color:#0f766e;text-decoration:none;font-size:13px;font-weight:700;">
              View Project →
            </a>
          </div>
        `);
      });
    }

    // Top Community Threads
    if (topThreads.length > 0) {
      contentSections.push(`
        <h2 style="margin:24px 0 12px 0;color:#0f172a;font-size:18px;font-weight:700;">
          💬 Top Community Threads
        </h2>
      `);

      topThreads.forEach((item) => {
        contentSections.push(`
          <div style="margin:0 0 12px 0;padding:16px;background:#faf5ff;border:1px solid #e9d5ff;border-radius:12px;">
            <p style="margin:0 0 6px 0;color:#0f172a;font-size:14px;font-weight:700;">
              ${escapeHtml(item.author.name)}
            </p>
            <p style="margin:0 0 10px 0;color:#475569;font-size:14px;line-height:1.5;">
              ${escapeHtml(item.contentPreview)}
            </p>
            <p style="margin:0 0 10px 0;color:#64748b;font-size:13px;">
              ${item.likesCount} likes · ${item.commentsCount} comments
            </p>
            <a href="${buildBlocnetLink('community', item.id)}" style="color:#0f766e;text-decoration:none;font-size:13px;font-weight:700;">
              View Thread →
            </a>
          </div>
        `);
      });
    }

    const content = contentSections.join('\n');

    const html = this.emailTemplate.wrapInTemplate({
      subject,
      content,
      options: {
        preheader,
        showLogo: true,
        showFooter: true,
        showUnsubscribeLink: true,
        ctaButtons: [
          {
            label: 'Open Blocnet App',
            url: buildBlocnetLink('notifications'),
            primary: true,
          },
          {
            label: 'Manage Notifications',
            url: buildBlocnetLink('settings_notifications'),
            primary: false,
          },
        ],
      },
    });

    // Text version
    const textSections: string[] = [
      `Hi ${greetingName},`,
      `Here's what you missed in ${digestWindowLabel}.`,
      '',
    ];

    if (missed.length > 0) {
      textSections.push('⚠️  MISSED HIGH URGENCY UPDATES');
      textSections.push('');
      missed.forEach((item) => {
        textSections.push(
          `• ${item.title}`,
          `  ${item.projectName} · ${relativeTime(item.createdAt, asOf)}`,
          `  ${buildBlocnetLink('update', item.updateId)}`,
          '',
        );
      });
    }

    if (activeProjects.length > 0) {
      textSections.push('📊 MOST ACTIVE PROJECTS');
      textSections.push('');
      activeProjects.forEach((item) => {
        textSections.push(
          `• ${item.projectName}`,
          `  ${item.newCount} new updates · ${item.highCount} high urgency`,
          `  ${buildBlocnetLink('project', item.projectId)}`,
          '',
        );
      });
    }

    if (topThreads.length > 0) {
      textSections.push('💬 TOP COMMUNITY THREADS');
      textSections.push('');
      topThreads.forEach((item) => {
        textSections.push(
          `• ${item.author.name}`,
          `  ${item.contentPreview}`,
          `  ${item.likesCount} likes · ${item.commentsCount} comments`,
          `  ${buildBlocnetLink('community', item.id)}`,
          '',
        );
      });
    }

    textSections.push(
      '---',
      '',
      `Open Blocnet App: ${buildBlocnetLink('notifications')}`,
      `Manage Notifications: ${buildBlocnetLink('settings_notifications')}`,
    );

    return {
      hasContent,
      subject,
      preheader,
      html,
      text: textSections.join('\n'),
    };
  }
}

function normalizeText(value?: string | null): string | null {
  const trimmed = value?.trim();
  if (!trimmed) {
    return null;
  }
  return trimmed;
}

function relativeTime(from: Date, to: Date): string {
  const diffMs = to.getTime() - from.getTime();
  const diffMinutes = Math.max(1, Math.round(diffMs / 60000));
  if (diffMinutes < 60) {
    return `${diffMinutes}m ago`;
  }

  const diffHours = Math.round(diffMinutes / 60);
  if (diffHours < 24) {
    return `${diffHours}h ago`;
  }

  const diffDays = Math.round(diffHours / 24);
  return `${diffDays}d ago`;
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
