import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../main_screen.dart';

class AnalysisStep extends StatefulWidget {
  final String name;
  final int genderIndex;
  final int age;
  final int height;
  final double weight;
  final int goalIndex;
  final String apiKey;
  final String language;

  const AnalysisStep({
    super.key,
    required this.name,
    required this.genderIndex,
    required this.age,
    required this.height,
    required this.weight,
    required this.goalIndex,
    required this.apiKey,
    required this.language,
  });

  @override
  State<AnalysisStep> createState() => _AnalysisStepState();
}

class _AnalysisStepState extends State<AnalysisStep> {
  @override
  void initState() {
    super.initState();
    _processData();
  }

  Future<void> _processData() async {
    // Fake loading delay for engagement
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Save User
    final user = UserModel(
      name: widget.name,
      birthdate: DateTime(DateTime.now().year - widget.age),
      height: widget.height.toDouble(),
      weight: widget.weight,
      language: widget.language,
      geminiApiKey: widget.apiKey,
      onboardingCompleted: true,
    );

    await context.read<AppProvider>().saveUser(user);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDe = widget.language == 'de';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            isDe ? 'Wir erstellen deinen Plan...' : 'Building your plan...',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            isDe ? 'Metabolismus wird analysiert' : 'Analyzing your metabolism',
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
