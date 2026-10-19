import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../extensions/l10n_extension.dart';
import '../../theme/app_colors.dart';
import '../../utils/platform_utils.dart';
import 'welcome_step.dart';
import 'about_step.dart';
import 'demographics_step.dart';
import 'metrics_step.dart';
import 'activity_level_step.dart';
import 'teaser_analysis_step.dart';
import 'health_step.dart';
import 'api_key_step.dart';
import 'login_step.dart';
import 'notification_step.dart';
import 'analysis_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

/// The pages, in order. [signIn] is not part of the way through: it is only
/// reached from the welcome page, by someone who already has an account.
enum _Step {
  welcome,
  signIn,
  about,
  demographics,
  metrics,
  activity,
  target,
  health,
  notifications,
  apiKey,
  finish,
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late String _language;
  String _name = '';

  int _genderIndex = 0; // 0: Male, 1: Female, 2: Other
  DateTime _birthdate = DateTime(2000, 1, 1);
  int _age = 25;
  double _height = 170.0;
  double _weight = 70.0;
  int _goalIndex = 1; // 0: Lose, 1: Maintain, 2: Gain
  int _activityLevel = 0;
  String _apiKey = '';
  bool _healthSyncEnabled = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _language = provider.language;

    // Restore state from persisted user data
    final user = provider.user;
    if (user != null) {
      _name = user.name;
      _birthdate = user.birthdate;
      final now = DateTime.now();
      _age = now.year - user.birthdate.year;
      if (now.month < user.birthdate.month ||
          (now.month == user.birthdate.month && now.day < user.birthdate.day)) {
        _age--;
      }
      _height = user.height;
      _weight = user.weight;
      _goalIndex = user.goalIndex;
      _genderIndex = user.genderIndex ?? 0;
      _activityLevel = user.activityLevelIndex;
      _apiKey = provider.apiKey;
      _healthSyncEnabled = user.healthSyncEnabled;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedStep = provider.databaseService.getOnboardingStep(
        isWeb: PlatformUtils.isWeb,
      );
      if (savedStep > 0 && savedStep < _totalSteps) {
        setState(() => _currentPage = savedStep);
        _pageController.jumpToPage(savedStep);
      }
    });
  }

  /// Health and notifications are asked for on phones only.
  List<_Step> get _steps => [
    for (final step in _Step.values)
      if (!PlatformUtils.isWeb ||
          (step != _Step.health && step != _Step.notifications))
        step,
  ];

  int get _totalSteps => _steps.length;

  int _indexOf(_Step step) => _steps.indexOf(step);

  _Step get _currentStep => _steps[_currentPage];

  /// The steps the progress bar counts: the way through, without the sign-in.
  List<_Step> get _progressSteps =>
      _steps.where((s) => s != _Step.signIn).toList();

  /// Back and progress show on the questions, not on the welcome page, the
  /// sign-in alone or the final saving page.
  bool get _showsProgress =>
      _currentStep != _Step.welcome && _currentStep != _Step.finish;

  double get _progress {
    final path = _progressSteps;
    final position = path.indexOf(_currentStep);
    return position <= 0 ? 0 : position / (path.length - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(_Step step, {Duration? duration}) {
    FocusScope.of(context).unfocus();
    final index = _indexOf(step);
    context.read<AppProvider>().databaseService.saveOnboardingStep(index);
    // Pages that are not neighbours are jumped to: sliding there would sweep
    // across the sign-in page in between.
    if ((index - _currentPage).abs() > 1) {
      _pageController.jumpToPage(index);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: duration ?? const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  /// The next page on the way through, skipping the sign-in.
  void _nextPage() {
    final path = _progressSteps;
    final next = path.indexOf(_currentStep) + 1;
    if (next < path.length) _goTo(path[next]);
  }

  void _previousPage() {
    if (_currentStep == _Step.signIn) {
      _goTo(_Step.welcome, duration: const Duration(milliseconds: 300));
      return;
    }
    final path = _progressSteps;
    final previous = path.indexOf(_currentStep) - 1;
    if (previous >= 0) {
      _goTo(path[previous], duration: const Duration(milliseconds: 300));
    }
  }

  void _restoreFrom(UserModel user) {
    setState(() {
      _name = user.name;
      _birthdate = user.birthdate;
      _height = user.height;
      _weight = user.weight;
      _goalIndex = user.goalIndex;
      _genderIndex = user.genderIndex ?? 0;
      _activityLevel = user.activityLevelIndex;
      _healthSyncEnabled = user.healthSyncEnabled;

      final now = DateTime.now();
      _age = now.year - user.birthdate.year;
      if (now.month < user.birthdate.month ||
          (now.month == user.birthdate.month && now.day < user.birthdate.day)) {
        _age--;
      }
    });
  }

  Widget _buildStep(_Step step) {
    switch (step) {
      case _Step.welcome:
        return WelcomeStep(
          language: _language,
          onLanguageChanged: (lang) {
            setState(() => _language = lang);
            context.read<AppProvider>().updateLanguage(lang);
          },
          onNext: _nextPage,
          onSignIn: () => _goTo(_Step.signIn),
        );
      case _Step.signIn:
        // For someone with an account: the profile comes from the cloud, so
        // the questions are skipped and only the API key is still needed.
        return LoginStep(
          language: _language,
          onNext: () => _goTo(_Step.apiKey),
          onSetupInstead: () => _goTo(_Step.about),
          onLoginSuccess: () {
            final user = context.read<AppProvider>().user;
            if (user != null) _restoreFrom(user);
          },
        );
      case _Step.about:
        return AboutStep(
          initialName: _name,
          initialGoalIndex: _goalIndex,
          onNext: (name, goalIndex) {
            setState(() {
              _name = name;
              _goalIndex = goalIndex;
            });
            context.read<AppProvider>().updateUser(name: name, goal: goalIndex);
            _nextPage();
          },
        );
      case _Step.demographics:
        return DemographicsStep(
          language: _language,
          initialAge: _age,
          initialGenderIndex: _genderIndex,
          onNext: (age, genderIndex) {
            setState(() {
              _age = age;
              _genderIndex = genderIndex;
              final now = DateTime.now();
              _birthdate = DateTime(now.year - age, now.month, now.day);
            });
            context.read<AppProvider>().updateUser(
              birthdate: _birthdate,
              gender: genderIndex,
            );
            _nextPage();
          },
        );
      case _Step.metrics:
        return MetricsStep(
          language: _language,
          initialHeight: _height,
          initialWeight: _weight,
          onNext: (height, weight) {
            setState(() {
              _height = height;
              _weight = weight;
            });
            context.read<AppProvider>().updateUser(
              height: height,
              weight: weight,
            );
            _nextPage();
          },
        );
      case _Step.activity:
        return ActivityLevelStep(
          initialLevel: _activityLevel,
          onNext: (level) {
            setState(() => _activityLevel = level);
            context.read<AppProvider>().updateUser(activityLevel: level);
            _nextPage();
          },
        );
      case _Step.target:
        return TeaserAnalysisStep(
          age: _age,
          genderIndex: _genderIndex,
          height: _height,
          weight: _weight,
          activityLevelIndex: _activityLevel,
          goalIndex: _goalIndex,
          onNext: _nextPage,
        );
      case _Step.health:
        return HealthStep(
          language: _language,
          onNext: (connected) {
            setState(() => _healthSyncEnabled = connected);
            context.read<AppProvider>().updateUser(
              healthSyncEnabled: connected,
            );
            _nextPage();
          },
        );
      case _Step.notifications:
        return NotificationStep(
          language: _language,
          onNext: (enabled) {
            context.read<AppProvider>().updateUser(
              mealRemindersEnabled: enabled,
              weightRemindersEnabled: enabled,
            );
            _nextPage();
          },
        );
      case _Step.apiKey:
        return ApiKeyStep(
          language: _language,
          initialValue: _apiKey,
          onNext: (key) {
            setState(() => _apiKey = key);
            context.read<AppProvider>().updateUser(apiKey: key);
            _nextPage();
          },
        );
      case _Step.finish:
        return AnalysisStep(
          language: _language,
          name: _name,
          genderIndex: _genderIndex,
          birthdate: _birthdate,
          height: _height,
          weight: _weight,
          goalIndex: _goalIndex,
          apiKey: _apiKey,
          healthSyncEnabled: _healthSyncEnabled,
        );
    }
  }

  List<Widget> _buildOnboardingSteps() => [
    for (final step in _steps) _buildStep(step),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.limestone,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (_showsProgress)
                    Semantics(
                      button: true,
                      label: context.l10n.back,
                      child: GestureDetector(
                        onTap: _previousPage,
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.slate,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 24),

                  if (_showsProgress)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          tween: Tween<double>(begin: 0, end: _progress),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                backgroundColor: AppColors.pebble.withValues(
                                  alpha: 0.3,
                                ),
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                                minHeight: 6,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity! > 200) {
                    if (_currentPage > 0) {
                      _previousPage();
                    }
                  }
                },
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: _buildOnboardingSteps(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
