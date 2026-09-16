import 'package:blocnet/constants/app_routes.dart';
import 'package:blocnet/services/notifications/notification_target_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationTargetResolver', () {
    test('opens update details for project updates', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'project_update',
        updateId: 'update_1',
      );

      expect(decision.opensUpdateDetails, isTrue);
      expect(decision.updateId, 'update_1');
    });

    test('routes community likes to discussion post', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'community_liked',
        payload: {'postId': 'post_1'},
      );

      expect(decision.opensUpdateDetails, isFalse);
      expect(decision.route, AppRoutes.communityDiscussion);
      expect(decision.arguments, 'post_1');
    });

    test('parses deeplink post id when payload is missing', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'community_bookmarked',
        deeplink: '/community/posts/post_9',
      );

      expect(decision.route, AppRoutes.communityDiscussion);
      expect(decision.arguments, 'post_9');
    });

    test('routes invite notifications to hunter hub', () {
      for (final type in [
        'project_invite_received',
        'project_invite_responded',
        'project_assignment_changed',
      ]) {
        final decision = NotificationTargetResolver.resolve(type: type);
        expect(decision.route, AppRoutes.hunterHub, reason: type);
      }
    });

    test('categorises level_up as rewards', () {
      expect(NotificationTargetResolver.categoryForType('level_up'), 'rewards');
      expect(NotificationTargetResolver.categoryForType('LEVEL_UP'), 'rewards');
    });

    test('routes level_up notifications to the levels screen', () {
      final decision = NotificationTargetResolver.resolve(type: 'level_up');

      expect(decision.opensUpdateDetails, isFalse);
      expect(decision.route, AppRoutes.levels);
      expect(decision.arguments, isNull);
    });

    test('routes /levels deeplinks to the levels screen', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'unknown_type',
        deeplink: 'blocnet://levels',
      );

      expect(decision.route, AppRoutes.levels);
    });

    test('routes update requests to the hunter hub, as governance', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'project_update_requested',
        deeplink: '/projects/gem_1',
        payload: {'projectId': 'gem_1'},
      );

      expect(decision.route, AppRoutes.hunterHub);
      expect(
        NotificationTargetResolver.categoryForType('project_update_requested'),
        'governance',
      );
    });

    test('routes inactivity reports to the moderation tab, as governance', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'project_reported_inactive',
        deeplink: '/projects/gem_1',
      );

      expect(decision.route, isNull);
      expect(decision.opensSpaceTab, isTrue);
      expect(decision.space, 'moderation');
      expect(decision.spaceTab, 2);
      expect(
        NotificationTargetResolver.categoryForType('project_reported_inactive'),
        'governance',
      );
    });

    test('routes a reviewed hunter application to become hunter', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'admin_application_reviewed',
        deeplink: '/profile',
      );

      expect(decision.route, AppRoutes.becomeHunter);
    });

    test('routes quest notifications to quests', () {
      for (final type in [
        'quest_completed',
        'quest_verified',
        'quest_rejected',
      ]) {
        final decision = NotificationTargetResolver.resolve(type: type);
        expect(decision.route, AppRoutes.quests, reason: type);
      }
    });

    test('routes mining claims and /mining deeplinks to mining', () {
      expect(
        NotificationTargetResolver.resolve(
          type: 'mining_claimed',
          deeplink: '/mining',
        ).route,
        AppRoutes.mining,
      );
      expect(
        NotificationTargetResolver.resolve(type: 'system', deeplink: '/mining')
            .route,
        AppRoutes.mining,
      );
    });

    test('routes referral notifications to the referral screen', () {
      for (final type in ['referral_bound', 'referral_admin_bound']) {
        final decision = NotificationTargetResolver.resolve(
          type: type,
          deeplink: '/profile',
        );
        expect(decision.route, AppRoutes.referralCode, reason: type);
      }
    });

    test('only coverage duties count as hunter hub alerts', () {
      expect(
        NotificationTargetResolver.isHunterHubType('project_update_requested'),
        isTrue,
      );
      expect(
        NotificationTargetResolver.isHunterHubType('project_update'),
        isFalse,
      );
      expect(
        NotificationTargetResolver.isHunterHubType('comment_received'),
        isFalse,
      );
    });

    test('falls back to main for unsupported notifications', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'unknown_type',
      );

      expect(decision.route, AppRoutes.main);
    });
  });
}
