import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../extensions/l10n_extension.dart';
import '../widgets/common/primary_button.dart';
import '../widgets/me/today_stats_grid.dart';
import '../widgets/me/weight_chart.dart';
import '../widgets/me/weight_list.dart';
import '../widgets/me/reminders_section.dart';
import 'onboarding/onboarding_flow.dart';
import 'settings_screen.dart';
import 'add_weight_screen.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final l10n = context.l10n;

    if (user == null) {
      return Center(
        child: PrimaryButton(
          text: l10n.startOnboarding,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OnboardingFlow()),
            );
          },
        ),
      );
    }

    // Sort weights descending by date
    final sortedWeights = List<WeightModel>.from(provider.weights)
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.limestone,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.meTitle,
          style: AppTypography.displayMedium.copyWith(fontSize: 24),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.slate),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user, provider.currentStreak),
            const SizedBox(height: 24),
            _buildSectionHeader(l10n.today),
            const SizedBox(height: 12),
            const TodayStatsGrid(),
            const SizedBox(height: 32),
            _buildSectionHeader(l10n.weight),
            const SizedBox(height: 12),
            WeightChart(weights: sortedWeights),
            const SizedBox(height: 16),
            PrimaryButton(
              text: l10n.logWeight,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddWeightScreen()),
                );
              },
            ),
            if (sortedWeights.isNotEmpty) ...[
              const SizedBox(height: 24),
              WeightList(
                weights: sortedWeights,
                language: provider.language,
                onDelete: (weight) => _confirmDeleteWeight(weight),
              ),
            ],
            const SizedBox(height: 32),
            const RemindersSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, int streak) {
    final l10n = context.l10n;
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.pebble,
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.slate,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: AppTypography.displayMedium.copyWith(fontSize: 20),
              ),
              if (streak > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.streakDays(streak),
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.displayMedium.copyWith(
        fontSize: 18,
        color: AppColors.slate,
      ),
    );
  }

  Future<void> _confirmDeleteWeight(WeightModel weight) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.deleteWeight,
          style: const TextStyle(color: AppColors.slate),
        ),
        content: Text(
          l10n.deleteWeightConfirm,
          style: const TextStyle(color: AppColors.slate),
        ),
        backgroundColor: AppColors.limestone,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.slate),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Fix: Pass weight.date (DateTime) instead of weight (WeightModel)
      await context.read<AppProvider>().deleteWeight(weight.date);
    }
  }
}
