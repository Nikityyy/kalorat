import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/platform_utils.dart';
import 'welcome_step.dart';
import 'name_step.dart';
import 'goal_step.dart';
import 'demographics_step.dart';
import 'loading_teaser_step.dart';
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
      final savedStep = provider.databaseService.getOnboardingStep();
      if (savedStep > 0 && savedStep < _totalSteps) {
        setState(() => _currentPage = savedStep);
        _pageController.jumpToPage(savedStep);
      }
    });
  }

  int get _totalSteps => PlatformUtils.isWeb ? 11 : 13;

  int get _lastStepIndex => _totalSteps - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    final nextStep = _currentPage + 1;
    context.read<AppProvider>().databaseService.saveOnboardingStep(nextStep);

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    
    int prevIndex = _currentPage - 1;
    final steps = _buildOnboardingSteps();
    
    if (prevIndex >= 0 && steps[prevIndex] is LoadingTeaserStep) {
      prevIndex--; // Skip the loading step when going backward
    }
    
    if (prevIndex >= 0) {
      _pageController.animateToPage(
        prevIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<Widget> _buildOnboardingSteps() {
    final steps = <Widget>[
      // Step 0
      WelcomeStep(
        language: _language,
        onLanguageChanged: (lang) {
          setState(() => _language = lang);
          context.read<AppProvider>().updateLanguage(lang);
        },
        onNext: _nextPage,
      ),
      // Step 1
      NameStep(
        language: _language,
        initialValue: _name,
        onNext: (name) {
          setState(() => _name = name);
          context.read<AppProvider>().updateUser(name: name);
          _nextPage();
        },
      ),
      // Step 2
      GoalStep(
        language: _language,
        initialIndex: _goalIndex,
        onNext: (index) {
          setState(() => _goalIndex = index);
          context.read<AppProvider>().updateUser(goal: index);
          _nextPage();
        },
      ),
      // Step 3
      DemographicsStep(
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
      ),
      // Step 4
      MetricsStep(
        language: _language,
        initialHeight: _height,
        initialWeight: _weight,
        onNext: (height, weight) {
          setState(() {
            _height = height;
            _weight = weight;
          });
          context.read<AppProvider>().updateUser(height: height, weight: weight);
          _nextPage();
        },
      ),
      // Step 5
      ActivityLevelStep(
        initialLevel: _activityLevel,
        onNext: (level) {
          setState(() => _activityLevel = level);
          context.read<AppProvider>().updateUser(activityLevel: level);
          _nextPage();
        },
      ),
      // Step 6
      LoadingTeaserStep(
        onNext: _nextPage,
      ),
      // Step 7: The "Aha!" Teaser
      TeaserAnalysisStep(
        age: _age,
        genderIndex: _genderIndex,
        height: _height,
        weight: _weight,
        activityLevelIndex: _activityLevel,
        goalIndex: _goalIndex,
        onNext: _nextPage,
      ),
      // Step 8: Login
      LoginStep(
        language: _language,
        onNext: _nextPage,
        onLoginSuccess: () {
          final user = context.read<AppProvider>().user;
          if (user != null) {
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
                  (now.month == user.birthdate.month &&
                      now.day < user.birthdate.day)) {
                _age--;
              }
            });
          }
        },
      ),
    ];

    if (!PlatformUtils.isWeb) {
      steps.add(
        HealthStep(
          language: _language,
          onNext: (connected) {
            setState(() => _healthSyncEnabled = connected);
            context.read<AppProvider>().updateUser(
              healthSyncEnabled: connected,
            );
            _nextPage();
          },
        ),
      );
      steps.add(
        NotificationStep(
          language: _language,
          onNext: (enabled) {
            context.read<AppProvider>().updateUser(
              mealRemindersEnabled: enabled,
              weightRemindersEnabled: enabled,
            );
            _nextPage();
          },
        ),
      );
    }

    steps.addAll([
      ApiKeyStep(
        language: _language,
        initialValue: _apiKey,
        onNext: (key) {
          setState(() => _apiKey = key);
          context.read<AppProvider>().updateUser(apiKey: key);
          _nextPage();
        },
      ),
      AnalysisStep(
        language: _language,
        name: _name,
        genderIndex: _genderIndex,
        birthdate: _birthdate,
        height: _height,
        weight: _weight,
        goalIndex: _goalIndex,
        apiKey: _apiKey,
        healthSyncEnabled: _healthSyncEnabled,
      ),
    ]);

    return steps;
  }

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
                  if (_currentPage > 0 && _currentPage < _lastStepIndex)
                    GestureDetector(
                      onTap: _previousPage,
                      child: const Icon(
                        Icons.arrow_back,
                        color: AppColors.slate,
                      ),
                    )
                  else
                    const SizedBox(width: 24),

                  if (_currentPage > 0 && _currentPage < _lastStepIndex)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          tween: Tween<double>(
                            begin: 0,
                            end: _currentPage / _lastStepIndex,
                          ),
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
