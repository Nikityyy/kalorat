import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_colors.dart';
import '../../extensions/l10n_extension.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../main_screen.dart';

class AnalysisStep extends StatefulWidget {
  final String name;
  final int genderIndex;
  final int age;
  final double height;
  final double weight;
  final int goalIndex;
  final String apiKey;
  final String language;
  final bool healthSyncEnabled;

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
    this.healthSyncEnabled = false,
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
    await context.read<AppProvider>().updateUser(
      name: widget.name,
      birthdate: DateTime(DateTime.now().year - widget.age),
      height: widget.height.toDouble(),
      weight: widget.weight,
      language: widget.language,
      apiKey: widget.apiKey,
      onboardingCompleted: true,
      goal: widget.goalIndex,
      gender: widget.genderIndex,
      healthSyncEnabled: widget.healthSyncEnabled,
      syncMealsToHealth: widget.healthSyncEnabled,
      syncWeightToHealth: widget.healthSyncEnabled,
    );

    if (!mounted) return;

    if (widget.weight > 0) {
      await context.read<AppProvider>().saveWeight(
        WeightModel(weight: widget.weight, date: DateTime.now()),
      );
    }

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(l10n.buildingPlan, style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.analyzingMetabolism, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
