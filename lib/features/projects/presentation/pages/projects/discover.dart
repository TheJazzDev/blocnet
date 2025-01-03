import 'package:blocknet/features/projects/data/models/sections_model.dart';
import 'package:blocknet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocknet/features/projects/presentation/widgets/shared/toggle_button.dart';
import 'package:flutter/material.dart';
import 'discover_projects.dart';
import 'your_projects.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  Section activeSection = Sections.yourProjects;

  void _handleToggle(Section activeButton) {
    setState(() {
      activeSection = activeButton;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Blocnet', backButton: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StyledToggleButton(
                section1: Sections.yourProjects,
                section2: Sections.discoverProjects,
                activeSection: activeSection,
                onToggle: _handleToggle,
              ),
              const SizedBox(height: 8),
              activeSection == Sections.yourProjects
                  ? YourProjectsSection()
                  : DiscoverProjectsSection()
            ],
          ),
        ),
      ),
    );
  }
}
