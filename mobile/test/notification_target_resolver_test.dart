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

    test('routes invite notifications to manage projects', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'project_invite_received',
      );

      expect(decision.route, AppRoutes.manageProjects);
    });

    test('falls back to main for unsupported notifications', () {
      final decision = NotificationTargetResolver.resolve(
        type: 'unknown_type',
      );

      expect(decision.route, AppRoutes.main);
    });
  });
}
