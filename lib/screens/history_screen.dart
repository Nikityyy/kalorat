import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = context.l10n;

    List<MealModel> filteredMeals = [];
    final now = DateTime.now();

    DateTime start = now;
    DateTime end = now;

    switch (_selectedPeriod) {
      case 0: // Day
        start = _selectedDate;
        end = _selectedDate;
        filteredMeals = provider.getMealsByDate(_selectedDate);
        break;
      case 1: // Week
        // Start of week (Monday)
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 7));
        filteredMeals = provider.getMealsByDateRange(start, end);
        break;
      case 2: // Month
        start = DateTime(now.year, now.month, 1);
        // Start of next month
        if (now.month == 12) {
          end = DateTime(now.year + 1, 1, 1);
        } else {
          end = DateTime(now.year, now.month + 1, 1);
        }
        filteredMeals = provider.getMealsByDateRange(start, end);
        break;
      case 3: // Year
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1);
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.myHistory,
                    style: AppTypography.displayMedium.copyWith(fontSize: 24),
                  ),
                  Visibility(
                    visible: _selectedPeriod == 0,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton.icon(
                      onPressed: () => _showDatePicker(provider.language),
                      icon: const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        DateFormat.yMMMd(
                          provider.language,
                        ).format(_selectedDate),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        backgroundColor: AppColors.pebble,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Custom Period Switcher
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                      onTap: () {
                        setState(() {
                          _selectedPeriod = index;
                          // Reset selected date to today when switching periods,
                          // EXCEPT when switching TO Day view, keep the selected date?
                          // Or always reset? Let's keep selected date as is.
                        });
                      },
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

            _buildPeriodStats(provider, context, start, end),

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
                          onTap: filteredMeals[i].isPending
                              ? null
                              : () => Navigator.push(
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

  Widget _buildPeriodStats(
    AppProvider provider,
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    final l10n = context.l10n;
    Map<String, double> stats;
    int daysElapsed = 1;

    if (_selectedPeriod == 0) {
      stats = provider.getTodayStats(); // Actually needs specific date stats
      // Correcting to use stats for the selected date
      final meals = provider.getMealsByDate(_selectedDate);
      double cals = 0, prot = 0, carbs = 0, fats = 0;
      for (var m in meals) {
        if (!m.isPending) {
          cals += m.calories;
          prot += m.protein;
          carbs += m.carbs;
          fats += m.fats;
        }
      }
      stats = {'calories': cals, 'protein': prot, 'carbs': carbs, 'fats': fats};
    } else {
      stats = provider.getStatsForDateRange(start, end);

      // Calculate days elapsed in period for averaging
      final now = DateTime.now();
      final periodEnd = end.isBefore(now) ? end : now;
      final periodStart = start;

      if (periodEnd.isAfter(periodStart)) {
        daysElapsed = periodEnd.difference(periodStart).inDays;
        if (daysElapsed == 0 && periodEnd.day == periodStart.day) {
          daysElapsed = 1;
        }
        // Cap at 1 to avoid division by zero, though logic above prevents it mostly
        if (daysElapsed < 1) {
          daysElapsed = 1;
        }
      }
    }

    final isDailyPeriod = _selectedPeriod == 0;

    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.pebble,
      child: Column(
        children: [
          _buildStatRow(stats, l10n),
          if (!isDailyPeriod) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(
                height: 1,
                color: AppColors.slate,
                indent: 20,
                endIndent: 20,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.dailyAvg.toUpperCase(),
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.slate.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatRow(stats, l10n, divisor: daysElapsed),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(
    Map<String, double> stats,
    dynamic l10n, {
    int divisor = 1,
  }) {
    // Helper to divide and format
    String fmt(double? val) => ((val ?? 0) / divisor).toStringAsFixed(0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text(
              fmt(stats['calories']),
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
        Container(
          width: 1,
          height: 40,
          color: AppColors.slate.withValues(alpha: 0.2),
        ),
        Column(
          children: [
            Text(
              '${fmt(stats['protein'])}${l10n.grams}',
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
              '${fmt(stats['carbs'])}${l10n.grams}',
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
              '${fmt(stats['fats'])}${l10n.grams}',
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

  Future<void> _showDatePicker(String language) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: language == 'de' ? const Locale('de') : const Locale('en'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.pebble,
              surface: AppColors.limestone,
              onSurface: AppColors.slate,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedPeriod = 0; // Force Day view when date is picked
      });
    }
  }
}
