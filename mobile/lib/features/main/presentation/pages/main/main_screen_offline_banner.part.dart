// part of '../main_screen.dart';

// class _OfflineStatusBanner extends StatelessWidget {
//   const _OfflineStatusBanner();

//   @override
//   Widget build(BuildContext context) {
//     final connectivity = context.watch<ConnectivityStore>();
//     if (!connectivity.hasEvaluated || !connectivity.isOffline) {
//       return const SizedBox.shrink();
//     }

//     return Positioned(
//       top: MediaQuery.paddingOf(context).top + 10,
//       left: 0,
//       right: 0,
//       child: IgnorePointer(
//         ignoring: true,
//         child: Center(
//           child: Tooltip(
//             message: 'No internet connection',
//             child: Container(
//               width: 28,
//               height: 28,
//               decoration: BoxDecoration(
//                 color: AppColors.warning500,
//                 shape: BoxShape.circle,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.24),
//                     blurRadius: 14,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.wifi_off_rounded,
//                 size: 14,
//                 color: Colors.black,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
