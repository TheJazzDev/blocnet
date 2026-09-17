import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:flutter/material.dart';

/// Banner on the sign-in screen after the auth server ended the session.
class SessionEndedNotice extends StatelessWidget {
  const SessionEndedNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.warning900.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(
          color: AppColors.warning500.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 18,
            color: AppColors.warning500,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.warning500,
                fontSize: AppText.captionSize,
                fontFamily: 'Geist',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
