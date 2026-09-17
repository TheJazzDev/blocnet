import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/primary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_choice_fields.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The text a proposal is made of, owned by the screen.
class SubmitGemControllers {
  final name = TextEditingController();
  final symbol = TextEditingController();
  final website = TextEditingController();
  final description = TextEditingController();
  final reason = TextEditingController();

  void dispose() {
    for (final c in [name, symbol, website, description, reason]) {
      c.dispose();
    }
  }
}

/// Submit New Gem's fields, in two flat sections. Limits match the
/// server's (`CreateProjectProposalDto`).
class SubmitGemForm extends StatelessWidget {
  const SubmitGemForm({
    super.key,
    required this.formKey,
    required this.fields,
    required this.chains,
    required this.chainId,
    required this.onChain,
    required this.busy,
    required this.onSubmit,
    this.error,
  });

  final GlobalKey<FormState> formKey;
  final SubmitGemControllers fields;
  final List<PrimaryTag> chains;
  final String? chainId;
  final ValueChanged<String> onChain;
  final bool busy;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.xl + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null && error!.isNotEmpty) ComposerErrorNotice(error!),
            ComposerSection(
              icon: Icons.diamond_outlined,
              label: 'The gem',
              children: [
                const ComposerFieldLabel('Name'),
                _field(
                  key: 'submit-name',
                  controller: fields.name,
                  hint: 'e.g. Codawoo',
                  max: 120,
                  validator: _required('Name', min: 2),
                ),
                composerFieldGap,
                const ComposerFieldLabel('Symbol (optional)'),
                _field(
                  key: 'submit-symbol',
                  controller: fields.symbol,
                  hint: 'e.g. COD',
                  max: 40,
                  caps: TextCapitalization.characters,
                ),
                composerFieldGap,
                const ComposerFieldLabel('Website (optional)'),
                _field(
                  key: 'submit-website',
                  controller: fields.website,
                  hint: 'https://example.com',
                  max: 500,
                  keyboard: TextInputType.url,
                  validator: _website,
                ),
                composerFieldGap,
                const ComposerFieldLabel('Chain'),
                _ChainPicker(
                    chains: chains, value: chainId, onChanged: onChain),
              ],
            ),
            ComposerSection(
              icon: Icons.notes_rounded,
              label: 'Why it matters',
              children: [
                const ComposerFieldLabel('Description'),
                _field(
                  key: 'submit-description',
                  controller: fields.description,
                  hint: 'What the gem is and how members take part.',
                  max: 3000,
                  lines: 5,
                  validator: _required('Description', min: 12),
                ),
                composerFieldGap,
                const ComposerFieldLabel('Note for reviewers (optional)'),
                _field(
                  key: 'submit-reason',
                  controller: fields.reason,
                  hint: 'Team, backers, risk checks.',
                  max: 2000,
                  lines: 3,
                ),
              ],
            ),
            AppSpace.gapSm,
            ComposerSubmitButton(
              label: 'Submit for approval',
              icon: Icons.send_rounded,
              busy: busy,
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String key,
    required TextEditingController controller,
    required String hint,
    required int max,
    int lines = 1,
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.sentences,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      key: ValueKey(key),
      controller: controller,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines * 2,
      keyboardType: keyboard,
      autocorrect: keyboard != TextInputType.url,
      textCapitalization:
          keyboard == TextInputType.url ? TextCapitalization.none : caps,
      inputFormatters: [LengthLimitingTextInputFormatter(max)],
      style: composerValueStyle(),
      decoration: composerFieldDecoration(hintText: hint),
      validator: validator,
    );
  }

  static FormFieldValidator<String> _required(String label,
      {required int min}) {
    return (value) {
      final next = value?.trim() ?? '';
      if (next.isEmpty) return '$label is required';
      if (next.length < min) return 'Use at least $min characters';
      return null;
    };
  }

  static String? _website(String? value) {
    final next = value?.trim() ?? '';
    if (next.isEmpty) return null;
    final withScheme = next.contains('://') ? next : 'https://$next';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.host.contains('.')) {
      return 'Enter a web address, like example.com';
    }
    return null;
  }
}

class _ChainPicker extends StatelessWidget {
  const _ChainPicker({
    required this.chains,
    required this.value,
    required this.onChanged,
  });

  final List<PrimaryTag> chains;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const ValueKey('submit-chain'),
      value: value,
      isExpanded: true,
      decoration: composerFieldDecoration(),
      dropdownColor: AppColors.bgElevated,
      style: composerValueStyle(),
      items: [
        for (final tag in chains)
          DropdownMenuItem<String>(
            value: tag.id,
            child: Text(
              tag.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: composerValueStyle(),
            ),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
      validator: (next) => next == null || next.isEmpty ? 'Pick a chain' : null,
    );
  }
}
