import 'package:blocnet/app/theme.dart';
import 'package:blocnet/app/tokens/tokens.dart';
import 'package:blocnet/features/projects/data/models/sections_model.dart';
import 'package:flutter/material.dart';

class StyledToggleButton extends StatefulWidget {
  const StyledToggleButton({
    super.key,
    required this.section1,
    required this.section2,
    required this.activeSection,
    required this.onToggle,
  });

  final Section section1;
  final Section section2;
  final Section activeSection;
  final Function(Section) onToggle;

  @override
  State<StyledToggleButton> createState() => _StyledToggleButtonState();
}

class _StyledToggleButtonState extends State<StyledToggleButton> {
  late Section _activeSection;

  @override
  void initState() {
    super.initState();
    _activeSection = widget.activeSection;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.hair),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.mdValue),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTab(widget.section1),
          const SizedBox(width: AppSpace.hair),
          _buildTab(widget.section2),
        ],
      ),
    );
  }

  Widget _buildTab(Section section) {
    final isActive = _activeSection == section;
    return GestureDetector(
      onTap: () {
        setState(() => _activeSection = section);
        widget.onToggle(section);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.lg),
        decoration: BoxDecoration(
          color: isActive ? AppColors.bgElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isActive
              ? Border.all(color: AppColors.borderMuted, width: 1)
              : null,
        ),
        child: Text(
          section.label,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: AppText.bodySize,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Geist',
          ),
        ),
      ),
    );
  }
}
