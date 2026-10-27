import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';
import '../utils/insights.dart';
import '../widgets/common/adaptive.dart';
import '../widgets/common/mono_digits.dart';
import '../widgets/common/segmented_tabs.dart';
import '../widgets/me/weight_chart.dart';
import '../widgets/me/weight_list.dart';
import 'add_weight_screen.dart';
import 'onboarding/onboarding_flow.dart';
import 'settings_screen.dart';

enum _Period { week, month, year }

/// How the weeks, months and years add up, and the body behind them:
/// weight, BMI and the burn the logged meals point to.
class ProgressScreen extends StatefulWidget {
  /// Opens a day on the Today tab.
  final ValueChanged<DateTime>? onOpenDay;

  /// Fires when the tab is tapped while shown: back to the top, then back
  /// to the current period.
  final Listenable? reselected;

  const ProgressScreen({super.key, this.onOpenDay, this.reselected});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _Bucket {
  final DateTime start;
  final String label;
  final double kcal;
  final double protein;
  final int days;
  final bool current;
  final bool openable;

  const _Bucket({
    required this.start,
    required this.label,
    required this.kcal,
    required this.protein,
    required this.days,
    required this.current,
    required this.openable,
  });

  double get average => days == 0 ? 0 : kcal / days;
}

class _ProgressScreenState extends State<ProgressScreen>
    with AutomaticKeepAliveClientMixin {
  // Kept while other tabs are shown: building it from scratch on every visit
  // was a visible hitch.
  @override
  bool get wantKeepAlive => true;

  _Period _period = _Period.week;

  /// How many periods back from the current one.
  int _back = 0;

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.reselected?.addListener(_onReselected);
  }

  @override
  void dispose() {
    widget.reselected?.removeListener(_onReselected);
    _scroll.dispose();
    super.dispose();
  }

  void _onReselected() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else if (_back != 0) {
      Haptics.selection();
      setState(() => _back = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final l10n = context.l10n;

    if (user == null) {
      return Center(
        child: FilledButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingFlow()),
          ),
          child: Text(l10n.startOnboarding),
        ),
      );
    }

    // Newest first, as the database returns them.
    final weights = provider.weights;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => provider.syncService.syncFromCloud(),
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.settings, color: AppColors.text),
                      tooltip: l10n.settings,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(l10n.tabProgress, style: AppTypography.title),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: MonoDigits(
                  _streakLine(context, user, provider.streakData),
                  style: AppTypography.secondary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: SegmentedTabs(
                  labels: [l10n.week, l10n.month, l10n.year],
                  semanticContext: l10n.calories,
                  selected: _period.index,
                  onChanged: (i) => setState(() {
                    _period = _Period.values[i];
                    _back = 0;
                  }),
                ),
              ),
              _PeriodSummary(
                buckets: _buckets(provider, user),
                range: _rangeLabel(provider.language, user),
                period: _period,
                target: user.dailyCalorieTarget.toDouble(),
                proteinTarget: user.dailyProteinTarget.toDouble(),
                canGoForward: _back > 0,
                onBack: () {
                  Haptics.selection();
                  setState(() => _back++);
                },
                onForward: () {
                  Haptics.selection();
                  setState(() => _back = math.max(0, _back - 1));
                },
                onOpenDay: widget.onOpenDay,
              ),
              _SectionTitle(l10n.weight),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: WeightChart(weights: weights),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Haptics.tick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddWeightScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadius,
                        ),
                      ),
                      textStyle: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.logWeight),
                  ),
                ),
              ),
              if (weights.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: WeightList(
                    weights: weights,
                    onEdit: (weight) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddWeightScreen(initialWeight: weight),
                      ),
                    ),
                    onDelete: _confirmDeleteWeight,
                  ),
                ),
              _SectionTitle(l10n.bodyTitle),
              _BodyRows(user: user, provider: provider),
            ],
          ),
        ),
      ),
    );
  }

  String _streakLine(BuildContext context, UserModel user, StreakData data) {
    final l10n = context.l10n;
    final parts = <String>[
      if (user.name.isNotEmpty) user.name,
      if (data.streak > 0) l10n.streakLine(data.streak),
    ];
    return parts.isEmpty ? l10n.streakNone : parts.join('  ·  ');
  }

  DateTime _logicalToday(UserModel user) {
    final now = DateTime.now().subtract(Duration(hours: user.dayStartHour));
    return DateTime(now.year, now.month, now.day);
  }

  (DateTime, DateTime) _range(UserModel user) {
    final today = _logicalToday(user);
    switch (_period) {
      case _Period.week:
        // The last seven days, today included.
        final end = DateTime(
          today.year,
          today.month,
          today.day + 1 - 7 * _back,
        );
        return (DateTime(end.year, end.month, end.day - 7), end);
      case _Period.month:
        final start = DateTime(today.year, today.month - _back, 1);
        return (start, DateTime(start.year, start.month + 1, 1));
      case _Period.year:
        final start = DateTime(today.year - _back, 1, 1);
        return (start, DateTime(start.year + 1, 1, 1));
    }
  }

  String _rangeLabel(String language, UserModel user) {
    final (start, end) = _range(user);
    switch (_period) {
      case _Period.week:
        final last = end.subtract(const Duration(days: 1));
        if (start.month != last.month) {
          return '${DateFormat.MMMd(language).format(start)} – ${DateFormat.MMMd(language).format(last)}';
        }
        // "13 – 19 October" reads as "13. – 19. Oktober" and "October 13 – 19".
        return language == 'de'
            ? '${DateFormat.d(language).format(start)} – ${DateFormat.MMMMd(language).format(last)}'
            : '${DateFormat.MMMMd(language).format(start)} – ${DateFormat.d(language).format(last)}';
      case _Period.month:
        return DateFormat.yMMMM(language).format(start);
      case _Period.year:
        return DateFormat.y(language).format(start);
    }
  }

  List<_Bucket> _buckets(AppProvider provider, UserModel user) {
    final (start, end) = _range(user);
    final offset = user.dayStartHour;
    final today = _logicalToday(user);
    final language = provider.language;
    final meals = provider
        .getMealsByDateRange(
          DateTime(start.year, start.month, start.day, offset),
          DateTime(end.year, end.month, end.day, offset),
        )
        .where((m) => !m.isPending);

    // Logged kcal and protein per logical day.
    final kcal = <DateTime, double>{};
    final protein = <DateTime, double>{};
    for (final m in meals) {
      final t = m.timestamp.subtract(Duration(hours: offset));
      final day = DateTime(t.year, t.month, t.day);
      kcal[day] = (kcal[day] ?? 0) + m.calories;
      protein[day] = (protein[day] ?? 0) + m.protein;
    }

    if (_period == _Period.year) {
      return [
        for (var month = 1; month <= 12; month++)
          () {
            final first = DateTime(start.year, month, 1);
            final days = kcal.keys.where(
              (d) => d.year == start.year && d.month == month,
            );
            return _Bucket(
              start: first,
              label: DateFormat.MMM(language).format(first).substring(0, 1),
              kcal: days.fold(0.0, (s, d) => s + kcal[d]!),
              protein: days.fold(0.0, (s, d) => s + protein[d]!),
              days: days.length,
              current: first.year == today.year && first.month == today.month,
              openable: false,
            );
          }(),
      ];
    }

    final weekday = DateFormat.E(language);
    final out = <_Bucket>[];
    for (
      var d = start;
      d.isBefore(end);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final logged = kcal.containsKey(d);
      out.add(
        _Bucket(
          start: d,
          label: _period == _Period.week
              ? weekday.format(d).replaceAll('.', '').substring(0, 2)
              : (d.day == 1 || d.day % 7 == 0 ? '${d.day}' : ''),
          kcal: kcal[d] ?? 0,
          protein: protein[d] ?? 0,
          days: logged ? 1 : 0,
          current: d == today,
          openable: !d.isAfter(today),
        ),
      );
    }
    return out;
  }

  Future<void> _confirmDeleteWeight(WeightModel weight) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteWeight,
      message: l10n.deleteWeightConfirm,
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (confirmed && mounted) {
      await context.read<AppProvider>().deleteWeight(weight.date);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 40, 20, 12),
    child: Text(text, style: AppTypography.heading),
  );
}

class _PeriodSummary extends StatelessWidget {
  final List<_Bucket> buckets;
  final String range;
  final _Period period;
  final double target;
  final double proteinTarget;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final ValueChanged<DateTime>? onOpenDay;

  const _PeriodSummary({
    required this.buckets,
    required this.range,
    required this.period,
    required this.target,
    required this.proteinTarget,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onOpenDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = buckets.fold<int>(0, (s, b) => s + b.days);
    final kcal = buckets.fold<double>(0, (s, b) => s + b.kcal);
    final protein = buckets.fold<double>(0, (s, b) => s + b.protein);
    final average = days == 0 ? null : kcal / days;
    final proteinAverage = days == 0 ? 0.0 : protein / days;
    final totalDays = period == _Period.year
        ? buckets.fold<int>(
            0,
            (s, b) => s + DateUtils.getDaysInMonth(b.start.year, b.start.month),
          )
        : buckets.length;

    String difference() {
      final diff = average! - target;
      if (diff.abs() < 25) return l10n.weeklyOnTarget;
      final value = diff.abs().round().toString();
      return diff > 0
          ? l10n.weeklyAboveTarget(value)
          : l10n.weeklyBelowTarget(value);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: MonoDigits(
                  range,
                  maxLines: 1,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onBack,
                tooltip: l10n.previousPeriod,
                icon: Icon(Icons.chevron_left, color: AppColors.text),
              ),
              IconButton(
                onPressed: canGoForward ? onForward : null,
                tooltip: l10n.nextPeriod,
                icon: Icon(
                  Icons.chevron_right,
                  color: canGoForward ? AppColors.text : AppColors.border,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(l10n.averagePerDay, style: AppTypography.secondary),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      (average ?? 0).round().toString(),
                      style: AppTypography.hero(size: 56),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.kcal,
                      style: AppTypography.body.copyWith(color: AppColors.ink2),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                MonoDigits(
                  average == null
                      ? l10n.periodNoMeals
                      : '${difference()} · ${l10n.weeklyDaysLogged(days, totalDays)}',
                  style: AppTypography.secondary,
                ),
                if (average != null && proteinTarget > 0)
                  MonoDigits(
                    l10n.proteinAveragePerDay(
                      proteinAverage.round(),
                      proteinTarget.round(),
                    ),
                    style: AppTypography.secondary,
                  ),
                const SizedBox(height: 20),
                _Bars(
                  buckets: buckets,
                  target: target,
                  useAverage: period == _Period.year,
                  onOpen: onOpenDay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One bar per day (or per month, as its daily average), with the target as
/// a dashed line. The current one is in the accent.
class _Bars extends StatelessWidget {
  final List<_Bucket> buckets;
  final double target;
  final bool useAverage;
  final ValueChanged<DateTime>? onOpen;

  const _Bars({
    required this.buckets,
    required this.target,
    required this.useAverage,
    required this.onOpen,
  });

  static const _height = 120.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    double value(_Bucket b) => useAverage ? b.average : b.kcal;
    final highest = buckets.map(value).fold<double>(0, math.max);
    final scale = math.max(highest, target) * 1.08;
    final dense = buckets.length > 12;
    final gap = dense ? 2.0 : 8.0;

    return Semantics(
      label: buckets
          .where((b) => b.days > 0)
          .map((b) => '${b.label}: ${value(b).round()} ${l10n.kcal}')
          .join(', '),
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: _height,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _height * target / scale,
                    child: CustomPaint(
                      size: const Size(double.infinity, 1.2),
                      painter: _DashPainter(AppColors.ink3),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final b in buckets)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: b.openable && onOpen != null
                                ? () {
                                    Haptics.tick();
                                    onOpen!(b.start);
                                  }
                                : null,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: gap / 2,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: b.days == 0
                                      ? 3
                                      : (_height * value(b) / scale).clamp(
                                          3.0,
                                          _height,
                                        ),
                                  decoration: BoxDecoration(
                                    color: b.current
                                        ? AppColors.primary
                                        : b.days == 0
                                        ? AppColors.border
                                        : AppColors.text.withValues(
                                            alpha: 0.16,
                                          ),
                                    borderRadius: BorderRadius.circular(
                                      dense ? 2 : 4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final b in buckets)
                  Expanded(
                    child: Text(
                      b.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: AppTypography.meta.copyWith(
                        fontSize: 11,
                        color: b.current ? AppColors.text : AppColors.ink3,
                        fontWeight: b.current ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;

  _DashPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + 4, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// BMI and the estimated burn, as plain rows.
class _BodyRows extends StatelessWidget {
  final UserModel user;
  final AppProvider provider;

  const _BodyRows({required this.user, required this.provider});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = switch (user.bmiCategory) {
      'underweight' => l10n.bmiUnderweight,
      'normal' => l10n.bmiNormal,
      'overweight' => l10n.bmiOverweight,
      _ => l10n.bmiObese,
    };
    final burn = provider.expenditureEstimate();
    final burnKcal = burn.kcal;
    final ready = burn.status == ExpenditureStatus.ready && burnKcal != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _Row(
            title: l10n.bmi,
            value: '${user.bmi.toStringAsFixed(1)} · $category',
            detail: l10n.healthyRange(
              user.minHealthyWeight.toStringAsFixed(1),
              user.maxHealthyWeight.toStringAsFixed(1),
            ),
          ),
          _Row(
            title: l10n.burnTitle,
            value: ready ? l10n.burnPerDay(burnKcal.round()) : null,
            detail: ready
                ? '${l10n.burnBasis(burn.loggedDays, burn.weighIns)} ${l10n.burnFormula(user.maintenanceCalories.round().toString())}'
                : burn.status == ExpenditureStatus.implausible
                ? l10n.burnImplausible
                : l10n.burnNeedsData(burn.loggedDays, burn.weighIns),
            last: true,
          ),
          if (ready)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.burnDisclaimer, style: AppTypography.meta),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String title;
  final String? value;
  final String detail;
  final bool last;

  const _Row({
    required this.title,
    required this.value,
    required this.detail,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: last ? BorderSide(color: AppColors.border) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (value != null)
                Flexible(
                  child: MonoDigits(
                    value!,
                    textAlign: TextAlign.end,
                    style: AppTypography.body,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          MonoDigits(detail, style: AppTypography.secondary),
        ],
      ),
    );
  }
}
