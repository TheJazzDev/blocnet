import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/update_model.dart';
import 'package:blocnet/features/projects/presentation/viewmodels/priority_screen_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

Update _update(String id, Priority priority) {
  return Update(
    id: id,
    title: 'Update $id',
    content: '...',
    adminId: 'u1',
    priority: priority,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1),
    projectId: 'p1',
    description: 'desc',
    secondaryTagIds: const [],
    secondaryTags: const [],
  );
}

void main() {
  final posts = [
    _update('h1', Priority.high),
    _update('h2', Priority.high),
    _update('m1', Priority.mid),
    _update('l1', Priority.low),
  ];

  test('each urgency level only keeps updates of that level', () {
    final high =
        PriorityScreenViewModel(priority: Priority.high, allPosts: posts);
    final mid = PriorityScreenViewModel(priority: Priority.mid, allPosts: posts);
    final low = PriorityScreenViewModel(priority: Priority.low, allPosts: posts);

    expect(high.filteredPosts.map((u) => u.id), ['h1', 'h2']);
    expect(mid.filteredPosts.map((u) => u.id), ['m1']);
    expect(low.filteredPosts.map((u) => u.id), ['l1']);
  });

  test('Priority.fromJson maps the API spellings onto the singletons', () {
    expect(Priority.fromJson('HIGH'), same(Priority.high));
    expect(Priority.fromJson('medium'), same(Priority.mid));
    expect(Priority.fromJson('mid'), same(Priority.mid));
    expect(Priority.fromJson('low'), same(Priority.low));
  });
}
