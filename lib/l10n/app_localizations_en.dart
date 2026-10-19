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
  String get welcomeSubtitle => 'Precise nutrition tracking. Absolute clarity.';

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
  String get analyzeMeal => 'Analyze';

  @override
  String get analyzing => 'Analyzing...';

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
  String get analysisWaitingForResume => 'Waiting for Kalorat to resume';

  @override
  String get analysisFailedTapToRetry => 'Analysis failed · tap to retry';

  @override
  String analysisRetrying(int attempt) {
    return 'Retrying ($attempt/3)';
  }

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
  String get noWeightData => 'No weight data recorded yet.';

  @override
  String get statistics => 'Statistics';

  @override
  String get noMealData => 'No meals recorded.';

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
  String get exportMarkdown => 'Export Markdown';

  @override
  String get reportTitle => 'Kalorat - Nutrition Report';

  @override
  String get reportGeneratedOn => 'Generated on';

  @override
  String get reportUserProfile => 'User Profile';

  @override
  String get reportGoal => 'Goal';

  @override
  String get reportActivityLevel => 'Activity Level';

  @override
  String get reportDailyCalories => 'Daily Calories Target';

  @override
  String get reportDailyProtein => 'Daily Protein Target';

  @override
  String get reportDailyCarbs => 'Daily Carbs Target';

  @override
  String get reportDailyFats => 'Daily Fat Target';

  @override
  String get reportMealsLog => 'Meals Log';

  @override
  String get reportWeight => 'Weight';

  @override
  String get reportDailyLog => 'Daily Log';

  @override
  String get reportNoMeals => '*No meals recorded.*';

  @override
  String get reportDailyTotal => 'Daily Total';

  @override
  String get reportUnnamedMeal => 'Unnamed Meal';

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
  String get startOnboarding => 'Start Onboarding';

  @override
  String get meTitle => 'Profile';

  @override
  String get deleteWeight => 'Delete weight?';

  @override
  String get deleteWeightConfirm => 'Do you really want to delete this entry?';

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
  String get buildingPlan => 'Saving profile...';

  @override
  String get apiKeyValidationError => 'Enter a valid API key.';

  @override
  String get nameValidationError => 'Enter your name.';

  @override
  String analysisError(String error) {
    return 'Analysis error: $error';
  }

  @override
  String get mealSaved => 'Meal saved';

  @override
  String get logYourWeight => 'Log your weight';

  @override
  String get weightReminderBody => 'Log today\'s weight.';

  @override
  String get mealReminderTitle => 'Meal reminder';

  @override
  String get mealReminderBody => 'Log your meal.';

  @override
  String get howOldAreYou => 'How old are you?';

  @override
  String get whatsYourGoal => 'What\'s your goal?';

  @override
  String get loseWeight => 'Lose weight';

  @override
  String get maintainWeight => 'Maintain weight';

  @override
  String get gainMuscle => 'Gain muscle';

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
  String healthyRange(String min, String max) {
    return 'Healthy range: $min - $max kg';
  }

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
  String get reminders => 'Reminders';

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
  String get noFoodDetected => 'No food detected. Try again.';

  @override
  String get myHistory => 'My History';

  @override
  String get noMealsRecorded => 'No meals recorded.';

  @override
  String get deleteQuestion => 'Delete?';

  @override
  String get deleteMealConfirmation =>
      'Do you really want to delete this meal?';

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
  String get welcomeSlogan => 'Calories, tracked with precision.';

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
  String get burnFatSubtitle => 'Calorie deficit';

  @override
  String get maintainSubtitle => 'Calorie balance';

  @override
  String get buildMassSubtitle => 'Calorie surplus';

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
  String get preferences => 'Preferences';

  @override
  String get integrations => 'Integrations';

  @override
  String get accountAndData => 'Account & Data';

  @override
  String get enterApiKeyError => 'Enter an API key.';

  @override
  String get invalidApiKeyError => 'Invalid API Key. Please check your input.';

  @override
  String get validateAndContinue => 'Validate & Continue';

  @override
  String get nameSubtitle => 'Shown in your profile.';

  @override
  String get cm => 'cm';

  @override
  String get kg => 'kg';

  @override
  String get kcal => 'kcal';

  @override
  String get grams => 'g';

  @override
  String get weightSaved => 'Weight saved';

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

  @override
  String get healthIntegration => 'Health Integration';

  @override
  String get healthSyncEnabled => 'Sync with Health';

  @override
  String get healthSyncDescription =>
      'Share nutrition and weight data with Apple Health or Google Health Connect.';

  @override
  String get connectHealth => 'Connect';

  @override
  String get disconnectHealth => 'Disconnect';

  @override
  String get syncMeals => 'Sync meals';

  @override
  String get syncWeight => 'Sync weight';

  @override
  String get healthConnected => 'Connected';

  @override
  String get healthNotConnected => 'Not connected';

  @override
  String get healthConnectNotInstalled => 'Health Connect app not installed';

  @override
  String get healthPermissionDenied => 'Health permissions denied';

  @override
  String get healthSyncSuccess => 'Synced with health app';

  @override
  String get healthOnboardingTitle => 'Connect Your Health';

  @override
  String get healthOnboardingDescription =>
      'Sync nutrition and weight with your device\'s health app.';

  @override
  String get healthOnboardingBenefit1 => 'Automatic meal logging';

  @override
  String get healthOnboardingBenefit2 => 'Weight sync across apps';

  @override
  String get healthOnboardingBenefit3 => 'Unified health dashboard';

  @override
  String get connectNow => 'Connect Now';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String syncWith(String appName) {
    return 'Sync with $appName';
  }

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get healthConnectionFailed => 'Connection failed';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle => 'Sync your data across all your devices';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get guestWarning =>
      'Guest data is only stored locally and cannot be recovered if you switch devices.';

  @override
  String get account => 'Account';

  @override
  String loggedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get logOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure? All your data will be permanently deleted.';

  @override
  String get requestData => 'Request My Data';

  @override
  String get guestMode => 'Guest Mode';

  @override
  String get loginToSync => 'Sign in to sync your data';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get dataExported => 'Data exported';

  @override
  String get accountSection => 'Your data is stored locally only';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get logOutConfirm => 'Are you sure you want to log out?';

  @override
  String get loggedOut => 'Logged out successfully';

  @override
  String get error => 'Error';

  @override
  String get rateLimitMeals => 'Maximum reached. 15 meals per day limit.';

  @override
  String get rateLimitPhotos => 'Maximum reached. 5 photos per meal limit.';

  @override
  String get legal => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get featureOnlyInApp => 'Only in app';

  @override
  String get healthNotAvailableWeb =>
      'Health integration requires the native app';

  @override
  String get activityLevel => 'Activity Level';

  @override
  String get sedentary => 'Sedentary';

  @override
  String get lightlyActive => 'Lightly Active';

  @override
  String get moderatelyActive => 'Moderately Active';

  @override
  String get activeLevel => 'Active';

  @override
  String get veryActive => 'Very Active';

  @override
  String get activityLevelSubtitle => 'To calculate your calorie needs.';

  @override
  String get sedentarySubtitle => 'Desk job, little movement';

  @override
  String get lightlyActiveSubtitle => 'Light activity, 1-3x per week';

  @override
  String get moderatelyActiveSubtitle => 'Exercise 3-5x per week';

  @override
  String get activeSubtitle => 'Exercise 6-7x per week';

  @override
  String get veryActiveSubtitle => 'Heavy physical labor';

  @override
  String get dailyAvg => 'ø / day';

  @override
  String get streak => 'Streak';

  @override
  String streakDays(int count) {
    return '$count days';
  }

  @override
  String get discardPhotos => 'Discard photos?';

  @override
  String get discardPhotosConfirm => 'Your captured photos will be lost.';

  @override
  String get selectDate => 'Select date';

  @override
  String get cameraNotAvailableWeb => 'Camera unavailable.';

  @override
  String get useGalleryInstead =>
      'Allow camera access or use the gallery button.';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateReady => 'A new version is available.';

  @override
  String get reloadButton => 'Reload';

  @override
  String get laterButton => 'Later';

  @override
  String get mealContextTitle => 'Anything to add?';

  @override
  String get mealContextHint =>
      'e.g. Vanilla pudding, 200g, info from label...';

  @override
  String get mealContextSkip => 'No note';

  @override
  String get mealContextAnalyze => 'Analyze';

  @override
  String get mealContextBackground => 'In background';

  @override
  String get mealSavedBackground =>
      'Meal saved. Analysis will continue when Kalorat is open and online.';

  @override
  String get ml => 'ml';

  @override
  String get saveToGallery => 'Save photo';

  @override
  String get saveToGallerySuccess => 'Photo saved to gallery';

  @override
  String get saveToGalleryError => 'Could not save photo.';

  @override
  String get dayStartsAt => 'Day starts at';

  @override
  String get dayStartsAtHint =>
      'Meals logged before this time count towards the previous day';

  @override
  String get aiThinkingTitle => 'AI Reasoning';

  @override
  String get aiThinkingLabel => 'AI is thinking...';

  @override
  String get analysisTimedOut => 'Analysis timed out. Try again.';

  @override
  String get reference => 'Reference';

  @override
  String get showLess => 'Show less';

  @override
  String showAllWeights(int count) {
    return 'Show all $count weights';
  }

  @override
  String get editWeight => 'Edit weight';

  @override
  String get weightRangeError => 'Enter a weight between 20 and 400 kg.';

  @override
  String get largeWeightJump => 'Large weight change';

  @override
  String confirmWeightJump(String previous, String next) {
    return 'Save the change from $previous to $next kg?';
  }

  @override
  String weeklyDifference(String difference) {
    return '7-day change: $difference kg';
  }

  @override
  String get switchCamera => 'Switch camera';

  @override
  String get flash => 'Flash';

  @override
  String get flashUnavailable => 'Flash unavailable';

  @override
  String get analysisUpdated => 'Analysis updated';

  @override
  String analysisConfidence(int percent) {
    return 'AI confidence: $percent%';
  }

  @override
  String retryFailed(String error) {
    return 'Retry failed: $error';
  }

  @override
  String get retryAnalysis => 'Restart analysis';

  @override
  String get syncData => 'Sync data';

  @override
  String get downloadStarted => 'Download started';

  @override
  String get restoreImportBackup => 'Restore last import backup';

  @override
  String get backupRestored => 'Backup restored.';

  @override
  String get close => 'Close';

  @override
  String get aBitAboutYou => 'About you';

  @override
  String get biologicalSex => 'Biological Sex';

  @override
  String get yourMeasurements => 'Your measurements';

  @override
  String get planReady => 'Plan calculated';

  @override
  String get basedOnProfile => 'Based on your profile.';

  @override
  String get dailyCalorieTarget => 'Daily Calorie Target';

  @override
  String get signUpToSave =>
      'You can change this in Settings, and sign in there to back up your data.';

  @override
  String get createAccount => 'Continue';

  @override
  String get cameraGuideText => 'Center the meal or a barcode in the frame.';

  @override
  String get apiKeyUnreachable => 'Google unreachable. Check your connection.';

  @override
  String get appVersion => 'Version';

  @override
  String get offlineShort => 'Offline';

  @override
  String get gramModeTitle => 'Gram mode';

  @override
  String get gramModeSubtitle => 'Show grams instead of servings';

  @override
  String get accurateModeTitle => 'Accurate mode';

  @override
  String get accurateModeSubtitle =>
      'Deeper analysis, more accurate. Off is faster.';

  @override
  String get gallery => 'Gallery';

  @override
  String get quickLogTitle => 'Quick log';

  @override
  String get quickLogHint =>
      'Describe what you ate, e.g. two slices of toast with butter';

  @override
  String get quickLogRecent => 'Eat it again';

  @override
  String get quickLogAgainAction => 'Log again';

  @override
  String quickLogLogged(String name) {
    return '$name logged';
  }

  @override
  String get quickLogUndo => 'Undo';

  @override
  String get quickLogFailed => 'Could not log the meal.';

  @override
  String get barcodeLookingUp => 'Looking up the product…';

  @override
  String get barcodeNotFound =>
      'Product not found. Photograph the nutrition label instead.';

  @override
  String barcodeNoNutrition(String name) {
    return 'No nutrition data for $name. Photograph the nutrition label instead.';
  }

  @override
  String get barcodeLookupFailed =>
      'Could not look up the product. Photograph the nutrition label instead.';

  @override
  String get barcodeLabelAction => 'Photograph label';

  @override
  String get barcodeLabelGuide => 'Photograph the nutrition label.';

  @override
  String barcodeLabelContext(String product) {
    return 'Nutrition label of $product';
  }

  @override
  String barcodeSourceNote(String code) {
    return 'Nutrition values from Open Food Facts (barcode $code).';
  }

  @override
  String get barcodeSwitchOn => 'Use nutrition values from Open Food Facts';

  @override
  String get barcodeSwitchOff =>
      'Barcode ignored, the photo is analyzed as a meal';

  @override
  String get barcodeRetryHint => 'Turn off to analyze the photo as a meal';

  @override
  String get retrySheetTitle => 'Analyze again';

  @override
  String get retrySheetSubtitle => 'Edit the note or analyze again right away';

  @override
  String get retrySheetHint => 'e.g. 2 portions, extra sauce ...';

  @override
  String get retrySheetAction => 'Analyze again';

  @override
  String estimatedRange(String range) {
    return 'Estimated range: $range';
  }

  @override
  String get analysisNoResult => 'No result received.';

  @override
  String analysisParseError(String error) {
    return 'The analysis could not be read: $error';
  }

  @override
  String get cameraDiagnosticsTitle => 'Camera diagnostics';

  @override
  String get cameraCanvasPreviewOn => 'Canvas preview: on';

  @override
  String get cameraCanvasPreviewOff => 'Canvas preview: off';

  @override
  String get backupShareText => 'Kalorat backup';

  @override
  String get reportShareText => 'Kalorat Markdown report';

  @override
  String get restoreBackupMissing => 'No import backup available.';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get weeklySummaryTitle => 'Last 7 days';

  @override
  String get weeklyAvgIntake => 'Average intake per day';

  @override
  String get weeklyOnTarget => 'On target';

  @override
  String weeklyAboveTarget(String kcal) {
    return '$kcal kcal above target';
  }

  @override
  String weeklyBelowTarget(String kcal) {
    return '$kcal kcal below target';
  }

  @override
  String weeklyDaysLogged(int count, int total) {
    return '$count of $total days logged';
  }

  @override
  String weeklyTarget(String kcal) {
    return 'Target $kcal kcal';
  }

  @override
  String weeklyWeightSpan(int days) {
    return 'over $days days';
  }

  @override
  String get weeklyWeightNeedMore => 'Two weigh-ins show the trend.';

  @override
  String get weeklyNoMeals => 'No meals logged in the last 7 days.';

  @override
  String get burnTitle => 'Estimated daily burn';

  @override
  String burnBasis(int days, int weighIns) {
    return 'From $days logged days and $weighIns weigh-ins in the last 4 weeks.';
  }

  @override
  String burnWeightTrend(String rate) {
    return 'Weight trend: $rate kg per week';
  }

  @override
  String burnFormula(String kcal) {
    return 'Formula (Mifflin-St Jeor): $kcal kcal';
  }

  @override
  String burnNeedsData(int days, int weighIns) {
    return 'Your real burn needs at least 3 weigh-ins over 10 days and meals logged on most of those days. So far: $days days, $weighIns weigh-ins.';
  }

  @override
  String get burnImplausible =>
      'The numbers don\'t add up. Meals or weigh-ins are probably missing.';

  @override
  String get burnDisclaimer =>
      'An estimate: only as accurate as your logged meals and weigh-ins.';

  @override
  String get correctionPrompt => 'Correct with one tap';

  @override
  String get correctionLower => 'Lower';

  @override
  String get correctionCurrent => 'Now';

  @override
  String get correctionHigher => 'Higher';

  @override
  String get validationInvalidMeal => 'Invalid meal.';

  @override
  String validationNegative(String field) {
    return '$field must not be negative.';
  }

  @override
  String get validationNutrition => 'Unrealistic nutrition values.';

  @override
  String get validationPortion => 'Unrealistic portion size.';

  @override
  String get validationPer100 => 'Invalid values per 100 g.';

  @override
  String get validationMacrosPer100 => 'Macros per 100 g cannot exceed 100 g.';

  @override
  String get validationWeightRange => 'Weight must be between 20 and 400 kg.';

  @override
  String get validationWeightFuture => 'The weight date is in the future.';

  @override
  String get validationDuplicateMeals => 'Duplicate meal IDs in the import.';

  @override
  String get thisWeekTitle => 'This week';

  @override
  String get startWeekStrong => 'Start your week strong.';

  @override
  String get keepMomentum => 'Keep the momentum going!';

  @override
  String get hintGotIt => 'Got it';

  @override
  String get hintNotNow => 'Not now';

  @override
  String get hintCameraTitle => 'Photograph your meal';

  @override
  String get hintCameraBody =>
      'Point the camera at your plate and tap the shutter. Before the analysis you can add more photos, a note, or a barcode for packaged food.';

  @override
  String get hintBackupTitle => 'Keep your meals safe';

  @override
  String get hintBackupBody =>
      'Your data is only stored on this device. Signing in with Google backs it up and makes it available on other devices.';

  @override
  String get hintBackupAction => 'Open settings';

  @override
  String get historyEmptyTitle => 'Your meals will appear here';

  @override
  String get historyEmptyBody =>
      'Every analysed meal is listed here, sorted by day, week, month or year. Switch to the camera to log your first one.';

  @override
  String get historyExampleLabel => 'Example';

  @override
  String get sampleMealName => 'Oatmeal';

  @override
  String get welcomeHaveAccount => 'I already have an account';

  @override
  String get loginNewHere => 'New here? Set up your profile';

  @override
  String get themeTitle => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';
}
