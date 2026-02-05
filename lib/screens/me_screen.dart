import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../extensions/l10n_extension.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'settings_screen.dart';
import 'add_weight_screen.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final l10n = context.l10n;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.styrianForest),
      );
    }

    final todayStats = provider.getTodayStats();
    final weights = provider.getAllWeights();

    return Scaffold(
      backgroundColor: AppColors.limestone,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Spacer for centering title
                  Text(
                    l10n.profile,
                    style: AppTypography.displayMedium.copyWith(fontSize: 24),
                  ),
                  IconButton(
                    icon: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.settings
                          : Icons.settings_outlined,
                      color: AppColors.slate,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Profile Header (Centered)
              _buildCenteredProfile(context, user),

              const SizedBox(height: 32),

              // BMI & Quick Stats
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      l10n.yourBmi.toUpperCase(),
                      user.bmi.toStringAsFixed(1),
                      AppColors.styrianForest,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      l10n.status.toUpperCase(),
                      _getLocalizedCategory(context, user.bmiCategory),
                      _getCategoryColor(user.bmiCategory),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Today's Stats Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.today,
                    style: AppTypography.displayMedium.copyWith(fontSize: 22),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    color: AppColors.styrianForest,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTodayStatsGrid(context, user, todayStats),

              const SizedBox(height: 40),

              // Reminders Section
              _buildRemindersSection(context, provider),

              const SizedBox(height: 40),

              // Weight Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.weightProgress,
                    style: AppTypography.displayMedium.copyWith(fontSize: 22),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddWeightScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.styrianForest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.pebble,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeightChart(context, weights),

              const SizedBox(height: 24),

              // Precise Weight List
              _buildWeightList(context, weights),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredProfile(BuildContext context, UserModel user) {
    final l10n = context.l10n;
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.styrianForest,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pebble, width: 1),
          ),
          child: Center(
            child: Text(
              user.name.isNotEmpty ? user.name[0] : '?',
              style: const TextStyle(
                fontSize: 40,
                color: AppColors.pebble,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: AppTypography.displayMedium.copyWith(fontSize: 32),
        ),
        Text(
          '${user.age} ${l10n.years} • ${user.height.toInt()} ${l10n.cm}',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14,
            color: AppColors.slate.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.pebble.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getGoalText(context, user.goal),
            style: AppTypography.labelLarge.copyWith(
              fontSize: 12,
              color: AppColors.styrianForest,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: AppColors.slate.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.slate.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.dataMedium.copyWith(color: color, height: 1.1),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatsGrid(
    BuildContext context,
    UserModel user,
    Map<String, double> stats,
  ) {
    final l10n = context.l10n;
    // Ensure we have the grid view package or use a column of rows if not available
    // Assuming StaggeredGrid is available from context based on previous files
    // If not, we'll use a Wrap/Column structure

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n.calories,
                value:
                    '${stats['calories']!.toInt()} / ${user.dailyCalorieTarget.toInt()}',
                unit: l10n.kcal,
                icon: Icons.local_fire_department_outlined,
                color: AppColors.primary,
                progress: stats['calories']! / user.dailyCalorieTarget,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: l10n.protein,
                value:
                    '${stats['protein']!.toInt()} / ${user.dailyProteinTarget.toInt()}',
                unit: l10n.grams,
                icon: Icons.fitness_center_outlined,
                color: AppColors.styrianForest,
                progress: stats['protein']! / user.dailyProteinTarget,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: l10n.carbs,
                value: '${stats['carbs']!.toInt()}',
                unit: l10n.grams,
                icon: Icons.bakery_dining_outlined,
                color: AppColors.limestone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: l10n.fats,
                value: '${stats['fats']!.toInt()}',
                unit: l10n.grams,
                icon: Icons.opacity_outlined,
                color: AppColors.limestone,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    double? progress,
  }) {
    final isPrimary =
        color == AppColors.primary || color == AppColors.styrianForest;
    final textColor = isPrimary ? AppColors.limestone : AppColors.slate;
    final subTextColor = isPrimary
        ? AppColors.limestone.withValues(alpha: 0.7)
        : AppColors.slate.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary ? color : AppColors.pebble,
        borderRadius: BorderRadius.circular(20),
        border: isPrimary ? null : Border.all(color: AppColors.pebble),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: subTextColor),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 10,
                  color: subTextColor,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTypography.dataMedium.copyWith(
              color: textColor,
              fontSize: 18,
            ),
          ),
          Text(
            unit,
            style: AppTypography.bodyMedium.copyWith(
              color: subTextColor,
              fontSize: 12,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.black.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPrimary ? AppColors.limestone : AppColors.primary,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemindersSection(BuildContext context, AppProvider provider) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reminders,
          style: AppTypography.displayMedium.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.pebble,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.pebble),
          ),
          child: Column(
            children: [
              _buildReminderToggle(
                l10n.logMeals,
                l10n.logMealsSubtitle,
                provider.mealRemindersEnabled,
                (val) => provider.setMealReminders(val),
              ),
              const Divider(height: 32, color: AppColors.pebble),
              _buildReminderToggle(
                l10n.logWeight,
                l10n.logWeightSubtitle,
                provider.weightRemindersEnabled,
                (val) => provider.setWeightReminders(val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(fontSize: 16),
              ),
              Text(
                subtitle,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 12,
                  color: AppColors.slate.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeThumbColor: AppColors.pebble.withValues(alpha: 0.5),
          activeTrackColor: AppColors.styrianForest,
          onChanged: (val) {
            HapticFeedback.lightImpact();
            onChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildWeightChart(BuildContext context, List<WeightModel> weights) {
    final l10n = context.l10n;
    if (weights.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.limestone,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.pebble),
        ),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: AppColors.slate.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noDataAvailable,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.slate.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final recentWeights = weights.take(14).toList().reversed.toList();
    double minWeight = recentWeights
        .map((e) => e.weight)
        .reduce((a, b) => a < b ? a : b);
    double maxWeight = recentWeights
        .map((e) => e.weight)
        .reduce((a, b) => a > b ? a : b);

    // Dynamic padding
    double minY = (minWeight - 1).floorToDouble();
    double maxY = (maxWeight + 1).ceilToDouble();
    // Ensure we have some range
    if (maxY == minY) {
      maxY += 1;
      minY -= 1;
    }

    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.limestone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGrey),
        // No boxShadow - flat design mandate
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4, // roughly 4 lines
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.pebble.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recentWeights.length) {
                    return const SizedBox.shrink();
                  }
                  final date = recentWeights[index].date;
                  final dateStr = '${date.day}.${date.month}';

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        color: AppColors.slate.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxY - minY) / 4,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == minY || value == maxY) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: AppColors.slate.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: recentWeights.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.weight);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.styrianForest,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.limestone,
                      strokeWidth: 2,
                      strokeColor: AppColors.styrianForest,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.styrianForest.withValues(alpha: 0.2),
                    AppColors.styrianForest.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppColors.styrianForest,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots
                    .map((LineBarSpot touchedSpot) {
                      final index = touchedSpot.x.toInt();
                      // Check index bounds safety
                      if (index < 0 || index >= recentWeights.length) {
                        return null;
                      }
                      final date = recentWeights[index].date;
                      final dateStr = '${date.day}.${date.month}';

                      final textStyle = TextStyle(
                        color: AppColors.limestone,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                      return LineTooltipItem(
                        '$dateStr\n${touchedSpot.y.toStringAsFixed(1)} ${l10n.kg}',
                        textStyle,
                      );
                    })
                    .whereType<LineTooltipItem>()
                    .toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeightList(BuildContext context, List<WeightModel> weights) {
    if (weights.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final recentWeights = weights.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.recentHistory,
            style: AppTypography.titleLarge.copyWith(
              fontSize: 14,
              color: AppColors.slate.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.pebble,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppColors.pebble),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentWeights.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.pebble,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final w = recentWeights[index];
              final dateStr =
                  '${w.date.day.toString().padLeft(2, '0')}.${w.date.month.toString().padLeft(2, '0')}.${w.date.year}';

              return Dismissible(
                key: Key(w.date.toIso8601String()),
                direction: DismissDirection.endToStart,
                background: Container(
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  context.read<AppProvider>().deleteWeight(w.date);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${w.weight.toStringAsFixed(1)} ${l10n.kg}',
                        style: AppTypography.dataMedium.copyWith(
                          fontSize: 18,
                          color: AppColors.styrianForest,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getLocalizedCategory(BuildContext context, String category) {
    final l10n = context.l10n;
    switch (category.toLowerCase()) {
      case 'underweight':
        return l10n.bmiUnderweight;
      case 'normal':
        return l10n.bmiNormal;
      case 'overweight':
        return l10n.bmiOverweight;
      case 'obese':
        return l10n.bmiObese;
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'normal' || 'underweight':
        return AppColors.styrianForest;
      default:
        return AppColors.error;
    }
  }

  String _getGoalText(BuildContext context, int goal) {
    final l10n = context.l10n;
    switch (goal) {
      case 0:
        return l10n.goalWeightLoss;
      case 2:
        return l10n.goalMuscleGain;
      case 1:
      default:
        return l10n.goalMaintainWeight;
    }
  }
}
