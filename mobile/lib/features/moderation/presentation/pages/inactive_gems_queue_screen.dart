import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/moderation/data/models/inactive_gem_model.dart';
import 'package:blocnet/features/moderation/presentation/widgets/inactive_gem_card.dart';
import 'package:blocnet/features/moderation/presentation/widgets/resolve_inactive_gem_dialog.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _apiClient.post(
        '/community/moderation/inactive-gems/${gem.projectId}/resolve',
        body: {
          'outcome': resolution.outcome.apiValue,
          'note': resolution.note,
        },
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Reports on ${gem.projectName} resolved'),
          backgroundColor: AppColors.successColor,
        ),
      );
      setState(() => _gems = _gems
          .where((row) => row.projectId != gem.projectId)
          .toList(growable: false));
      _loadGems();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to resolve: ${describeApiError(e)}',
          ),
          backgroundColor: AppColors.error500,
        ),
      );
    } finally {
      if (mounted) setState(() => _resolvingProjectId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Quiet Gems Reported',
          style: AppTypography.custom(
            color: AppColors.textPrimary,
            size: AppText.subtitleSize,
            weight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _gems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _gems.isEmpty) {
      return Center(
        child: AppEmptyState.error(
          title: 'Reported gems did not load',
          message: _error,
          onAction: _loadGems,
        ),
      );
    }
    if (_gems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadGems,
        color: AppColors.moderationAccent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            AppEmptyState(
              icon: Icons.verified_outlined,
              title: 'No quiet gems reported',
              message:
                  'When members report a gem whose hunter has gone quiet, it appears here.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadGems,
      color: AppColors.moderationAccent,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpace.lg),
        itemCount: _gems.length,
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
