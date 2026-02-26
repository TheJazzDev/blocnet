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

@Injectable()
export class DigestComposerService {
  compose(input: {
    recipient: DigestRecipient;
    summary: DigestSummaryPayload;
    asOf?: Date;
  }): DigestComposedEmail {
    const asOf = input.asOf ?? new Date();
    const missed = input.summary.missedHighUrgency.slice(0, 5);
    const activeProjects = input.summary.activeProjects.slice(0, 5);
    const topThreads = input.summary.topCommunityPosts.slice(0, 3);

    const hasContent =
      missed.length > 0 || activeProjects.length > 0 || topThreads.length > 0;

    const monthDay = new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
    }).format(asOf);

    const subject = `Your Blocnet Daily Digest · ${monthDay}`;
    const preheader = `${missed.length} high-priority updates, ${activeProjects.length} active projects, ${topThreads.length} top threads`;

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
          `<li><strong>${escapeHtml(item.title)}</strong><br/>${escapeHtml(item.projectName)} · ${escapeHtml(relativeTime(item.createdAt, asOf))}<br/><a href="${buildBlocnetLink('update', item.updateId)}">View update</a></li>`,
      )
      .join('');

    const projectsHtml = activeProjects
      .map(
        (item) =>
          `<li><strong>${escapeHtml(item.projectName)}</strong><br/>${item.newCount} updates · ${item.highCount} high urgency<br/><a href="${buildBlocnetLink('project', item.projectId)}">Open project</a></li>`,
      )
      .join('');

    const communityHtml = topThreads
      .map(
        (item) =>
          `<li><strong>${escapeHtml(item.author.name)}</strong><br/>${escapeHtml(item.contentPreview)}<br/>${item.likesCount} likes · ${item.commentsCount} comments<br/><a href="${buildBlocnetLink('community', item.id)}">Open thread</a></li>`,
      )
      .join('');

    const html = `
<!doctype html>
<html>
  <body style="font-family:Arial,sans-serif;color:#0f172a;line-height:1.5;">
    <p style="display:none;visibility:hidden;opacity:0;height:0;width:0;overflow:hidden;">${escapeHtml(preheader)}</p>
    <h2>Hi ${escapeHtml(greetingName)},</h2>
    <p>Here’s what you missed in the last 24 hours.</p>

    ${missed.length > 0 ? `<h3>Missed High Urgency Updates</h3><ul>${missedHtml}</ul>` : ''}
    ${activeProjects.length > 0 ? `<h3>Most Active Projects</h3><ul>${projectsHtml}</ul>` : ''}
    ${topThreads.length > 0 ? `<h3>Top Community Threads</h3><ul>${communityHtml}</ul>` : ''}

    <p><a href="${buildBlocnetLink('notifications')}">Open Blocnet</a></p>
    <p style="font-size:12px;color:#64748b;">Manage preferences: <a href="${buildBlocnetLink('settings_notifications')}">${buildBlocnetLink('settings_notifications')}</a></p>
  </body>
</html>
`.trim();

    const textSections: string[] = [
      `Hi ${greetingName},`,
      `Here’s what you missed in the last 24 hours.`,
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

    textSections.push(`\nOpen Blocnet: ${buildBlocnetLink('notifications')}`);
    textSections.push(
      `Manage preferences: ${buildBlocnetLink('settings_notifications')}`,
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
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
