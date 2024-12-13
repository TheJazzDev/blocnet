import 'package:blocknet/features/projects/data/models/priority.dart';
import 'package:flutter/material.dart';

class PriorityLabel extends StatelessWidget {
  const PriorityLabel(this.urgency, {super.key});

  final Priority urgency;

  @override
  Widget build(BuildContext context) {
    Color urgencyColor = urgency.color;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      decoration: BoxDecoration(
          border: Border.all(
            color: urgencyColor,
          ),
          borderRadius: BorderRadius.all(Radius.circular(30))),
      child: Row(
        children: [
          _buildDivider(urgencyColor),
          SizedBox(width: 6),
          Text(
            '${urgency.label[0].toUpperCase()}${urgency.label.substring(1).toLowerCase()} Urgency',
            style: TextStyle(color: urgencyColor, fontSize: 12),
          )
        ],
      ),
    );
  }

  // Modify the divider to accept the color
  Widget _buildDivider(Color color) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(8),
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
