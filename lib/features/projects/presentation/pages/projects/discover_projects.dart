import 'package:flutter/material.dart';

class DiscoverProjectsSection extends StatefulWidget {
  const DiscoverProjectsSection({super.key});

  @override
  State<DiscoverProjectsSection> createState() =>
      _DiscoverProjectsSectionState();
}

class _DiscoverProjectsSectionState extends State<DiscoverProjectsSection> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Text('Discover projects'),
        const SizedBox(height: 12),
        const SizedBox(height: 16),
      ],
    );
  }
}
