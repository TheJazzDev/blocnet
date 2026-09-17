import 'package:blocnet/app/theme.dart';
import 'package:blocnet/features/moderation/data/models/inactive_gem_model.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_app_bar.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_queue_body.dart';
import 'package:blocnet/features/moderation/presentation/widgets/inactive_gem_card.dart';
import 'package:blocnet/features/moderation/presentation/widgets/resolve_inactive_gem_dialog.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';

/// Gems members have reported as abandoned (F-42), for a moderator to follow
/// up. Resolving closes the reports; it never reassigns the gem.
class InactiveGemsQueueScreen extends StatefulWidget {
  const InactiveGemsQueueScreen({this.apiClient, super.key});

  /// Injectable for tests.
  final ApiClient? apiClient;

  @override
  State<InactiveGemsQueueScreen> createState() =>
      _InactiveGemsQueueScreenState();
}

class _InactiveGemsQueueScreenState extends State<InactiveGemsQueueScreen> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();
  List<InactiveGemReport> _gems = [];
  bool _isLoading = false;
  String? _error;
  String? _resolvingProjectId;

  @override
  void initState() {
    super.initState();
    _loadGems();
  }

  Future<void> _loadGems() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.get(
        '/community/moderation/inactive-gems',
        query: const {'limit': '50'},
      );
      if (!mounted) return;
      setState(() => _gems = InactiveGemReport.listFromApi(response));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to load reported quiet gems: $e');
      setState(() {
        _error = describeApiError(
          e,
          fallback: 'Could not load reported gems.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resolve(InactiveGemReport gem) async {
    final resolution = await ResolveInactiveGemDialog.show(
      context,
      gemName: gem.projectName,
    );
    if (resolution == null || !mounted) return;

    setState(() => _resolvingProjectId = gem.projectId);
    final toast = AppSnackbar.of(context);
    try {
      await _apiClient.post(
        '/community/moderation/inactive-gems/${gem.projectId}/resolve',
        body: {
          'outcome': resolution.outcome.apiValue,
          'note': resolution.note,
        },
      );
      if (!mounted) return;
      toast.success('Reports on ${gem.projectName} resolved');
      setState(() => _gems = _gems
          .where((row) => row.projectId != gem.projectId)
          .toList(growable: false));
      _loadGems();
    } catch (e) {
      if (!mounted) return;
      toast.error(
        describeApiError(e, fallback: 'Could not resolve these reports.'),
      );
    } finally {
      if (mounted) setState(() => _resolvingProjectId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const ModAppBar(title: 'Quiet Gems Reported'),
      body: ModQueueBody(
        isLoading: _isLoading,
        error: _error,
        itemCount: _gems.length,
        onRefresh: _loadGems,
        errorTitle: 'Reported gems did not load',
        emptyIcon: Icons.verified_outlined,
        emptyTitle: 'No quiet gems reported',
        emptyMessage: 'Gems members report as quiet show up here.',
        itemBuilder: (context, index) {
          final gem = _gems[index];
          return InactiveGemCard(
            gem: gem,
            isResolving: _resolvingProjectId == gem.projectId,
            onResolve: () => _resolve(gem),
          );
        },
      ),
    );
  }
}
