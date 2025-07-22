import 'package:blocnet/features/projects/presentation/widgets/shared/app_bar.dart';
import 'package:blocnet/shared/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: ''),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: const Column(
          children: [StyledBodyText700('Trending posts will appear here...')],
        ),
      ),
    );
  }
}
