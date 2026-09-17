import 'package:flutter/material.dart';

class RouteAccessGate extends StatefulWidget {
  const RouteAccessGate({
    super.key,
    required this.allowAccess,
    required this.redirectTo,
    required this.childBuilder,
  });

  final bool allowAccess;
  final String redirectTo;
  final WidgetBuilder childBuilder;

  @override
  State<RouteAccessGate> createState() => _RouteAccessGateState();
}

class _RouteAccessGateState extends State<RouteAccessGate> {
  /// Shared by every gate: when auth drops, each gated route in the stack
  /// rebuilds in the same frame, and only one of them may redirect.
  static bool _redirectInFlight = false;

  bool _didScheduleRedirect = false;

  @override
  Widget build(BuildContext context) {
    if (widget.allowAccess) {
      _didScheduleRedirect = false;
      return widget.childBuilder(context);
    }

    _scheduleRedirect();
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  void _scheduleRedirect() {
    if (_didScheduleRedirect) return;
    _didScheduleRedirect = true;
    if (_redirectInFlight) return;
    _redirectInFlight = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          widget.redirectTo,
          (Route<dynamic> route) => false,
        );
      } finally {
        _redirectInFlight = false;
      }
    });
  }
}
