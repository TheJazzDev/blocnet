import 'package:blocnet/features/hunter/data/models/hunter_reliability_model.dart';
import 'package:blocnet/features/profile/data/models/activity_item_model.dart';
import 'package:blocnet/features/profile/domain/activity_target.dart';
import 'package:blocnet/features/profile/domain/reliability_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_harness.dart';

HunterReliability _public({
  ReliabilityStanding standing = ReliabilityStanding.reliable,
  int gems = 5,
  double? coverage = 0.8,
}) {
  return HunterReliability(
    profileId: 'h1',
    standing: standing,
    gemsOwned: gems,
    updates30d: 9,
    followersTotal: 0,
    tipsReceivedTotal: BigInt.zero,
    membersWaiting: 0,
    openReports: 0,
    coverage: coverage,
  );
}

void main() {
  group('activityTargetFor', () {
    ActivityTarget? target(ActivityItem item) => activityTargetFor(item);

    test('updates open themselves', () {
      for (final action in ['update.create', 'update.update']) {
        expect(target(activity('a', action, resourceId: 'u1')),
            const ActivityTarget(ActivityTargetKind.update, 'u1'));
      }
    });

    test("comments open the comment's update", () {
      for (final action in [
        'comment.create',
        'comment.update',
        'comment.delete'
      ]) {
        expect(
          target(activity('a', action,
              resourceId: 'c1', metadata: {'updateId': 'u9'})),
          const ActivityTarget(ActivityTargetKind.update, 'u9'),
        );
      }
    });

    test('gem actions open the gem, not the follow row', () {
      expect(target(activity('a', 'project.create', resourceId: 'g1')),
          const ActivityTarget(ActivityTargetKind.gem, 'g1'));
      for (final action in [
        'project.follow',
        'project.unfollow',
        'follow.preferences.update',
      ]) {
        expect(
          target(activity('a', action,
              resourceId: 'follow-row', metadata: {'projectId': 'g2'})),
          const ActivityTarget(ActivityTargetKind.gem, 'g2'),
        );
      }
    });

    test('community, people and mining have their own homes', () {
      expect(target(activity('a', 'community_post.create', resourceId: 'p1')),
          const ActivityTarget(ActivityTargetKind.communityPost, 'p1'));
      expect(
        target(activity('a', 'community_post.reaction.add',
            resourceId: 'r1', metadata: {'postId': 'p2'})),
        const ActivityTarget(ActivityTargetKind.communityPost, 'p2'),
      );
      expect(
        target(activity('a', 'profile.follow',
            resourceId: 'uf', metadata: {'followeeId': 'm1'})),
        const ActivityTarget(ActivityTargetKind.person, 'm1'),
      );
      expect(target(activity('a', 'mining.claim')),
          const ActivityTarget(ActivityTargetKind.mine));
    });

    test('nothing to open means no target', () {
      expect(target(activity('a', 'project_proposal.create', resourceId: 'x')),
          isNull);
      expect(target(activity('a', 'comment.create', resourceId: 'c1')), isNull);
      expect(target(activity('a', 'something.new', resourceId: 'x')), isNull);
    });

    test('labels are short and plain', () {
      expect(activity('a', 'update.create').label, 'Posted an update');
      expect(activity('a', 'something_new.done').label, 'Something new done');
    });
  });

  group('ReliabilitySummary.fromReliability', () {
    test('reliable with coverage counts current gems', () {
      final s = ReliabilitySummary.fromReliability(_public());
      expect(s.standing, 'Reliable');
      expect(s.tone, StandingTone.reliable);
      expect(s.detail, '4 of 5 gems current');
    });

    test('no coverage yet shows the gem count, not zero', () {
      final s = ReliabilitySummary.fromReliability(
          _public(standing: ReliabilityStanding.quiet, coverage: null));
      expect(s.tone, StandingTone.slipping);
      expect(s.detail, '5 gems');
    });

    test('new hunters are unscored', () {
      final s = ReliabilitySummary.fromReliability(
          _public(standing: ReliabilityStanding.newHunter, gems: 1));
      expect(s.standing, 'New');
      expect(s.tone, StandingTone.unscored);
      expect(s.detail, '1 gem');
      expect(ReliabilitySummary.fromReliability(_public(gems: 0)).detail,
          'No gems yet');
    });
  });
}
