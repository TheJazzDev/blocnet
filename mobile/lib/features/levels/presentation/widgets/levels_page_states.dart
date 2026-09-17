import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/badges/presentation/widgets/progress_style.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Full-body loading spinner for the levels page.
class LevelsLoadingState extends StatelessWidget {
  const LevelsLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: AppColors.primary500),
    );
  }
}

/// Full-body error with a retry button.
class LevelsErrorState extends StatelessWidget {
  const LevelsErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppEmptyState.error(
        title: 'Could not load levels',
        message: progressErrorText(
          message,
          fallback: 'Check your connection and try again.',
        ),
        onAction: onRetry,
      ),
    );
  }
}

/// Full-body empty state when the server returns no levels.
class LevelsEmptyState extends StatelessWidget {
  const LevelsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppEmptyState(
        icon: Icons.military_tech_outlined,
        title: 'No levels yet',
      ),
    );
  }
}
