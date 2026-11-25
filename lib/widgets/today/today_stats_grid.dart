import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../extensions/l10n_extension.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';
import '../common/mono_digits.dart';
import '../common/thin_bar.dart';

/// Compact streak badge paired with the last seven days' activity dots.
class StreakStrip extends StatelessWidget {
  final StreakData data;
  final String language;
  final int dayStartHour;

  const StreakStrip({
    super.key,
    required this.data,
    required this.language,
    this.dayStartHour = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final logicalNow = DateTime.now().subtract(Duration(hours: dayStartHour));
    final today = DateTime(logicalNow.year, logicalNow.month, logicalNow.day);
    final weekday = DateFormat.E(language);
    final presence = data.last7DaysPresence;
    final hasStreak = data.streak > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: hasStreak ? AppColors.primary : AppColors.ink3,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: MonoDigits(
                    hasStreak ? l10n.streakBadge(data.streak) : l10n.streakZeroShort,
                    maxLines: 1,
                    style: AppTypography.secondary.copyWith(
                      fontSize: 13,
                      fontWeight: hasStreak ? FontWeight.w600 : FontWeight.w400,
                      color: hasStreak ? AppColors.text : AppColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: hasStreak ? l10n.streakLine(data.streak) : l10n.streakNone,
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 7; i++)
                  _DayDot(
                    label: weekday.format(today.subtract(Duration(days: 6 - i))),
                    logged: i < presence.length && presence[i],
                    isToday: i == 6,
                    spacing: i == 0 ? 0 : 6,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final String label;
  final bool logged;
  final bool isToday;
  final double spacing;

  const _DayDot({
    required this.label,
    required this.logged,
    required this.isToday,
    required this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final cleaned = label.replaceAll('.', '').trim();
    final letter = cleaned.isEmpty ? '' : cleaned[0].toUpperCase();
    return Padding(
      padding: EdgeInsets.only(left: spacing),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            letter,
            style: AppTypography.meta.copyWith(
              fontSize: 9,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? AppColors.text : AppColors.ink3,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: logged ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: logged
                    ? AppColors.primary
                    : isToday
                    ? AppColors.ink2
                    : AppColors.border,
                width: isToday && !logged ? 1.5 : 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2x2 momentum grid showing daily calories and protein in filled Styrian Forest
/// hero tiles, with carbs and fat below on neutral hairline cards.
class TodayStatsGrid extends StatelessWidget {
  final double eaten;
  final double calorieTarget;
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbTarget;
  final double fats;
  final double fatTarget;
  final bool isToday;

  const TodayStatsGrid({
    super.key,
    required this.eaten,
    required this.calorieTarget,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbTarget,
    required this.fats,
    required this.fatTarget,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kcalDiff = (calorieTarget - eaten).round();
    final kcalPct = calorieTarget > 0 ? (eaten / calorieTarget * 100).round() : 0;
    final kcalSubtitle = !isToday
        ? l10n.percentOfGoal(kcalPct)
        : kcalDiff >= 0
        ? l10n.kcalLeftSimple(kcalDiff)
        : l10n.kcalOverSimple(-kcalDiff);

    final proteinSubtitle = proteinTarget <= 0
        ? ''
        : protein.round() >= proteinTarget.round()
        ? l10n.proteinReachedShort
        : l10n.gramsToGo((proteinTarget - protein).round());

    String ceilingSubtitle(double val, double target, bool over) {
      if (target <= 0) return '';
      return over
          ? l10n.gramsOver((val - target).round())
          : l10n.gramsLeft((target - val).round());
    }

    final carbsOver = carbTarget > 0 && carbs.round() > carbTarget.round();
    final fatsOver = fatTarget > 0 && fats.round() > fatTarget.round();
    final carbsSubtitle = ceilingSubtitle(carbs, carbTarget, carbsOver);
    final fatsSubtitle = ceilingSubtitle(fats, fatTarget, fatsOver);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.calories,
                  icon: Icons.local_fire_department_outlined,
                  value: eaten,
                  target: calorieTarget,
                  unit: l10n.kcal,
                  subtitle: kcalSubtitle,
                  hero: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: l10n.protein,
                  icon: Icons.fitness_center_outlined,
                  value: protein,
                  target: proteinTarget,
                  unit: l10n.grams,
                  subtitle: proteinSubtitle,
                  hero: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: l10n.carbs,
                  icon: Icons.bakery_dining_outlined,
                  value: carbs,
                  target: carbTarget,
                  unit: l10n.grams,
                  subtitle: carbsSubtitle,
                  overCeiling: carbsOver,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: l10n.fats,
                  icon: Icons.opacity_outlined,
                  value: fats,
                  target: fatTarget,
                  unit: l10n.grams,
                  subtitle: fatsSubtitle,
                  overCeiling: fatsOver,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double target;
  final String unit;
  final String subtitle;
  final bool hero;
  final bool overCeiling;

  const _MetricTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.target,
    required this.unit,
    required this.subtitle,
    this.hero = false,
    this.overCeiling = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final hasTarget = target > 0;
    final share = hasTarget ? (value / target).clamp(0.0, 1.0) : 0.0;
    final pct = hasTarget ? (value / target * 100).round() : 0;

    final Color bg;
    final Color? borderColor;
    final Color labelColor;
    final Color valueColor;
    final Color targetColor;
    final Color barColor;
    final Color trackColor;

    if (hero) {
      // Deep Styrian Forest fill keeps crisp white contrast in both light and dark modes.
      bg = dark ? const Color(0xFF104930) : AppColors.styrianForestColor;
      borderColor = dark
          ? AppColors.styrianForestLight.withValues(alpha: 0.35)
          : null;
      labelColor = Colors.white.withValues(alpha: 0.78);
      valueColor = AppColors.pureWhite;
      targetColor = Colors.white.withValues(alpha: 0.72);
      barColor = dark ? AppColors.styrianForestLight : AppColors.pureWhite;
      trackColor = Colors.white.withValues(alpha: dark ? 0.16 : 0.22);
    } else {
      bg = AppColors.surface;
      borderColor = AppColors.border;
      labelColor = AppColors.ink2;
      valueColor = overCeiling ? AppColors.negative : AppColors.text;
      targetColor = AppColors.ink3;
      barColor = overCeiling ? AppColors.negative : AppColors.primary;
      trackColor = AppColors.border;
    }

    final valText = value.round().toString();
    final tgtText = target.round().toString();

    return Semantics(
      container: true,
      label: hasTarget
          ? '$label: $valText / $tgtText $unit. $subtitle'
          : '$label: $valText $unit',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: borderColor == null
                ? null
                : Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: labelColor),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.outfit,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: labelColor,
                      ),
                    ),
                  ),
                  if (hasTarget) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$pct%',
                      style: AppTypography.number(
                        size: 12,
                        weight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: valText,
                        style: AppTypography.number(
                          size: 23,
                          weight: FontWeight.w700,
                          color: valueColor,
                        ),
                      ),
                      TextSpan(
                        text: hasTarget ? ' / $tgtText $unit' : ' $unit',
                        style: AppTypography.number(
                          size: 13,
                          weight: FontWeight.w500,
                          color: targetColor,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 8),
              ThinBar(
                share: share,
                height: 4,
                color: barColor,
                trackColor: trackColor,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 5),
                MonoDigits(
                  subtitle,
                  maxLines: 1,
                  style: AppTypography.meta.copyWith(
                    fontSize: 11,
                    color: overCeiling && !hero
                        ? AppColors.negative
                        : labelColor,
                    fontWeight: overCeiling && !hero
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
