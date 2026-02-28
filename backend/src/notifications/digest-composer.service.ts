import { Injectable } from '@nestjs/common';
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

const BRAND_LOGO_URL = 'https://blocnet.app/logo2.png';

@Injectable()
export class DigestComposerService {
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
    const openBlocnetLink = buildBlocnetLink('notifications');
    const notificationSettingsLink = buildBlocnetLink('settings_notifications');

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

    const missedHtml = missed
      .map(
        (item) =>
          `<div class="item">
            <p class="item-title">${escapeHtml(item.title)}</p>
            <p class="item-meta">${escapeHtml(item.projectName)} · ${escapeHtml(relativeTime(item.createdAt, asOf))}</p>
            <a class="item-link" href="${buildBlocnetLink('update', item.updateId)}">Open update</a>
          </div>`,
      )
      .join('');

    const projectsHtml = activeProjects
      .map(
        (item) =>
          `<div class="item">
            <p class="item-title">${escapeHtml(item.projectName)}</p>
            <p class="item-meta">${item.newCount} updates · ${item.highCount} high urgency</p>
            <a class="item-link" href="${buildBlocnetLink('project', item.projectId)}">Open project</a>
          </div>`,
      )
      .join('');

    const communityHtml = topThreads
      .map(
        (item) =>
          `<div class="item">
            <p class="item-title">${escapeHtml(item.author.name)}</p>
            <p class="item-meta">${escapeHtml(item.contentPreview)}</p>
            <p class="item-meta">${item.likesCount} likes · ${item.commentsCount} comments</p>
            <a class="item-link" href="${buildBlocnetLink('community', item.id)}">Open thread</a>
          </div>`,
      )
      .join('');

    const html = `
<!doctype html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      body { margin:0; padding:0; background:#0b1120; font-family: Inter, Arial, sans-serif; color:#0f172a; }
      .wrapper { width:100%; padding:24px 12px; background: radial-gradient(circle at top right, #1e293b 0%, #0b1120 45%, #020617 100%); }
      .container { width:100%; max-width:640px; margin:0 auto; background:#f8fafc; border-radius:20px; overflow:hidden; border:1px solid #e2e8f0; }
      .header { padding:20px 22px; background:#0f172a; color:#e2e8f0; }
      .brand { display:flex; align-items:center; gap:10px; font-weight:700; font-size:16px; letter-spacing:0.2px; }
      .brand img { width:38px; height:38px; border-radius:10px; display:block; background:#ffffff; padding:4px; }
      .cadence-pill { margin-top:10px; display:inline-block; padding:4px 10px; border-radius:999px; background:#1e293b; color:#94a3b8; font-size:11px; font-weight:600; letter-spacing:0.5px; text-transform:uppercase; }
      .content { padding:22px; }
      .intro { margin:0 0 16px 0; color:#334155; font-size:15px; line-height:1.6; }
      .cta-row { margin:16px 0 20px 0; }
      .btn { display:inline-block; margin-right:8px; margin-bottom:8px; padding:10px 14px; border-radius:10px; text-decoration:none; font-weight:700; font-size:13px; }
      .btn-primary { background:#0f766e; color:#f8fafc !important; }
      .btn-secondary { background:#e2e8f0; color:#0f172a !important; }
      .section { margin-top:18px; }
      .section-title { margin:0 0 8px 0; color:#0f172a; font-size:15px; font-weight:800; }
      .item { padding:12px; background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; margin-bottom:8px; }
      .item-title { margin:0 0 4px 0; color:#0f172a; font-size:14px; font-weight:700; line-height:1.4; }
      .item-meta { margin:0 0 6px 0; color:#475569; font-size:12px; line-height:1.5; }
      .item-link { color:#0f766e; text-decoration:none; font-size:12px; font-weight:700; }
      .footer { margin-top:20px; padding-top:14px; border-top:1px solid #e2e8f0; color:#64748b; font-size:12px; line-height:1.5; }
      @media only screen and (max-width: 600px) {
        .wrapper { padding:10px 6px; }
        .container { border-radius:14px; }
        .header, .content { padding:16px; }
        .btn { width:100%; text-align:center; margin-right:0; }
      }
    </style>
  </head>
  <body>
    <p style="display:none;visibility:hidden;opacity:0;height:0;width:0;overflow:hidden;">${escapeHtml(preheader)}</p>
    <div class="wrapper">
      <div class="container">
        <div class="header">
          <div class="brand">
            <img src="${BRAND_LOGO_URL}" alt="Blocnet logo" />
            <span>Blocnet Digest</span>
          </div>
          <span class="cadence-pill">${cadenceLabel} Digest</span>
        </div>
        <div class="content">
          <p class="intro">Hi ${escapeHtml(greetingName)},</p>
          <p class="intro">Here’s what you missed in ${digestWindowLabel}.</p>
          <div class="cta-row">
            <a class="btn btn-primary" href="${openBlocnetLink}">Open Blocnet App</a>
            <a class="btn btn-secondary" href="${notificationSettingsLink}">Manage Notifications</a>
          </div>

          ${missed.length > 0 ? `<div class="section"><p class="section-title">Missed High Urgency Updates</p>${missedHtml}</div>` : ''}
          ${activeProjects.length > 0 ? `<div class="section"><p class="section-title">Most Active Projects</p>${projectsHtml}</div>` : ''}
          ${topThreads.length > 0 ? `<div class="section"><p class="section-title">Top Community Threads</p>${communityHtml}</div>` : ''}

          <div class="footer">
            You received this email because digest notifications are enabled on your Blocnet account.<br/>
            Manage notification settings: <a href="${notificationSettingsLink}">${notificationSettingsLink}</a>
          </div>
        </div>
      </div>
    </div>
  </body>
</html>
`.trim();

    const textSections: string[] = [
      `Hi ${greetingName},`,
      `Here’s what you missed in ${digestWindowLabel}.`,
    ];

    if (missed.length > 0) {
      textSections.push('\nMissed High Urgency Updates');
      textSections.push(
        ...missed.map(
          (item) =>
            `- ${item.title} (${item.projectName}, ${relativeTime(item.createdAt, asOf)})\n  ${buildBlocnetLink('update', item.updateId)}`,
        ),
      );
    }

    if (activeProjects.length > 0) {
      textSections.push('\nMost Active Projects');
      textSections.push(
        ...activeProjects.map(
          (item) =>
            `- ${item.projectName}: ${item.newCount} updates, ${item.highCount} high\n  ${buildBlocnetLink('project', item.projectId)}`,
        ),
      );
    }

    if (topThreads.length > 0) {
      textSections.push('\nTop Community Threads');
      textSections.push(
        ...topThreads.map(
          (item) =>
            `- ${item.author.name}: ${item.contentPreview}\n  ${item.likesCount} likes, ${item.commentsCount} comments\n  ${buildBlocnetLink('community', item.id)}`,
        ),
      );
    }

    textSections.push(`\nOpen Blocnet App: ${openBlocnetLink}`);
    textSections.push(`Manage notifications: ${notificationSettingsLink}`);

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
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
