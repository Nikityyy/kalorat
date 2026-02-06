import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../widgets/common/app_card.dart';
import '../widgets/widgets.dart';
import 'meal_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedPeriod = 0; // 0=Day, 1=Week, 2=Month, 3=Year

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = context.l10n;

    List<MealModel> filteredMeals = [];
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 0: // Day
        filteredMeals = provider.getMealsByDate(now);
        break;
      case 1: // Week
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeek = DateTime(start.year, start.month, start.day);
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        filteredMeals = provider.getMealsByDateRange(startOfWeek, endOfWeek);
        break;
      case 2: // Month
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        filteredMeals = provider.getMealsByDateRange(start, end);
        break;
      case 3: // Year
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year + 1, 1, 1);
        filteredMeals = provider.getMealsByDateRange(start, end);
        break;
    }

    // Sort by newest first
    filteredMeals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final periods = [l10n.day, l10n.week, l10n.month, l10n.year];

    return Scaffold(
      backgroundColor: AppColors.limestone,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                l10n.myHistory,
                style: AppTypography.displayMedium.copyWith(fontSize: 24),
              ),
            ),

            // Custom Period Switcher
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.limestone,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppColors.pebble, width: 1),
              ),
              child: Row(
                children: List.generate(periods.length, (index) {
                  final isSelected = _selectedPeriod == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.transparent,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                        child: Text(
                          periods[index],
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected
                                ? AppColors.pebble
                                : AppColors.slate,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            _buildPeriodStats(provider, context),
            const Divider(color: AppColors.pebble),
            Expanded(
              child: filteredMeals.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noMealsRecorded,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredMeals.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: MealCard(
                          meal: filteredMeals[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MealDetailScreen(
                                meal: filteredMeals[i],
                                isNewEntry: false,
                              ),
                            ),
                          ),
                          onDelete: () => _confirmDelete(
                            context,
                            filteredMeals[i],
                            provider,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodStats(AppProvider provider, BuildContext context) {
    final l10n = context.l10n;
    Map<String, double> stats;
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 1:
        stats = provider.getWeekStats();
        break;
      case 2:
        stats = provider.getMonthStats();
        break;
      case 3:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year + 1, 1, 1);
        stats = provider.getStatsForDateRange(start, end);
        break;
      default:
        stats = provider.getTodayStats();
    }

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.pebble,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${stats['calories']?.toInt() ?? 0}',
                style: AppTypography.heroNumber.copyWith(
                  fontSize: 24,
                  color: AppColors.slate,
                ),
              ),
              Text(
                l10n.kcal,
                style: TextStyle(color: AppColors.slate.withValues(alpha: 0.6)),
              ),
            ],
          ),
          Container(width: 1, height: 40, color: AppColors.slate),
          Column(
            children: [
              Text(
                '${stats['protein']?.toInt() ?? 0}${l10n.grams}',
                style: AppTypography.heroNumber.copyWith(
                  fontSize: 18,
                  color: AppColors.styrianForest,
                ),
              ),
              Text(
                l10n.protein,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '${stats['carbs']?.toInt() ?? 0}${l10n.grams}',
                style: AppTypography.heroNumber.copyWith(
                  fontSize: 18,
                  color: AppColors.styrianForest,
                ),
              ),
              Text(
                l10n.carbs,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '${stats['fats']?.toInt() ?? 0}${l10n.grams}',
                style: AppTypography.heroNumber.copyWith(
                  fontSize: 18,
                  color: AppColors.styrianForest,
                ),
              ),
              Text(
                l10n.fats,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    MealModel meal,
    AppProvider provider,
  ) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteQuestion),
        content: Text(l10n.deleteMealConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMeal(meal.id);
              Navigator.pop(ctx);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
