import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/moderation/data/models/community_appeal_model.dart';
import 'package:blocnet/features/moderation/presentation/widgets/appeals/appeal_card.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_app_bar.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_dropdown.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_input_dialogs.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_queue_body.dart';
import 'package:blocnet/features/moderation/presentation/widgets/common/mod_styles.dart';
import 'package:blocnet/services/api/api_client.dart';
import 'package:blocnet/services/api/api_error.dart';
import 'package:blocnet/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';

/// Members contesting a moderation decision. An admin overturns or upholds.
class AppealsQueueScreen extends StatefulWidget {
  const AppealsQueueScreen({this.apiClient, super.key});

  /// Injectable for tests.
  final ApiClient? apiClient;

  @override
  State<AppealsQueueScreen> createState() => _AppealsQueueScreenState();
}

enum _Decision {
  overturn('overturn', 'Overturn decision', 'Overturn', 'Appeal overturned'),
  uphold('uphold', 'Uphold decision', 'Uphold', 'Decision upheld');

  const _Decision(this.apiValue, this.title, this.action, this.done);

  final String apiValue;
  final String title;
  final String action;
  final String done;
}

class _AppealsQueueScreenState extends State<AppealsQueueScreen> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();
  List<CommunityAppeal> _appeals = [];
  bool _isLoading = false;
  bool _reloadQueued = false;
  String? _error;
  String? _statusFilter;
  String? _reviewingId;

  static const Map<String?, String> _statusOptions = {
    null: 'All',
    'pending': 'Pending',
    'under_review': 'Under review',
    'approved': 'Approved',
    'rejected': 'Rejected',
  };

  @override
  void initState() {
    super.initState();
    _loadAppeals();
  }

  Future<void> _loadAppeals() async {
    if (_isLoading) {
      _reloadQueued = true;
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.get(
        '/community/moderation/appeals',
        query: {
          'limit': '50',
          if (_statusFilter != null) 'status': _statusFilter!,
        },
      );
      final rows = response is Map ? response['appeals'] : null;
      if (!mounted) return;
      setState(() {
        _appeals = (rows is List ? rows : const [])
            .whereType<Map<String, dynamic>>()
            .map(CommunityAppeal.fromApi)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to load appeals: $e');
      setState(() {
        _error = describeApiError(e, fallback: 'Appeals could not be loaded.');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted && _reloadQueued) {
      _reloadQueued = false;
      await _loadAppeals();
    }
  }

  void _onStatusFilterChanged(String? value) {
    setState(() {
      _statusFilter = value;
      _appeals = [];
    });
    _loadAppeals();
  }

  Future<void> _review(CommunityAppeal appeal, _Decision decision) async {
    final notes = await showModReasonDialog(
      context,
      title: decision.title,
      hint: 'Why?',
      required: false,
      confirmLabel: decision.action,
    );
    if (notes == null || !mounted) return;

    setState(() => _reviewingId = appeal.id);
    try {
      await _apiClient.patch(
        '/community/moderation/appeals/${appeal.id}',
        body: {
          'decision': decision.apiValue,
          if (notes.isNotEmpty) 'reviewNotes': notes,
        },
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, decision.done);
      await _loadAppeals();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        describeApiError(e, fallback: 'The review did not go through.'),
      );
    } finally {
      if (mounted) setState(() => _reviewingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: const ModAppBar(title: 'Appeals'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              ModTone.gutter,
              AppSpace.md,
              ModTone.gutter,
              AppSpace.md,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: ModDropdown<String?>(
              label: 'Status',
              value: _statusFilter,
              options: _statusOptions,
              onChanged: _onStatusFilterChanged,
            ),
          ),
          Expanded(
            child: ModQueueBody(
              isLoading: _isLoading,
              error: _error,
              itemCount: _appeals.length,
              onRefresh: _loadAppeals,
              errorTitle: 'Appeals did not load',
              emptyIcon: Icons.gavel_outlined,
              emptyTitle: 'No appeals',
              emptyMessage: 'Nothing matches this filter.',
              itemBuilder: (context, index) {
                final appeal = _appeals[index];
                return AppealCard(
                  appeal: appeal,
                  busy: _reviewingId != null,
                  onOverturn: () => _review(appeal, _Decision.overturn),
                  onUphold: () => _review(appeal, _Decision.uphold),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
