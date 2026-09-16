import { DigestComposerService } from './digest-composer.service';
import type { ConfigService } from '@nestjs/config';
import { buildBlocnetLink } from './utils/blocnet-link.util';
import { EmailTemplateService } from './email-template.service';

describe('DigestComposerService', () => {
  const service = new DigestComposerService(
    new EmailTemplateService({
      get: () => undefined,
    } as unknown as ConfigService),
  );

  it('renders digest with capped sections and links', () => {
    const now = new Date('2026-02-25T08:00:00.000Z');
    const result = service.compose({
      recipient: {
        email: 'user@example.com',
        displayName: 'Jazz',
      },
      asOf: now,
      summary: {
        missedHighUrgency: Array.from({ length: 8 }, (_, idx) => ({
          updateId: `u-${idx + 1}`,
          title: `Update ${idx + 1}`,
          projectName: 'BlocNet',
          createdAt: new Date('2026-02-25T07:00:00.000Z'),
        })),
        activeProjects: Array.from({ length: 7 }, (_, idx) => ({
          projectId: `p-${idx + 1}`,
          projectName: `Project ${idx + 1}`,
          newCount: idx + 1,
          highCount: idx,
        })),
        topCommunityPosts: Array.from({ length: 5 }, (_, idx) => ({
          id: `c-${idx + 1}`,
          contentPreview: `Community ${idx + 1}`,
          likesCount: idx + 2,
          commentsCount: idx + 1,
          author: { name: 'User' },
        })),
      },
    });

    expect(result.hasContent).toBe(true);
    expect(result.subject).toContain('Your Blocnet Daily Digest');
    expect(result.html).toContain('Missed High Urgency Updates');
    expect(result.text).toContain(
      `Open Blocnet App: ${buildBlocnetLink('notifications')}`,
    );

    const updateLinks = result.html.match(/%2Fupdates%2F/g) ?? [];
    const projectLinks = result.html.match(/%2Fprojects%2F/g) ?? [];
    const communityLinks = result.html.match(/%2Fcommunity%2F/g) ?? [];
    expect(updateLinks).toHaveLength(5);
    expect(projectLinks).toHaveLength(5);
    expect(communityLinks).toHaveLength(3);
  });

  it('returns empty body when summary has no content', () => {
    const result = service.compose({
      recipient: {
        email: 'user@example.com',
      },
      summary: {
        missedHighUrgency: [],
        activeProjects: [],
        topCommunityPosts: [],
      },
    });

    expect(result.hasContent).toBe(false);
    expect(result.html).toBe('');
    expect(result.text).toBe('');
  });

  it('renders weekly cadence copy and subject', () => {
    const result = service.compose({
      recipient: {
        email: 'user@example.com',
      },
      cadence: 'weekly',
      windowDays: 7,
      summary: {
        missedHighUrgency: [
          {
            updateId: 'u-1',
            title: 'Weekly update',
            projectName: 'BlocNet',
            createdAt: new Date('2026-02-24T07:00:00.000Z'),
          },
        ],
        activeProjects: [],
        topCommunityPosts: [],
      },
    });

    expect(result.subject).toContain('Your Blocnet Weekly Digest');
    expect(result.text).toContain("Here's what you missed in the last 7 days.");
  });
});
