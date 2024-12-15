import 'package:blocknet/features/projects/data/models/priority.dart';
import 'package:flutter/material.dart';

class PriorityLabel extends StatelessWidget {
  const PriorityLabel(this.priority, {this.isButton = false, super.key});

  final Priority priority;
  final bool isButton;

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
              style: TextStyle(color: Colors.black, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: priorityColor),
        borderRadius: const BorderRadius.all(Radius.circular(30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDivider(priorityColor),
          const SizedBox(width: 6),
          Text(
            '${priority.label[0].toUpperCase()}${priority.label.substring(1).toLowerCase()} Urgency',
            style: TextStyle(color: priorityColor, fontSize: 12),
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



// import 'package:blocknet/features/projects/data/models/priority.dart';
// import 'package:flutter/material.dart';

// class PriorityLabel extends StatelessWidget {
//   const PriorityLabel(this.priority, {super.key});

//   final Priority priority;

//   @override
//   Widget build(BuildContext context) {
//     Color priorityColor = priority.color;

// // main label
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
//       decoration: BoxDecoration(
//           border: Border.all(
//             color: priorityColor,
//           ),
//           borderRadius: BorderRadius.all(Radius.circular(30))),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _buildDivider(priorityColor),
//           SizedBox(width: 6),
//           Text(
//             '${priority.label[0].toUpperCase()}${priority.label.substring(1).toLowerCase()} Urgency',
//             style: TextStyle(color: priorityColor, fontSize: 12),
//           )
//         ],
//       ),
//     );
//   }

//   // Modify the divider to accept the color
//   Widget _buildDivider(Color color) {
//     return Center(
//       child: Container(
//         margin: const EdgeInsets.only(right: 2),
//         width: 8,
//         height: 8,
//         decoration: BoxDecoration(
//           color: color,
//           shape: BoxShape.circle,
//         ),
//       ),
//     );
//   }
// }
