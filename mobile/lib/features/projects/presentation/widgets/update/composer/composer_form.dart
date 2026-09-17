import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/priority_model.dart';
import 'package:blocnet/features/projects/data/models/secondary_tag_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_choice_fields.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_deadline_field.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_fields.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_project_picker.dart';
import 'package:flutter/material.dart';

/// The composer's current choices, owned by the screen.
class ComposerFormState {
  const ComposerFormState({
    required this.projectId,
    required this.priority,
    required this.deadlineAt,
    required this.tagIds,
    required this.isEdit,
    required this.busy,
    this.error,
  });

  final String? projectId;
  final Priority priority;
  final DateTime? deadlineAt;
  final Set<String> tagIds;
  final bool isEdit;
  final bool busy;
  final String? error;
}

/// What the form asks the screen to change.
class ComposerFormCallbacks {
  const ComposerFormCallbacks({
    required this.onProject,
    required this.onPriority,
    required this.onPickDeadline,
    required this.onClearDeadline,
    required this.onToggleTag,
    required this.onSubmit,
  });

  final ValueChanged<String?> onProject;
  final ValueChanged<Priority> onPriority;
  final VoidCallback onPickDeadline;
  final VoidCallback onClearDeadline;
  final void Function(String tagId, bool selected) onToggleTag;
  final VoidCallback onSubmit;
}

/// The update composer's fields, in three flat sections.
class ComposerForm extends StatelessWidget {
  const ComposerForm({
    super.key,
    required this.formKey,
    required this.title,
    required this.content,
    required this.options,
    required this.tags,
    required this.state,
    required this.callbacks,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController title;
  final TextEditingController content;
  final List<ComposerProjectOption> options;
  final List<SecondaryTag> tags;
  final ComposerFormState state;
  final ComposerFormCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final error = state.error;
    // A Column, not a ListView: a field scrolled out of a lazy list leaves
    // the Form and would skip validation.
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
            if (error != null && error.isNotEmpty) ComposerErrorNotice(error),
            ComposerSection(
              icon: Icons.diamond_outlined,
              label: 'Gem',
              children: [
                ComposerProjectPicker(
                  options: options,
                  value: state.projectId,
                  enabled: !state.isEdit,
                  onChanged: callbacks.onProject,
                ),
              ],
            ),
            ComposerSection(
              icon: Icons.flag_outlined,
              label: 'Urgency and window',
              children: [
                const ComposerFieldLabel('Urgency'),
                ComposerPriorityPicker(
                  value: state.priority,
                  onChanged: callbacks.onPriority,
                ),
                composerFieldGap,
                const ComposerFieldLabel('Closing window (optional)'),
                ComposerDeadlineField(
                  value: state.deadlineAt,
                  onPick: callbacks.onPickDeadline,
                  onClear: callbacks.onClearDeadline,
                ),
                composerFieldGap,
                const ComposerFieldLabel('Tags'),
                ComposerTagPicker(
                  tags: tags,
                  selected: state.tagIds,
                  onToggle: callbacks.onToggleTag,
                ),
              ],
            ),
            ComposerSection(
              icon: Icons.edit_note_rounded,
              label: 'Update',
              children: [
                const ComposerFieldLabel('Title'),
                TextFormField(
                  key: const ValueKey('composer-title'),
                  controller: title,
                  style: composerValueStyle(),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: composerFieldDecoration(hintText: 'Update title'),
                  validator: _titleError,
                ),
                composerFieldGap,
                const ComposerFieldLabel('Content'),
                TextFormField(
                  key: const ValueKey('composer-content'),
                  controller: content,
                  minLines: 6,
                  maxLines: 12,
                  style: composerValueStyle(),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: composerFieldDecoration(
                    hintText: 'What changed? Markdown works.',
                  ),
                  validator: _contentError,
                ),
              ],
            ),
            AppSpace.gapSm,
            ComposerSubmitButton(
              label: state.isEdit ? 'Save changes' : 'Publish Update',
              icon: state.isEdit ? Icons.check_rounded : Icons.send_rounded,
              busy: state.busy,
              onTap: callbacks.onSubmit,
            ),
          ],
        ),
      ),
    );
  }

  static String? _titleError(String? value) {
    final next = value?.trim() ?? '';
    if (next.isEmpty) return 'Title is required';
    if (next.length < 6) return 'Use at least 6 characters';
    return null;
  }

  static String? _contentError(String? value) {
    final next = value?.trim() ?? '';
    if (next.isEmpty) return 'Content is required';
    if (next.length < 16) return 'Use at least 16 characters';
    return null;
  }
}
