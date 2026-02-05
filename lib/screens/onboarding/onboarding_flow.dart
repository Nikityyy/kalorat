import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'welcome_step.dart';
import 'name_step.dart';
import 'gender_step.dart';
import 'age_step.dart';
import 'height_step.dart';
import 'weight_step.dart';
import 'goal_step.dart';
import 'api_key_step.dart';
import 'analysis_step.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data State
  String _language = 'de'; // Default to German
  String _name = '';
  int _genderIndex = 0; // 0: Male, 1: Female, 2: Other
  int _age = 25;
  double _height = 170.0;
  double _weight = 70.0; // Double for precision
  int _goalIndex = 1; // 0: Lose, 1: Maintain, 2: Gain
  String _apiKey = '';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
                  if (_currentPage > 0)
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
                      _currentPage < 8) // Hide on welcome and analysis
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          tween: Tween<double>(begin: 0, end: _currentPage / 8),
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
                children: [
                  WelcomeStep(
                    language: _language,
                    onLanguageChanged: (lang) =>
                        setState(() => _language = lang),
                    onNext: _nextPage,
                  ),
                  NameStep(
                    language: _language,
                    onNext: (name) {
                      setState(() => _name = name);
                      _nextPage();
                    },
                  ),
                  GenderStep(
                    language: _language,
                    initialIndex: _genderIndex,
                    onNext: (index) {
                      setState(() => _genderIndex = index);
                      _nextPage();
                    },
                  ),
                  AgeStep(
                    language: _language,
                    initialValue: _age,
                    onNext: (value) {
                      setState(() => _age = value);
                      _nextPage();
                    },
                  ),
                  HeightStep(
                    language: _language,
                    initialValue: _height,
                    onNext: (value) {
                      setState(() => _height = value);
                      _nextPage();
                    },
                  ),
                  WeightStep(
                    language: _language,
                    initialValue: _weight,
                    onNext: (value) {
                      setState(() => _weight = value);
                      _nextPage();
                    },
                  ),
                  GoalStep(
                    language: _language,
                    initialIndex: _goalIndex,
                    onNext: (index) {
                      setState(() => _goalIndex = index);
                      _nextPage();
                    },
                  ),
                  ApiKeyStep(
                    language: _language,
                    onNext: (key) {
                      setState(() => _apiKey = key);
                      _nextPage();
                    },
                  ),
                  AnalysisStep(
                    language: _language,
                    name: _name,
                    genderIndex: _genderIndex,
                    age: _age,
                    height: _height,
                    weight: _weight,
                    goalIndex: _goalIndex,
                    apiKey: _apiKey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
