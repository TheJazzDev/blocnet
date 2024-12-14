import 'package:blocknet/app/app_theme.dart';
import 'package:blocknet/shared/styles/text.dart';
import 'package:flutter/material.dart';

class StyledToggleButton extends StatefulWidget {
  const StyledToggleButton({
    super.key,
    required this.text1,
    required this.text2,
    required this.activeSection,
    required this.onToggle,
  });

  final String text1;
  final String text2;
  final String activeSection;
  final Function(String) onToggle;

  @override
  State<StyledToggleButton> createState() => _StyledToggleButtonState();
}

class _StyledToggleButtonState extends State<StyledToggleButton> {
  late String _activeSection;

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
            text: widget.text1,
            isActive: _activeSection == 'first-section',
            onPressed: () {
              setState(() {
                _activeSection = 'first-section';
              });
              widget.onToggle('first-section');
            },
          ),
          _buildButton(
            text: widget.text2,
            isActive: _activeSection == 'second-section',
            onPressed: () {
              setState(() {
                _activeSection = 'second-section';
              });
              widget.onToggle('second-section');
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        backgroundColor: isActive ? AppColors.darkGrey800 : Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(40)),
        ),
      ),
      child: StyledHeading2(
        text,
        style: TextStyle(
          color: isActive ? AppColors.darkGrey100 : AppColors.darkGrey400,
        ),
      ),
    );
  }
}
