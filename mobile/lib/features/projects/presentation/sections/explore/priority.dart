import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/presentation/viewmodels/priority_screen_view_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/features/projects/presentation/widgets/filter_label/filter_label.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/update_card/update_card.dart';
import 'package:blocnet/services/projects/updates_store.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PriorityScreens extends StatefulWidget {
  const PriorityScreens({super.key});

  @override
  State<PriorityScreens> createState() => _PriorityScreensState();
}

class _PriorityScreensState extends State<PriorityScreens> {
  late PriorityScreenViewModel viewModel;
  late Priority priority;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    priority = args?['priority'] ?? Priority.high;
    viewModel = PriorityScreenViewModel(priority: priority);
    Provider.of<UpdatesStore>(context, listen: false).fetchUpdatesOnce();

    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final title = _priorityTitle(priority);
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: CustomAppBar(title: title, backButton: true),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Consumer<UpdatesStore>(
          builder: (context, postsStore, _) {
            viewModel.setPosts(postsStore.posts);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: [
                    FilterLabel(
                      selectedTags: viewModel.selectedFilters,
                      unselectedTags: viewModel.allSecondaryTags,
                      onTagToggle: (tag) {
                        setState(() {
                          viewModel.toggleTag(tag);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        viewModel.filteredPosts.length,
                        (index) =>
                            UpdateCard(post: viewModel.filteredPosts[index]),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _priorityTitle(Priority selectedPriority) {
    if (selectedPriority == Priority.high) return 'High Urgency';
    if (selectedPriority == Priority.mid) return 'Medium Urgency';
    return 'Low Urgency';
  }
}
