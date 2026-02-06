// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kalorat';

  @override
  String get welcome => 'Welcome to Kalorat';

  @override
  String get welcomeSubtitle => 'Your companion for the climb.';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get onboardingName => 'What\'s your name?';

  @override
  String get onboardingNameHint => 'Your name';

  @override
  String get onboardingBirthdate => 'When were you born?';

  @override
  String get onboardingHeight => 'How tall are you?';

  @override
  String get onboardingHeightHint => 'Height in cm';

  @override
  String get onboardingWeight => 'How much do you weigh?';

  @override
  String get onboardingWeightHint => 'Weight in kg';

  @override
  String get onboardingLanguage => 'Select language';

  @override
  String get onboardingApiKey => 'Enter Gemini API key';

  @override
  String get onboardingApiKeyHint => 'API key';

  @override
  String get onboardingApiKeyInfo =>
      'Enter your API key from ai.dev. Go to https://ai.dev → Account → Create API Key → paste here.';

  @override
  String get home => 'Home';

  @override
  String get me => 'Me';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get age => 'Age';

  @override
  String get years => 'years';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get bmi => 'BMI';

  @override
  String get bmiUnderweight => 'Underweight';

  @override
  String get bmiNormal => 'Normal weight';

  @override
  String get bmiOverweight => 'Overweight';

  @override
  String get bmiObese => 'Obese';

  @override
  String get takePhoto => 'Capture';

  @override
  String get addMorePhotos => 'Add more photos';

  @override
  String get analyzeMeal => 'Check Provisions';

  @override
  String get analyzing => 'Checking...';

  @override
  String get mealName => 'Meal';

  @override
  String get calories => 'Energy';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbohydrates';

  @override
  String get fats => 'Fat';

  @override
  String get vitamins => 'Vitamins';

  @override
  String get minerals => 'Minerals';

  @override
  String get manualEntry => 'Manual entry';

  @override
  String get offlineMessage =>
      'You are offline. The AI will analyze your meal once you are back online and open the app.';

  @override
  String get pendingAnalysis => 'Pending analyses';

  @override
  String get processingQueue => 'Processing pending meals...';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get thisYear => 'This year';

  @override
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get total => 'Total';

  @override
  String get weightTracking => 'Weight tracking';

  @override
  String get addWeight => 'Add weight';

  @override
  String get weightHistory => 'Weight history';

  @override
  String get noWeightData => 'The path starts here.';

  @override
  String get statistics => 'Statistics';

  @override
  String get noMealData => 'No meals recorded yet';

  @override
  String get mealsLogged => 'meals logged';

  @override
  String get language => 'Language';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'English';

  @override
  String get apiKey => 'API key';

  @override
  String get apiKeyInfo => 'Enter or change your API key from ai.dev.';

  @override
  String get exportData => 'Export data';

  @override
  String get importData => 'Import data';

  @override
  String get exportSuccess => 'Data exported successfully';

  @override
  String get importSuccess => 'Data imported successfully';

  @override
  String get importError => 'Error importing data';

  @override
  String get notifications => 'Notifications';

  @override
  String get mealReminders => 'Meal reminders';

  @override
  String get weightReminders => 'Weight reminders';

  @override
  String get confirmDelete => 'Confirm delete?';

  @override
  String get confirmDeleteMeal => 'Do you really want to delete this meal?';

  @override
  String get cameraPermission => 'Camera permission required';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get name => 'Name';

  @override
  String get heightCm => 'Height (cm)';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get birthdate => 'Birthdate';

  @override
  String ageYears(int age) {
    return '$age years';
  }

  @override
  String get saveChanges => 'Save changes';

  @override
  String get saved => 'Saved';

  @override
  String get data => 'Data';

  @override
  String exported(String path) {
    return 'Exported: $path';
  }

  @override
  String get importSuccessful => 'Import successful';

  @override
  String get importFailed => 'Import failed';

  @override
  String get buildingPlan => 'Building your plan...';

  @override
  String get analyzingMetabolism => 'Analyzing your metabolism';

  @override
  String get apiKeyValidationError => 'Please enter a valid API key';

  @override
  String analysisError(String error) {
    return 'Analysis error: $error';
  }

  @override
  String get mealSaved => 'Meal saved';

  @override
  String get logYourWeight => 'Log your weight';

  @override
  String get weightReminderBody => 'Don\'t forget to track your weight today!';

  @override
  String get mealReminderTitle => 'Time to eat!';

  @override
  String get mealReminderBody => 'Remember to log your meal.';

  @override
  String get howOldAreYou => 'How old are you?';

  @override
  String get whatsYourGoal => 'What\'s your goal?';

  @override
  String get loseWeight => 'Healthy Pace';

  @override
  String get maintainWeight => 'Steady Path';

  @override
  String get gainMuscle => 'Building Strength';

  @override
  String get whatsYourGender => 'What\'s your gender?';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get yourBmi => 'YOUR BMI';

  @override
  String get status => 'STATUS';

  @override
  String get weightProgress => 'Weight Progress';

  @override
  String get caloriesConsumed => 'CALORIES CONSUMED';

  @override
  String get proteinShort => 'Prot';

  @override
  String get carbsShort => 'Carb';

  @override
  String get fatsShort => 'Fat';

  @override
  String get reminders => 'Nudges';

  @override
  String get logMeals => 'Log meals';

  @override
  String get logMealsSubtitle => 'Morning, Lunch, Dinner';

  @override
  String get logWeight => 'Log weight';

  @override
  String get logWeightSubtitle => 'Daily reminder';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get recentHistory => 'Recent History';

  @override
  String get noFoodDetected => 'No food detected. Please try again.';

  @override
  String get myHistory => 'My History';

  @override
  String get noMealsRecorded => 'Your journal is empty.';

  @override
  String get deleteQuestion => 'Delete?';

  @override
  String get deleteMealConfirmation =>
      'Do you really want to delete this meal?';

  @override
  String get analyzingMeal => 'Checking provisions...';

  @override
  String get cameraNeeded => 'Camera Access Needed';

  @override
  String get cameraPermissionText =>
      'To analyze your meals, Kalorat needs access to your camera.';

  @override
  String get backToSelection => 'Back to selection';

  @override
  String get reviewPhotos => 'Review Photos';

  @override
  String get discard => 'Discard';

  @override
  String get addPhoto => '+ Photo';

  @override
  String get startAnalysis => 'Start Analysis';

  @override
  String get analysisResult => 'Analysis Result';

  @override
  String get saveMeal => 'Log Entry';

  @override
  String get welcomeSlogan => 'Calories, tracked beautifully.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get genderLabel => 'Gender';

  @override
  String get goalLabel => 'Goal';

  @override
  String get geminiApiKeyLabel => 'Gemini API Key';

  @override
  String get ok => 'OK';

  @override
  String get chooseGender => 'Choose your gender';

  @override
  String get calculateMetabolicRate => 'To calculate your metabolic rate.';

  @override
  String get continueButton => 'Continue';

  @override
  String get whatIsYourGoal => 'What is your goal?';

  @override
  String get burnFatSubtitle => 'Burn fat & get lean';

  @override
  String get maintainSubtitle => 'Stay healthy & fit';

  @override
  String get buildMassSubtitle => 'Build mass & strength';

  @override
  String get createPlan => 'Create Plan';

  @override
  String get aiConfigure => 'Configure AI';

  @override
  String get goTo => 'Go to ';

  @override
  String get createKeyInstruction =>
      ' and create a free key. Copy it, paste it here, and start tracking.';

  @override
  String get enterApiKeyError => 'Please enter an API Key';

  @override
  String get invalidApiKeyError => 'Invalid API Key. Please check your input.';

  @override
  String get validateAndContinue => 'Validate & Continue';

  @override
  String get nameSubtitle => 'We\'d like to know how to call you.';

  @override
  String get cm => 'cm';

  @override
  String get kg => 'kg';

  @override
  String get kcal => 'kcal';

  @override
  String get grams => 'g';

  @override
  String get weightSaved => 'Weight saved!';

  @override
  String get goalWeightLoss => 'Weight Loss';

  @override
  String get goalMaintainWeight => 'Maintain Weight';

  @override
  String get goalMuscleGain => 'Muscle Gain';

  @override
  String get editMealName => 'Edit meal name';

  @override
  String get editCalories => 'Edit calories';

  @override
  String get date => 'Date';
}
