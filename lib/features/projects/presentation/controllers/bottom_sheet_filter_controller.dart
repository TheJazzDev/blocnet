import 'package:blocknet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocknet/features/projects/data/models/priority_model.dart';
import 'package:blocknet/features/projects/data/models/secondary_tag_model.dart';

class BottomSheetFilterController {
  // State for selected/unselected tags and priorities
  Set<String> primaryTags = Set.from(PrimaryTag.getAll());
  Set<String> secondaryTags = Set.from(SecondaryTag.getAll());
  Set<Priority> priorities = Set.from(Priority.getAll());

  Set<String> selectedPrimaryTags = {};
  Set<String> selectedSecondaryTags = {};
  Set<Priority> selectedPriorities = {};

  bool get isEnabled =>
      selectedPrimaryTags.isNotEmpty ||
      selectedSecondaryTags.isNotEmpty ||
      selectedPriorities.isNotEmpty;

  // Toggle methods for tags and priorities
  void togglePrimaryTag(String tag) {
    if (selectedPrimaryTags.contains(tag)) {
      selectedPrimaryTags.remove(tag);
      primaryTags.add(tag);
    } else {
      selectedPrimaryTags.add(tag);
      primaryTags.remove(tag);
    }
  }

  void toggleSecondaryTag(String tag) {
    if (selectedSecondaryTags.contains(tag)) {
      selectedSecondaryTags.remove(tag);
      secondaryTags.add(tag);
    } else {
      selectedSecondaryTags.add(tag);
      secondaryTags.remove(tag);
    }
  }

  void togglePriority(Priority priority) {
    if (selectedPriorities.contains(priority)) {
      selectedPriorities.remove(priority);
      priorities.add(priority);
    } else {
      selectedPriorities.add(priority);
      priorities.remove(priority);
    }
  }

  void clearAllFilters() {
    primaryTags.addAll(selectedPrimaryTags);
    selectedPrimaryTags.clear();

    secondaryTags.addAll(selectedSecondaryTags);
    selectedSecondaryTags.clear();

    priorities.addAll(selectedPriorities);
    selectedPriorities.clear();
  }

  Map<String, dynamic> getFilters() {
    return {
      'primaryTags': selectedPrimaryTags.toList(),
      'secondaryTags': selectedSecondaryTags.toList(),
      'priorities': selectedPriorities.toList(),
    };
  }
}
