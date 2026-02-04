import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'settings_screen.dart';
import 'add_weight_screen.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final isDe = provider.language == 'de';

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.shamrock),
      );
    }

    final todayStats = provider.getTodayStats();
    final weights = provider.getAllWeights();

    return Scaffold(
      backgroundColor: AppColors.lavenderBlush,
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
                    isDe ? 'Mein Profil' : 'My Profile',
                    style: AppTypography.displayMedium.copyWith(fontSize: 24),
                  ),
                  IconButton(
                    icon: Icon(
                      Platform.isIOS
                          ? CupertinoIcons.settings
                          : Icons.settings_outlined,
                      color: AppColors.carbonBlack,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Profile Header (Centered)
              _buildCenteredProfile(user, isDe),

              const SizedBox(height: 32),

              // BMI & Quick Stats
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      isDe ? 'DEIN BMI' : 'YOUR BMI',
                      user.bmi.toStringAsFixed(1),
                      AppColors.shamrock,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      isDe ? 'STATUS' : 'STATUS',
                      isDe
                          ? _getGermanCategory(user.bmiCategory)
                          : user.bmiCategory,
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
                    isDe ? 'Heute' : 'Today',
                    style: AppTypography.displayMedium.copyWith(fontSize: 22),
                  ),
                  const Icon(
                    Icons.flash_on,
                    color: AppColors.shamrock,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTodayStatsGrid(todayStats, isDe),

              const SizedBox(height: 40),

              // Reminders Section
              _buildRemindersSection(provider, isDe),

              const SizedBox(height: 40),

              // Weight Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDe ? 'Gewichtsverlauf' : 'Weight Progress',
                    style: AppTypography.displayMedium.copyWith(fontSize: 22),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddWeightScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.shamrock,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.carbonBlack,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeightChart(weights, isDe),

              const SizedBox(height: 24),

              // Precise Weight List
              _buildWeightList(weights, isDe),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredProfile(UserModel user, bool isDe) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.shamrock,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shamrock.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              user.name.isNotEmpty ? user.name[0] : '?',
              style: const TextStyle(
                fontSize: 40,
                color: AppColors
                    .carbonBlack, // Changed from white for better UI context
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
          '${user.age} ${isDe ? 'Jahre' : 'years'} • ${user.height.toInt()} cm',
          style: AppTypography.bodyMedium.copyWith(
            fontSize: 14,
            color: AppColors.carbonBlack.withValues(alpha: 0.5),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.celadon, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              fontSize: 11,
              letterSpacing: 1.2,
              color: AppColors.carbonBlack.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displayMedium.copyWith(
              fontSize: 22, // Slightly smaller to prevent overflow
              color: color,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStatsGrid(Map<String, double> stats, bool isDe) {
    final calories = stats['calories']?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.shamrock,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Text(
            '$calories',
            style: AppTypography.displayLarge.copyWith(
              color: AppColors.carbonBlack, // Contrast
              fontSize: 52,
            ),
          ),
          Text(
            isDe ? 'KALORIEN AUFGENOMMEN' : 'CALORIES CONSUMED',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.carbonBlack.withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMacro(
                isDe ? 'Eiw.' : 'Prot',
                '${stats['protein']?.toInt() ?? 0}g',
              ),
              _buildMiniMacro(
                isDe ? 'KH' : 'Carb',
                '${stats['carbs']?.toInt() ?? 0}g',
              ),
              _buildMiniMacro(
                isDe ? 'Fett' : 'Fat',
                '${stats['fats']?.toInt() ?? 0}g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMacro(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.carbonBlack,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: AppColors.carbonBlack.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRemindersSection(AppProvider provider, bool isDe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isDe ? 'Erinnerungen' : 'Reminders',
          style: AppTypography.displayMedium.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.celadon),
          ),
          child: Column(
            children: [
              _buildReminderToggle(
                isDe ? 'Mahlzeiten loggen' : 'Log meals',
                isDe ? 'Morgens, Mittags, Abends' : 'Morning, Lunch, Dinner',
                provider.mealRemindersEnabled,
                (val) => provider.setMealReminders(val),
              ),
              const Divider(height: 32, color: AppColors.celadon),
              _buildReminderToggle(
                isDe ? 'Gewicht loggen' : 'Log weight',
                isDe ? 'Tägliche Erinnerung' : 'Daily reminder',
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
                  color: AppColors.carbonBlack.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: AppColors.shamrock,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildWeightChart(List<WeightModel> weights, bool isDe) {
    if (weights.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.celadon),
        ),
        child: Center(
          child: Text(
            isDe ? 'Keine Daten verfügbar' : 'No data available',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.carbonBlack.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.celadon.withValues(alpha: 0.3),
              strokeWidth: 1,
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
                  return const SizedBox.shrink(); // Simplify for now
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5, // Improved precision
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: AppColors.carbonBlack.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: weights
                  .take(7)
                  .toList()
                  .reversed
                  .toList()
                  .asMap()
                  .entries
                  .map((e) {
                    return FlSpot(e.key.toDouble(), e.value.weight);
                  })
                  .toList(),
              isCurved: true,
              color: AppColors.shamrock,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: AppColors.shamrock,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.shamrock.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightList(List<WeightModel> weights, bool isDe) {
    if (weights.isEmpty) return const SizedBox.shrink();

    final recentWeights = weights.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            isDe ? 'Verlauf der letzten Tage' : 'Recent History',
            style: AppTypography.titleLarge.copyWith(
              fontSize: 14,
              color: AppColors.carbonBlack.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.celadon),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentWeights.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: AppColors.celadon,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final w = recentWeights[index];
              final dateStr =
                  '${w.date.day.toString().padLeft(2, '0')}.${w.date.month.toString().padLeft(2, '0')}.${w.date.year}';

              return Padding(
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
                      '${w.weight.toStringAsFixed(1)} kg',
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 18,
                        color: AppColors.shamrock,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getGermanCategory(String category) {
    switch (category.toLowerCase()) {
      case 'underweight':
        return 'Untergewicht';
      case 'normal':
        return 'Normalgewicht';
      case 'overweight':
        return 'Übergewicht';
      case 'obese':
        return 'Adipositas';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'normal':
        return AppColors.shamrock;
      case 'underweight':
        return Colors.blue;
      default:
        return AppColors.error;
    }
  }
}
