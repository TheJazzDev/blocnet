import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/typography.dart';
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
                  child: viewModel.filteredPosts.isEmpty
                      ? _EmptyState(priority: priority)
                      : SingleChildScrollView(
                          child: Column(
                            children: List.generate(
                              viewModel.filteredPosts.length,
                              (index) => UpdateCard(
                                  post: viewModel.filteredPosts[index]),
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

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.priority});

  final Priority priority;

  String _getMessage() {
    if (priority == Priority.high) {
      return 'No high urgency updates at the moment.\nEverything is under control!';
    } else if (priority == Priority.mid) {
      return 'No medium urgency updates right now.\nCheck back later for important updates.';
    }
    return 'No low urgency updates available.\nCheck back soon!';
  }

  String _getTitle() {
    if (priority == Priority.high) return 'No High Urgency Updates';
    if (priority == Priority.mid) return 'No Medium Urgency Updates';
    return 'No Low Urgency Updates';
  }

  IconData _getIcon() {
    if (priority == Priority.high) return Icons.emergency_rounded;
    if (priority == Priority.mid) return Icons.brightness_5_rounded;
    return Icons.sentiment_satisfied_rounded;
  }

  Color _getColor() {
    return priority.color;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(
                _getIcon(),
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getTitle(),
              style: AppTypography.custom(
                color: AppColors.textPrimary,
                size: 18,
                weight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getMessage(),
              style: AppTypography.custom(
                color: AppColors.textMuted,
                size: 14,
                weight: FontWeight.w400,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
