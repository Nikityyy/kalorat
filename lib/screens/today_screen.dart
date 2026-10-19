import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../extensions/l10n_extension.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/hints/first_use_hints.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import '../utils/haptics.dart';
import '../widgets/common/adaptive.dart';
import '../widgets/app_toast.dart';
import '../widgets/common/mono_digits.dart';
import '../widgets/common/thin_bar.dart';
import '../widgets/first_use_card.dart';
import '../widgets/inputs/pressable.dart';
import '../widgets/today/day_ridge.dart';
import '../widgets/today/meal_row.dart';
import 'meal_detail_screen.dart';
import 'settings_screen.dart';

/// One day: what is left, the day's climb, and the plates that made it.
/// Opens on today; the arrows and the date step through earlier days.
class TodayScreen extends StatefulWidget {
  /// True while this tab is on screen. A meal saved while it was away
  /// climbs onto the ridge when it comes back.
  final ValueListenable<bool>? activeListenable;

  /// Set by another tab to show a day here.
  final ValueNotifier<DateTime?>? dayRequest;

  /// Fires when the tab is tapped while shown: back to the top, then back
  /// to today.
  final Listenable? reselected;
  final VoidCallback? onOpenCamera;

  const TodayScreen({
    super.key,
    this.activeListenable,
    this.dayRequest,
    this.reselected,
    this.onOpenCamera,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Kept while other tabs are shown, so it knows which meals are new.
  @override
  bool get wantKeepAlive => true;

  /// The logical day shown, at midnight. Null means today, which follows
  /// the clock.
  DateTime? _day;
  bool _backupHintDismissed = false;

  // A deleted meal goes at once and Undo is offered; it really goes when
  // the toast does. Until then it is only hidden here.
  final Map<String, Timer> _deleting = {};
  final _scroll = ScrollController();

  late final AnimationController _climb;
  Set<String> _fresh = const {};
  Set<String>? _seen;

  @override
  void initState() {
    super.initState();
    _climb = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      value: 1,
    );
    widget.activeListenable?.addListener(_onActiveChanged);
    widget.dayRequest?.addListener(_onDayRequest);
    widget.reselected?.addListener(_onReselected);
  }

  void _onReselected() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    } else if (_day != null) {
      Haptics.selection();
      setState(() => _day = null);
    }
  }

  @override
  void dispose() {
    widget.activeListenable?.removeListener(_onActiveChanged);
    widget.dayRequest?.removeListener(_onDayRequest);
    widget.reselected?.removeListener(_onReselected);
    _scroll.dispose();
    _climb.dispose();
    for (final entry in _deleting.entries) {
      entry.value.cancel();
      _provider?.deleteMeal(entry.key);
    }
    super.dispose();
  }

  bool get _active => widget.activeListenable?.value ?? true;

  void _onActiveChanged() {
    if (_active) _climbNewMeals();
  }

  void _onDayRequest() {
    final day = widget.dayRequest?.value;
    if (day == null) return;
    widget.dayRequest!.value = null;
    setState(() => _day = _isToday(day) ? null : day);
  }

  int get _offset => context.read<AppProvider>().user?.dayStartHour ?? 0;

  DateTime _logicalToday() {
    final now = DateTime.now().subtract(Duration(hours: _offset));
    return DateTime(now.year, now.month, now.day);
  }

  bool _isToday(DateTime day) => day == _logicalToday();

  DateTime get _shownDay => _day ?? _logicalToday();

  List<MealModel> _mealsOf(AppProvider provider, DateTime day) {
    final start = DateTime(day.year, day.month, day.day, _offset);
    return provider.getMealsByDateRange(
      start,
      start.add(const Duration(days: 1)),
    )..sort(compareMealsNewestFirst);
  }

  /// Plays the climb for today's meals that were not on the ridge the last
  /// time it was seen.
  void _climbNewMeals() {
    if (!mounted || _day != null) return;
    final provider = context.read<AppProvider>();
    final ids = {
      for (final m in _mealsOf(provider, _logicalToday()))
        if (!m.isPending) m.id,
    };
    final seen = _seen;
    _seen = ids;
    if (seen == null) return;
    final fresh = ids.difference(seen);
    if (fresh.isEmpty) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    setState(() => _fresh = fresh);
    _climb.duration = Duration(milliseconds: reduce ? 150 : 420);
    _climb.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _fresh = const {});
    });
    // The pin lands about halfway through.
    Future.delayed(Duration(milliseconds: reduce ? 0 : 220), Haptics.tick);
  }

  void _step(int days) {
    Haptics.selection();
    final next = _shownDay.add(Duration(days: days));
    if (next.isAfter(_logicalToday())) return;
    setState(() => _day = _isToday(next) ? null : next);
  }

  Future<void> _pickDay(String language) async {
    final picked = await pickDate(
      context,
      initial: _shownDay,
      first: DateTime(2020),
      last: _logicalToday(),
    );
    if (picked != null && mounted) {
      setState(() => _day = _isToday(picked) ? null : picked);
    }
  }

  Future<void> _open(MealModel meal) async {
    await Navigator.push<MealModel>(
      context,
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(meal: meal, isNewEntry: false),
      ),
    );
  }

  AppProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<AppProvider>();
  }

  Future<void> _delete(MealModel meal) async {
    final provider = context.read<AppProvider>();
    Haptics.tick();
    const window = Duration(seconds: 5);
    setState(() {
      _deleting[meal.id] = Timer(window, () {
        _deleting.remove(meal.id);
        provider.deleteMeal(meal.id);
      });
    });
    AppToast.show(
      context,
      context.l10n.mealDeleted,
      actionLabel: context.l10n.quickLogUndo,
      duration: window,
      onAction: () {
        _deleting.remove(meal.id)?.cancel();
        if (mounted) setState(() {});
      },
    );
  }

  /// Hold a meal for its actions, in a menu where the finger is.
  Widget _withActions(MealModel meal, Widget row) {
    if (meal.isPending) return row;
    final l10n = context.l10n;
    return GestureDetector(
      onLongPressStart: (d) async {
        Haptics.tick();
        final p = d.globalPosition;
        final choice = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(p.dx, p.dy, p.dx, p.dy),
          items: [
            PopupMenuItem(
              value: 'again',
              child: ListTile(
                leading: const Icon(Icons.replay),
                title: Text(l10n.quickLogAgainAction),
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.edit),
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.negative),
                title: Text(
                  l10n.delete,
                  style: TextStyle(color: AppColors.negative),
                ),
              ),
            ),
          ],
        );
        if (!mounted) return;
        switch (choice) {
          case 'again':
            _eatAgain(meal);
          case 'edit':
            _open(meal);
          case 'delete':
            _delete(meal);
        }
      },
      child: row,
    );
  }

  Future<void> _eatAgain(MealModel source) async {
    Haptics.tick();
    final provider = context.read<AppProvider>();
    final l10n = context.l10n;
    final copy = await provider.repeatMeal(source);
    if (!mounted) return;
    _climbNewMeals();
    AppToast.show(
      context,
      l10n.quickLogLogged(copy.mealName),
      actionLabel: l10n.quickLogUndo,
      onAction: () => provider.deleteMeal(copy.id),
    );
  }

  bool _showBackupHint(AppProvider provider) {
    final user = provider.user;
    return user != null &&
        !_backupHintDismissed &&
        user.isGuest &&
        !FirstUseHints.seen(FirstUseHint.backup) &&
        provider.hasMeals;
  }

  void _dismissBackupHint() {
    setState(() => _backupHintDismissed = true);
    FirstUseHints.markSeen(FirstUseHint.backup);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = context.watch<AppProvider>();
    final user = provider.user;
    final l10n = context.l10n;
    final language = provider.language;
    final day = _shownDay;
    final isToday = _day == null;
    final meals = _mealsOf(
      provider,
      day,
    ).where((m) => !_deleting.containsKey(m.id)).toList();
    final logged = meals.where((m) => !m.isPending).toList();
    final syncPending = provider.mealIdsPendingSync();

    // A meal saved while this tab is on screen climbs right away.
    if (isToday && _active) {
      final ids = {for (final m in logged) m.id};
      if (_seen != null &&
          !setEquals(ids, _seen) &&
          ids.length > _seen!.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _climbNewMeals());
      } else {
        _seen ??= ids;
      }
    }

    final target = user?.dailyCalorieTarget.toDouble() ?? 2000;
    final proteinTarget = user?.dailyProteinTarget.toDouble() ?? 0;
    final now = DateTime.now();
    final dayStart = DateTime(day.year, day.month, day.day, _offset);
    double hoursOf(DateTime t) => t.difference(dayStart).inMinutes / 60;
    final steps = [
      for (final m in logged)
        RidgeStep(
          id: m.id,
          hour: hoursOf(m.timestamp).clamp(0, 24),
          kcal: m.calories,
          photoPath: m.photoPaths.isNotEmpty ? m.photoPaths.first : null,
          name: m.mealName,
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await provider.syncService.syncFromCloud();
            await provider.processOfflineQueue();
          },
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  label: _dayLabel(context, day, isToday, language),
                  canGoForward: !isToday,
                  onPick: () => _pickDay(language),
                  onBack: () => _step(-1),
                  onForward: () => _step(1),
                ),
              ),
              if (provider.isProcessingQueue)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.processingQueue,
                            style: AppTypography.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _climb,
                  builder: (context, _) {
                    // While a meal climbs, the numbers count with its step.
                    final rise = Curves.easeOutCubic.transform(
                      (_climb.value / 0.52).clamp(0, 1),
                    );
                    double eaten = 0, protein = 0;
                    for (final m in logged) {
                      final share = _fresh.contains(m.id) ? rise : 1.0;
                      eaten += m.calories * share;
                      protein += m.protein * share;
                    }
                    return _Hero(
                      isToday: isToday,
                      eaten: eaten,
                      target: target,
                      protein: protein,
                      proteinTarget: proteinTarget,
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: DayRidge(
                    steps: steps,
                    target: target,
                    endHour: isToday ? hoursOf(now).clamp(0, 24) : 24,
                    dayStartHour: _offset,
                    fresh: _fresh,
                    progress: _climb,
                    onPinTap: (id) {
                      final meal = logged.where((m) => m.id == id);
                      if (meal.isNotEmpty) _open(meal.first);
                    },
                  ),
                ),
              ),
              if (logged.isNotEmpty)
                SliverToBoxAdapter(
                  child: _MacroLine(meals: logged, user: user),
                ),
              if (meals.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyDay(
                    isToday: isToday,
                    recent: isToday
                        ? provider.recentDistinctMeals(limit: 4)
                        : const [],
                    onOpenCamera: widget.onOpenCamera,
                    onEatAgain: _eatAgain,
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
                    child: Text(
                      l10n.mealsCount(meals.length),
                      style: AppTypography.secondary.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: meals.length,
                    itemBuilder: (context, i) {
                      final meal = meals[i];
                      final failed =
                          meal.isPending && meal.analysisStatus == 'failed';
                      return Dismissible(
                        key: ValueKey('meal-${meal.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(meal),
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsetsDirectional.only(end: 20),
                          decoration: BoxDecoration(
                            color: AppColors.negative,
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadius,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                l10n.delete,
                                style: AppTypography.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: _withActions(
                          meal,
                          MealRow(
                            meal: meal,
                            showDivider: i < meals.length - 1,
                            syncPending: syncPending.contains(meal.id),
                            analysisWorkerActive:
                                provider.isProcessingQueue &&
                                meal.analysisStatus == 'running',
                            onTap: meal.isPending
                                ? (failed
                                      ? () =>
                                            provider.retryMealAnalysis(meal.id)
                                      : null)
                                : () => _open(meal),
                            onRetry: failed
                                ? () => provider.retryMealAnalysis(meal.id)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (_showBackupHint(provider))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: FirstUseCard(
                      icon: Icons.cloud_upload_outlined,
                      title: l10n.hintBackupTitle,
                      body: l10n.hintBackupBody,
                      dismissLabel: l10n.hintNotNow,
                      onDismiss: _dismissBackupHint,
                      actionLabel: l10n.hintBackupAction,
                      onAction: () async {
                        _dismissBackupHint();
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // Room for the floating tab bar.
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  String _dayLabel(
    BuildContext context,
    DateTime day,
    bool isToday,
    String language,
  ) {
    final l10n = context.l10n;
    final date = DateFormat.MMMMd(language).format(day);
    if (isToday) return l10n.todayWithDate(date);
    if (day == _logicalToday().subtract(const Duration(days: 1))) {
      return l10n.yesterdayWithDate(date);
    }
    return DateFormat.MMMMEEEEd(language).format(day);
  }
}

class _Header extends StatelessWidget {
  final String label;
  final bool canGoForward;
  final VoidCallback onPick;
  final VoidCallback onBack;
  final VoidCallback onForward;

  const _Header({
    required this.label,
    required this.canGoForward,
    required this.onPick,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              hint: l10n.pickDay,
              child: Pressable(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPick,
                  child: SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Flexible(
                          child: MonoDigits(
                            label,
                            maxLines: 1,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: AppColors.ink3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onBack,
            tooltip: l10n.previousDay,
            icon: Icon(Icons.chevron_left, color: AppColors.text),
          ),
          IconButton(
            onPressed: canGoForward ? onForward : null,
            tooltip: l10n.nextDay,
            icon: Icon(
              Icons.chevron_right,
              color: canGoForward ? AppColors.text : AppColors.border,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final bool isToday;
  final double eaten;
  final double target;
  final double protein;
  final double proteinTarget;

  const _Hero({
    required this.isToday,
    required this.eaten,
    required this.target,
    required this.protein,
    required this.proteinTarget,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final left = target - eaten;
    final targetText = target.round().toString();

    final String big;
    final String sub;
    if (!isToday) {
      big = eaten.round().toString();
      sub = l10n.kcalOfTarget(targetText);
    } else if (left >= 0) {
      big = left.round().toString();
      sub = eaten == 0 ? l10n.kcalToEatToday : l10n.kcalLeftOf(targetText);
    } else {
      big = (-left).round().toString();
      sub = l10n.kcalOverTarget(targetText);
    }

    final proteinLeft = (proteinTarget - protein).round();
    final Widget proteinLine;
    if (proteinTarget <= 0) {
      proteinLine = const SizedBox.shrink();
    } else if (!isToday) {
      proteinLine = MonoDigits(
        l10n.proteinOfTarget(protein.round(), proteinTarget.round()),
        style: AppTypography.body.copyWith(color: AppColors.ink2),
      );
    } else if (proteinLeft <= 0) {
      proteinLine = Text(
        l10n.proteinReached,
        style: AppTypography.body.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      proteinLine = MonoDigits(
        l10n.proteinToGo(proteinLeft),
        style: AppTypography.body.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Semantics(
      container: true,
      label: '$big $sub',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(big, style: AppTypography.hero(size: 88)),
              ),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: MonoDigits(
                sub,
                style: AppTypography.body.copyWith(color: AppColors.ink2),
              ),
            ),
            const SizedBox(height: 2),
            proteinLine,
          ],
        ),
      ),
    );
  }
}

/// The day's three macros against their targets, in ink: the accent is kept
/// for the day's progress.
class _MacroLine extends StatelessWidget {
  final List<MealModel> meals;
  final UserModel? user;

  const _MacroLine({required this.meals, required this.user});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    double p = 0, c = 0, f = 0;
    for (final m in meals) {
      p += m.protein;
      c += m.carbs;
      f += m.fats;
    }
    final u = user;
    // Carbs and fat have a ceiling; protein is a floor to reach, never over.
    Widget cell(
      String label,
      double value,
      num? target, {
      bool ceiling = true,
    }) {
      final share = target == null || target <= 0
          ? 0.0
          : (value / target).clamp(0.0, 1.0);
      // Going over a ceiling is the one place the day turns red.
      final over =
          ceiling &&
          target != null &&
          target > 0 &&
          value.round() > target.round();
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.meta.copyWith(color: AppColors.ink2),
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value.round().toString(),
                    style: AppTypography.number(
                      size: 16,
                      color: over ? AppColors.negative : null,
                    ),
                  ),
                  if (target != null)
                    TextSpan(
                      text: '/${target.round()}',
                      style: AppTypography.number(
                        size: 16,
                        color: AppColors.ink3,
                      ),
                    ),
                  TextSpan(text: ' ${l10n.grams}', style: AppTypography.meta),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ThinBar(share: share, color: over ? AppColors.negative : null),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          cell(l10n.protein, p, u?.dailyProteinTarget, ceiling: false),
          const SizedBox(width: 16),
          cell(l10n.carbs, c, u?.dailyCarbTarget),
          const SizedBox(width: 16),
          cell(l10n.fats, f, u?.dailyFatTarget),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final bool isToday;
  final List<MealModel> recent;
  final VoidCallback? onOpenCamera;
  final ValueChanged<MealModel> onEatAgain;

  const _EmptyDay({
    required this.isToday,
    required this.recent,
    required this.onOpenCamera,
    required this.onEatAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!isToday) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
        child: Text(l10n.pastDayEmpty, style: AppTypography.secondary),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.todayEmptyBody,
            style: AppTypography.body.copyWith(color: AppColors.ink2),
          ),
          if (onOpenCamera != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: () {
                  Haptics.tick();
                  onOpenCamera!();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  textStyle: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.photo_camera),
                label: Text(l10n.openCamera),
              ),
            ),
          ],
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              l10n.quickLogRecent,
              style: AppTypography.secondary.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < recent.length; i++)
              _EatAgainRow(
                meal: recent[i],
                showDivider: i < recent.length - 1,
                onTap: () => onEatAgain(recent[i]),
              ),
          ],
        ],
      ),
    );
  }
}

class _EatAgainRow extends StatelessWidget {
  final MealModel meal;
  final bool showDivider;
  final VoidCallback onTap;

  const _EatAgainRow({
    required this.meal,
    required this.showDivider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: '${l10n.quickLogAgainAction}: ${meal.mealName}',
      excludeSemantics: true,
      child: Pressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: showDivider
                  ? Border(bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              children: [
                MealPhoto(meal: meal, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.mealName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      MonoDigits(
                        '${meal.calories.round()} ${l10n.kcal}',
                        style: AppTypography.secondary,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
