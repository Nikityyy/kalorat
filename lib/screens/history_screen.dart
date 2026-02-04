import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/common/app_card.dart';
import '../widgets/widgets.dart';

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
    final isDe = provider.language == 'de';
    final meals = provider.getAllMeals();

    final periods = isDe
        ? ['Tag', 'Woche', 'Monat', 'Jahr']
        : ['Day', 'Week', 'Month', 'Year'];

    return Scaffold(
      backgroundColor: AppColors.lavenderBlush,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                isDe ? 'Meine Historie' : 'My History',
                style: AppTypography.displayMedium.copyWith(fontSize: 24),
              ),
            ),

            // Custom Period Switcher
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.celadon),
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
                              ? AppColors.shamrock
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          periods[index],
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.carbonBlack,
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
            _buildPeriodStats(provider, isDe),
            const Divider(color: AppColors.celadon),
            Expanded(
              child: meals.isEmpty
                  ? Center(
                      child: Text(
                        isDe
                            ? 'Noch keine Mahlzeiten erfasst'
                            : 'No meals recorded yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: meals.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: MealCard(
                          meal: meals[i],
                          language: isDe ? 'de' : 'en',
                          onDelete: () =>
                              _confirmDelete(context, meals[i], provider, isDe),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodStats(AppProvider provider, bool isDe) {
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
      backgroundColor: AppColors.celadon,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '${stats['calories']?.toInt() ?? 0}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.carbonBlack,
                ),
              ),
              Text(
                'kcal',
                style: TextStyle(
                  color: AppColors.carbonBlack.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Column(
            children: [
              Text(
                '${stats['protein']?.toInt() ?? 0}g',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                ),
              ),
              Text(
                isDe ? 'Eiweiß' : 'Protein',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.carbonBlack.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '${stats['carbs']?.toInt() ?? 0}g',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5A623),
                ),
              ),
              Text(
                isDe ? 'Kohlenhydrate' : 'Carbs',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.carbonBlack.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                '${stats['fats']?.toInt() ?? 0}g',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD0021B),
                ),
              ),
              Text(
                isDe ? 'Fett' : 'Fat',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.carbonBlack.withValues(alpha: 0.6),
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
    bool isDe,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDe ? 'Löschen?' : 'Delete?'),
        content: Text(
          isDe
              ? 'Möchtest du diese Mahlzeit wirklich löschen?'
              : 'Do you really want to delete this meal?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isDe ? 'Abbrechen' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMeal(meal.id);
              Navigator.pop(ctx);
            },
            child: Text(
              isDe ? 'Löschen' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
