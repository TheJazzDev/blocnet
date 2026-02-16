import 'package:blocnet/app/theme.dart';
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey100,
        borderRadius: const BorderRadius.all(Radius.circular(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            text: widget.section1.label,
            isActive: _activeSection == widget.section1,
            onPressed: () {
              setState(() {
                _activeSection = widget.section1;
              });
              widget.onToggle(widget.section1);
            },
          ),
          _buildButton(
            text: widget.section2.label,
            isActive: _activeSection == widget.section2,
            onPressed: () {
              setState(() {
                _activeSection = widget.section2;
              });
              widget.onToggle(widget.section2);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        backgroundColor: isActive ? AppColors.darkGrey800 : Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? AppColors.darkGrey100 : AppColors.darkGrey400,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'Britti',
        ),
      ),
    );
  }
}
