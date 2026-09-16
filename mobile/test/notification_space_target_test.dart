import 'package:blocnet/features/notifications/data/models/notification_model.dart';
import 'package:blocnet/features/notifications/presentation/widgets/cross_space_notification_sheet.dart';
import 'package:blocnet/services/notifications/notification_space_target.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

NotificationSpaceTarget? _target(
  String type, {
  String? deeplink,
  String activeSpace = 'user',
  bool hunter = true,
  bool moderator = true,
}) {
  return NotificationSpaceTarget.crossSpaceFor(
    type: type,
    deeplink: deeplink,
    activeSpace: activeSpace,
    hasHunterSpace: hunter,
    hasModerationSpace: moderator,
  );
}

void main() {
  group('NotificationSpaceTarget.crossSpaceFor', () {
    test('an update request seen outside hunter space belongs to the hub', () {
      expect(
        _target('project_update_requested'),
        NotificationSpaceTarget.hunterHub,
      );
      expect(
        _target('project_update_requested', activeSpace: 'moderation'),
        NotificationSpaceTarget.hunterHub,
      );
      expect(
        _target('project_update_requested', activeSpace: 'hunter'),
        isNull,
      );
    });

    test('an inactivity report belongs to moderation', () {
      expect(
        _target('project_reported_inactive'),
        NotificationSpaceTarget.moderationHub,
      );
      expect(
        _target('project_reported_inactive', activeSpace: 'hunter'),
        NotificationSpaceTarget.moderationHub,
      );
      expect(
        _target('project_reported_inactive', activeSpace: 'moderation'),
        isNull,
      );
    });

    test('never targets a space the user cannot enter', () {
      expect(_target('project_update_requested', hunter: false), isNull);
      expect(_target('project_reported_inactive', moderator: false), isNull);
      expect(
        _target('system', deeplink: '/manage-projects', hunter: false),
        isNull,
      );
    });

    test('update and comment alerts open in any space', () {
      expect(_target('project_update'), isNull);
      expect(_target('comment_received'), isNull);
    });

    test('community alerts seen from hunter space belong to user space', () {
      expect(
        _target('community_liked', activeSpace: 'hunter'),
        NotificationSpaceTarget.community,
      );
      expect(_target('community_liked'), isNull);
    });

    test('every target lands on slot 3 of its own space', () {
      for (final target in NotificationSpaceTarget.values) {
        expect(target.tab, 2);
        expect(NotificationSpaceTarget.forSpace(target.space), target);
      }
    });
  });

  group('CrossSpaceNotificationSheet', () {
    final item = NotificationModel(
      id: 'n1',
      type: 'project_reported_inactive',
      title: 'Gem reported as unmaintained',
      body: 'One member reports its hunter has gone quiet.',
      isRead: false,
      createdAt: DateTime(2026, 9, 1),
    );

    Future<bool?> tapInSheet(WidgetTester tester, String button) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showCrossSpaceNotificationSheet(
                context,
                item: item,
                target: NotificationSpaceTarget.moderationHub,
                currentSpaceLabel: 'User',
              );
            },
            child: const Text('open'),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Switch and open'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('Switch and open resolves true', (tester) async {
      expect(await tapInSheet(tester, 'Switch and open'), isTrue);
    });

    testWidgets('Close resolves false', (tester) async {
      expect(await tapInSheet(tester, 'Close'), isFalse);
    });
  });
}
