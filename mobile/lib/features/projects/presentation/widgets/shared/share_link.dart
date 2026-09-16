import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Web link that opens [deepPath] in the app, as update cards share it.
String blocnetShareLink(String deepPath) =>
    'https://blocnet.app/open?path=${Uri.encodeComponent(deepPath)}';

/// Opens the system share sheet with [title] and a link to [deepPath].
/// Same text and fallback as `FeedCard`'s share.
Future<void> shareBlocnetLink(
  BuildContext context, {
  required String title,
  required String deepPath,
}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: '$title\n${blocnetShareLink(deepPath)}',
        subject: title,
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    AppSnackbar.showError(context, 'Unable to open share options right now.');
  }
}
