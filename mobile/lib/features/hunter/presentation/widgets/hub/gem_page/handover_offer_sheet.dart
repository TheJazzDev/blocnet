import 'package:blocnet/features/hunter/presentation/widgets/hub/gem_page/handover_sheet_frame.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_input.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/hub_styles.dart';
import 'package:blocnet/services/hunter/hunter_board_store.dart';
import 'package:blocnet/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// *Hand over {gem}* — choose a hunter, add an optional note, send the
/// invite. Pops with the chosen username (without `@`) once the backend has
/// the invite; a refusal stays in the sheet as an inline line.
class HandoverOfferSheet extends StatefulWidget {
  const HandoverOfferSheet({
    super.key,
    required this.projectId,
    required this.gemName,
    this.search,
    this.ownUsername,
  });

  static const int maxNoteLength = 280;

  static const String explainer =
      'The hunter you choose gets an invite. If they accept, the gem and the '
      'obligation to keep it current are theirs. Members\' waits and reports '
      'stay with the gem.';

  final String projectId;
  final String gemName;

  /// Injectable for tests; defaults to `/profiles/search`.
  final ProfileSearch? search;

  /// Left out of suggestions (you cannot hand a gem to yourself).
  final String? ownUsername;

  @override
  State<HandoverOfferSheet> createState() => _HandoverOfferSheetState();
}

class _HandoverOfferSheetState extends State<HandoverOfferSheet> {
  final _hunter = TextEditingController();
  final _note = TextEditingController();

  /// Errors are only this sheet's once it has sent something.
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _hunter.addListener(_rebuild);
  }

  @override
  void dispose() {
    _hunter.removeListener(_rebuild);
    _hunter.dispose();
    _note.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// What the backend receives: `@username` as typed, or a bare profile id.
  String get _hunterValue => _hunter.text.trim();

  bool get _hasHunter => _hunterValue.replaceFirst('@', '').trim().isNotEmpty;

  Future<void> _offer(HunterBoardStore store) async {
    if (!_hasHunter) return;
    setState(() => _sent = true);
    final value = _hunterValue;
    final inviteId = await store.startHandover(
      widget.projectId,
      value,
      note: _note.text,
    );
    if (!mounted || inviteId == null) return;
    Navigator.of(context).pop(value.replaceFirst('@', ''));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HunterBoardStore>();
    final busy = store.isHandoverBusy(widget.projectId);
    final error = _sent ? store.handoverErrorFor(widget.projectId) : null;

    return HandoverSheetFrame(
      key: const ValueKey('handover-offer-sheet'),
      title: 'Hand over ${widget.gemName}',
      body: HandoverOfferSheet.explainer,
      children: [
        UsernameSuggestField(
          controller: _hunter,
          search: widget.search,
          excludeUsername: widget.ownUsername,
          inputBuilder: (context, onChanged) => HubInput(
            fieldKey: const ValueKey('handover-hunter'),
            label: 'HUNTER',
            hint: '@username',
            controller: _hunter,
            onChanged: onChanged,
            enabled: !busy,
          ),
        ),
        const SizedBox(height: 14),
        HubInput(
          fieldKey: const ValueKey('handover-note'),
          label: 'NOTE (OPTIONAL)',
          hint: 'Anything they should know',
          controller: _note,
          maxLength: HandoverOfferSheet.maxNoteLength,
          maxLines: 3,
          enabled: !busy,
        ),
        if (error != null) HandoverSheetError(message: error),
        const SizedBox(height: 12),
        AppButton(
          key: const ValueKey('handover-offer'),
          label: 'Offer handover',
          isLoading: busy,
          onPressed: _hasHunter ? () => _offer(store) : null,
          color: HubTone.accent,
          size: AppButtonSize.compact,
        ),
      ],
    );
  }
}

/// The snackbar line once a handover has been offered.
String handoverOfferedMessage(String username) =>
    'Handover offered to @$username. You stay responsible until they accept.';
