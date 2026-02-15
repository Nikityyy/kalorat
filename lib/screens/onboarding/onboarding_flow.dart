import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/platform_utils.dart';
import 'welcome_step.dart';
import 'name_step.dart';
import 'gender_step.dart';
import 'age_step.dart';
import 'height_step.dart';
import 'weight_step.dart';
import 'goal_step.dart';
import 'activity_level_step.dart';
import 'health_step.dart';
import 'api_key_step.dart';
import 'login_step.dart';
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
  int _age = 25;
  double _height = 170.0;
  double _weight = 70.0; // Double for precision
  int _goalIndex = 1; // 0: Lose, 1: Maintain, 2: Gain
  int _activityLevel = 0; // 0: Sedentary ... 4: Very Active
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
      // Calculate age from birthdate
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

    // Restore current step
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedStep = provider.databaseService.getOnboardingStep();
      if (savedStep > 0 && savedStep < _totalSteps) {
        setState(() => _currentPage = savedStep);
        _pageController.jumpToPage(savedStep);
      }
    });
  }

  // Total steps depends on platform: 11 on mobile (with health step), 10 on web (without)
  int get _totalSteps => PlatformUtils.isWeb ? 11 : 12;

  // The last step index (analysis) for hiding back button and progress
  int get _lastStepIndex => _totalSteps - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    FocusScope.of(context).unfocus();
    final nextStep = _currentPage + 1;
    // Save progress
    context.read<AppProvider>().databaseService.saveOnboardingStep(nextStep);

    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Widget> _buildOnboardingSteps() {
    final steps = <Widget>[
      WelcomeStep(
        language: _language,
        onLanguageChanged: (lang) {
          setState(() => _language = lang);
          context.read<AppProvider>().updateLanguage(lang);
        },
        onNext: _nextPage,
      ),
      NameStep(
        language: _language,
        onNext: (name) {
          setState(() => _name = name);
          context.read<AppProvider>().updateUser(name: name);
          _nextPage();
        },
      ),
      GenderStep(
        language: _language,
        initialIndex: _genderIndex,
        onNext: (index) {
          setState(() => _genderIndex = index);
          context.read<AppProvider>().updateUser(gender: index);
          _nextPage();
        },
      ),
      AgeStep(
        language: _language,
        initialValue: _age,
        onNext: (value) {
          setState(() => _age = value);
          // Approximate birthdate from age
          final now = DateTime.now();
          final birthdate = DateTime(now.year - value, now.month, now.day);
          context.read<AppProvider>().updateUser(birthdate: birthdate);
          _nextPage();
        },
      ),
      HeightStep(
        language: _language,
        initialValue: _height,
        onNext: (value) {
          setState(() => _height = value);
          context.read<AppProvider>().updateUser(height: value);
          _nextPage();
        },
      ),
      WeightStep(
        language: _language,
        initialValue: _weight,
        onNext: (value) {
          setState(() => _weight = value);
          context.read<AppProvider>().updateUser(weight: value);
          _nextPage();
        },
      ),
      GoalStep(
        language: _language,
        initialIndex: _goalIndex,
        onNext: (index) {
          setState(() => _goalIndex = index);
          context.read<AppProvider>().updateUser(goal: index);
          _nextPage();
        },
      ),
      ActivityLevelStep(
        initialLevel: _activityLevel,
        onNext: (level) {
          setState(() => _activityLevel = level);
          context.read<AppProvider>().updateUser(activityLevel: level);
          _nextPage();
        },
      ),
    ];

    // Only add HealthStep on mobile platforms
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
    }

    steps.addAll([
      ApiKeyStep(
        language: _language,
        onNext: (key) {
          setState(() => _apiKey = key);
          context.read<AppProvider>().updateUser(apiKey: key);
          _nextPage();
        },
      ),
      LoginStep(language: _language, onNext: _nextPage),
      AnalysisStep(
        language: _language,
        name: _name,
        genderIndex: _genderIndex,
        age: _age,
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
      backgroundColor:
          AppColors.limestone, // Or white if pursuing "Cal AI" stricter look
      body: SafeArea(
        child: Column(
          children: [
            // Header (Back + Progress)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Hide back button on welcome (0) and analysis (last step)
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

                  if (_currentPage > 0 &&
                      _currentPage <
                          _lastStepIndex) // Hide on welcome and analysis
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
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: _buildOnboardingSteps(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
