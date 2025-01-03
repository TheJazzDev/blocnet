import 'package:blocknet/features/projects/data/models/priority_model.dart';
import 'package:flutter/material.dart';

class PriorityLabel extends StatelessWidget {
  const PriorityLabel(
      {required this.priority,
      this.isButton = false,
      this.miniCard = false,
      super.key});

  final Priority priority;
  final bool isButton;
  final bool miniCard;

  @override
  Widget build(BuildContext context) {
    Color priorityColor = priority.color;

    if (isButton) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
        decoration: BoxDecoration(
          color: priorityColor,
          borderRadius: const BorderRadius.all(Radius.circular(30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDivider(Colors.black),
            const SizedBox(width: 6),
            Text(
              '${priority.label[0].toUpperCase()}${priority.label.substring(1).toLowerCase()} Urgency',
              style: TextStyle(color: Colors.black, fontSize: 10),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
          vertical: miniCard ? 7 : 8, horizontal: miniCard ? 12 : 14),
      decoration: BoxDecoration(
        border: Border.all(color: priorityColor, width: miniCard ? 0.7 : 1),
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDivider(priorityColor),
          const SizedBox(width: 6),
          Text(
            '${priority.label[0].toUpperCase()}${priority.label.substring(1).toLowerCase()} Urgency',
            style: TextStyle(color: priorityColor, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // Modify the divider to accept the color
  Widget _buildDivider(Color color) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 2),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
