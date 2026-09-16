import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/app/typography.dart';
import 'package:blocnet/features/hunter/data/models/hunter_board_model.dart';
import 'package:blocnet/features/hunter/domain/hub_layout.dart';
import 'package:blocnet/features/hunter/presentation/widgets/hub/parts/gem_state_chip.dart';
import 'package:blocnet/features/projects/data/models/project_model.dart';
import 'package:blocnet/features/projects/presentation/widgets/update/composer/composer_fields.dart';
import 'package:flutter/material.dart';

/// One gem the composer can post to. [chip] is set for the hunter's own
/// board gems, which list first.
@immutable
class ComposerProjectOption {
  const ComposerProjectOption(
      {required this.id, required this.name, this.chip});

  final String id;
  final String name;
  final GemChip? chip;
}

/// The hunter's board gems first, in the board's worst-first order and with
/// their state, then every other gem they may post to.
List<ComposerProjectOption> composerProjectOptions({
  required List<HunterBoardGem> boardGems,
  required List<Project> projects,
}) {
  final seen = <String>{};
  return [
    for (final gem in boardGems)
      if (seen.add(gem.projectId))
        ComposerProjectOption(
            id: gem.projectId, name: gem.name, chip: gem.chip),
    for (final project in projects)
      if (seen.add(project.id))
        ComposerProjectOption(id: project.id, name: project.name),
  ];
}

class ComposerProjectPicker extends StatelessWidget {
  const ComposerProjectPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final List<ComposerProjectOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  /// False in edit mode: an update cannot move to another gem.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: const ValueKey('composer-project'),
      value: value,
      isExpanded: true,
      decoration: composerFieldDecoration(),
      dropdownColor: AppColors.bgElevated,
      style: composerValueStyle(),
      items: [
        for (final option in options)
          DropdownMenuItem<String>(
            value: option.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.custom(
                      color: AppColors.textSecondary,
                      size: AppText.bodySize,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
                if (option.chip != null) ...[
                  const SizedBox(width: AppSpace.sm),
                  GemStateChip(chip: option.chip!),
                ],
              ],
            ),
          ),
      ],
      onChanged: enabled ? onChanged : null,
      validator: (value) =>
          value == null || value.isEmpty ? 'Select a project' : null,
    );
  }
}
