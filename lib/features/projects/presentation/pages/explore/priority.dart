import 'package:blocknet/features/projects/data/models/priority_model.dart';
import 'package:blocknet/features/projects/presentation/viewmodels/priority_screen_view_model.dart';
import 'package:blocknet/features/projects/presentation/widgets/app_bar.dart';
import 'package:blocknet/features/projects/presentation/widgets/filter_label/filter_label.dart';
import 'package:blocknet/features/projects/presentation/widgets/post/post_card/post_card.dart';
import 'package:blocknet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class PriorityScreens extends StatefulWidget {
  const PriorityScreens({super.key});

  @override
  State<PriorityScreens> createState() => _PriorityScreensState();
}

class _PriorityScreensState extends State<PriorityScreens> {
  late PriorityScreenViewModel viewModel;

  // Get priority from the page and pass it to the fetchposts
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final priority = args?['priority'] ?? Priority.high;

    viewModel = PriorityScreenViewModel(priority: priority);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: ''),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              children: [
                StyledBodyText700('${viewModel.priority} Urgency'),
                FilterLabel(
                  selectedTags: viewModel.selectedFilters,
                  unselectedTags: viewModel.allSecondaryTags,
                  onTagToggle: (tag) {
                    setState(() {
                      viewModel.toggleTag(tag);
                    });
                  },
                )
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(
                    viewModel.filteredPosts.length,
                    (index) => PostCard(post: viewModel.filteredPosts[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
