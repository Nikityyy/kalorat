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
  String get onboardingName => 'What\'s your name?';

  @override
  String get onboardingNameHint => 'Your name';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get age => 'Age';

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
  String get analyzeMeal => 'Analyze';

  @override
  String get analyzing => 'Analyzing…';

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
  String get offlineMessage =>
      'You are offline. The AI will analyze your meal once you are back online and open the app.';

  @override
  String get pendingAnalysis => 'Pending analyses';

  @override
  String get processingQueue => 'Processing pending meals…';

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
  String get day => 'Day';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get year => 'Year';

  @override
  String get addWeight => 'Add weight';

  @override
  String get language => 'Language';

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
  String get notifications => 'Notifications';

  @override
  String get mealReminders => 'Meal reminders';

  @override
  String get weightReminders => 'Weight reminders';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get startOnboarding => 'Set up your profile';

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
  String get data => 'Data';

  @override
  String get importSuccessful => 'Import successful';

  @override
  String get importFailed => 'Import failed';

  @override
  String get buildingPlan => 'Saving profile…';

  @override
  String get nameValidationError => 'Enter your name.';

  @override
  String get logYourWeight => 'Log your weight';

  @override
  String get weightReminderBody => 'Log today\'s weight.';

  @override
  String get mealReminderTitle => 'Meal reminder';

  @override
  String get mealReminderBody => 'Log your meal.';

  @override
  String get loseWeight => 'Lose weight';

  @override
  String get maintainWeight => 'Maintain weight';

  @override
  String get gainMuscle => 'Gain muscle';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String healthyRange(String min, String max) {
    return 'Healthy range: $min - $max kg';
  }

  @override
  String get status => 'Status';

  @override
  String get proteinShort => 'Prot';

  @override
  String get carbsShort => 'Carb';

  @override
  String get fatsShort => 'Fat';

  @override
  String get logWeight => 'Log weight';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get noFoodDetected => 'No food detected. Try again.';

  @override
  String get deleteQuestion => 'Delete?';

  @override
  String get deleteMealConfirmation =>
      'Do you really want to delete this meal?';

  @override
  String get cameraNeeded => 'Camera access needed';

  @override
  String get cameraPermissionText =>
      'To analyze your meals, Kalorat needs access to your camera.';

  @override
  String get backToSelection => 'Back to selection';

  @override
  String get reviewPhotos => 'Review photos';

  @override
  String get discard => 'Discard';

  @override
  String get addPhoto => '+ Photo';

  @override
  String get reorderPhotosHint => 'Hold and drag to change the order';

  @override
  String get coverPhoto => 'Cover';

  @override
  String get movePhotoEarlier => 'Move earlier';

  @override
  String get movePhotoLater => 'Move later';

  @override
  String get startAnalysis => 'Analyze';

  @override
  String get yourDescription => 'Your description';

  @override
  String get yourNote => 'Your note';

  @override
  String get saveMeal => 'Log meal';

  @override
  String get welcomeSlogan => 'Calories, tracked with precision.';

  @override
  String get getStarted => 'Get started';

  @override
  String get genderLabel => 'Gender';

  @override
  String get goalLabel => 'Goal';

  @override
  String get geminiApiKeyLabel => 'Gemini API key';

  @override
  String get ok => 'OK';

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
  String get accountAndData => 'Account and data';

  @override
  String get enterApiKeyError => 'Enter an API key.';

  @override
  String get invalidApiKeyError => 'Invalid API Key. Please check your input.';

  @override
  String get validateAndContinue => 'Check and continue';

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
  String get editMealName => 'Edit meal name';

  @override
  String get editCalories => 'Edit calories';

  @override
  String get date => 'Date';

  @override
  String get healthSyncEnabled => 'Sync with Health';

  @override
  String get syncMeals => 'Sync meals';

  @override
  String get syncWeight => 'Sync weight';

  @override
  String get healthConnected => 'Connected';

  @override
  String get healthConnectNotInstalled => 'Health Connect app not installed';

  @override
  String get healthPermissionDenied => 'Health permissions denied';

  @override
  String get healthOnboardingTitle => 'Connect your health app';

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
  String get connectNow => 'Connect now';

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
  String get loginTitle => 'Sign in';

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
  String get logOut => 'Sign out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure? All your data will be permanently deleted.';

  @override
  String get guestMode => 'Guest mode';

  @override
  String get loginToSync => 'Sign in to sync your data';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get accountDeleted => 'Account deleted';

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
  String get featureOnlyInApp => 'Only in app';

  @override
  String get activityLevel => 'Activity level';

  @override
  String get sedentary => 'Sedentary';

  @override
  String get lightlyActive => 'Lightly active';

  @override
  String get moderatelyActive => 'Moderately active';

  @override
  String get activeLevel => 'Active';

  @override
  String get veryActive => 'Very active';

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
  String get streak => 'Streak';

  @override
  String get discardPhotos => 'Discard photos?';

  @override
  String get discardPhotosConfirm => 'Your captured photos will be lost.';

  @override
  String get cameraNotAvailableWeb => 'Camera unavailable.';

  @override
  String get useGalleryInstead =>
      'Allow camera access or use the gallery button.';

  @override
  String get updateAvailable => 'Update available';

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
      'e.g. vanilla pudding, 200 g, info from the label';

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
  String get analysisTimedOut =>
      'Gemini did not answer in time. Please try again.';

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
  String get biologicalSex => 'Biological sex';

  @override
  String get yourMeasurements => 'Your measurements';

  @override
  String get planReady => 'Plan calculated';

  @override
  String get basedOnProfile => 'Based on your profile.';

  @override
  String get dailyCalorieTarget => 'Daily calorie target';

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
  String get mealDeleted => 'Meal deleted';

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
  String get retrySheetSubtitle => 'Note for the AI, optional';

  @override
  String get retrySheetHint => 'e.g. 2 portions, extra sauce';

  @override
  String get retryLeftoversTitle => 'Subtract leftovers';

  @override
  String get retryLeftoversHint =>
      'Photo of what is left on the plate; it gets subtracted.';

  @override
  String get retryLeftoversCamera => 'Photograph leftovers';

  @override
  String get retryLeftoversGallery => 'From photos';

  @override
  String retryLeftoversCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leftover photos',
      one: '1 leftover photo',
    );
    return '$_temp0';
  }

  @override
  String get retryLeftoversCountHint =>
      'The analysis counts only what was eaten.';

  @override
  String get retryLeftoversAddMore => 'Take another';

  @override
  String get retryLeftoverRemove => 'Remove photo';

  @override
  String get leftoversNeedOnline =>
      'Leftovers can only be subtracted when the analysis can run now. Remove the leftover photos or get back online.';

  @override
  String get photoTimeTitle => 'Time from the photo';

  @override
  String get photoTimeOff => 'Now';

  @override
  String get leftoversQuestion => 'Finished it all?';

  @override
  String get leftoversNone => 'Yes, all';

  @override
  String get leftoversSome => 'No, some left';

  @override
  String get shareMeal => 'Share';

  @override
  String get shareMealTitle => 'Share meal';

  @override
  String get shareStylePhoto => 'Photo';

  @override
  String get shareStyleLight => 'Light';

  @override
  String get shareStyleDark => 'Dark';

  @override
  String get shareImageAction => 'Share image';

  @override
  String get shareSaveAction => 'Save to Photos';

  @override
  String get shareFailed => 'The image could not be shared.';

  @override
  String sharePhotoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get componentsTitle => 'On the plate';

  @override
  String get componentsTapToEdit => 'Tap to change';

  @override
  String componentsTopShare(String first, String second, int percent) {
    return '$first and $second bring $percent% of the calories';
  }

  @override
  String get componentEditHint => 'Change amount';

  @override
  String componentPer100(int kcal) {
    return '$kcal kcal per 100 g';
  }

  @override
  String get componentSourceUsda => 'USDA';

  @override
  String get componentLess => 'Less';

  @override
  String get componentMore => 'More';

  @override
  String componentMealNow(int kcal, int total) {
    return '$kcal kcal · meal now $total kcal';
  }

  @override
  String get componentRemove => 'Remove';

  @override
  String get componentApply => 'Apply';

  @override
  String get analysisReadingPhoto => 'Reading the photo';

  @override
  String get analysisReadingText => 'Reading the description';

  @override
  String analysisParallel(int count) {
    return '$count estimates running in parallel';
  }

  @override
  String get analysisSingle => 'One quick estimate';

  @override
  String analysisComponentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parts found',
      one: '1 part found',
    );
    return '$_temp0';
  }

  @override
  String get analysisAmounts => 'Estimating amounts';

  @override
  String analysisEstimateOf(int done, int total) {
    return 'Estimate $done of $total';
  }

  @override
  String analysisSoFar(String values) {
    return 'So far $values kcal';
  }

  @override
  String analysisMedianOf(int count) {
    return 'Median of $count estimates';
  }

  @override
  String get analysisDone => 'Estimate ready';

  @override
  String get retrySheetAction => 'Analyze again';

  @override
  String get analysisNoResult => 'No result received.';

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
  String get burnTitle => 'Estimated daily burn';

  @override
  String burnBasis(int days, int weighIns) {
    return 'From $days logged days and $weighIns weigh-ins in the last 4 weeks.';
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

  @override
  String todayWithDate(String date) {
    return 'Today, $date';
  }

  @override
  String yesterdayWithDate(String date) {
    return 'Yesterday, $date';
  }

  @override
  String get pickDay => 'Choose a day';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String kcalOfTarget(String target) {
    return 'kcal of $target';
  }

  @override
  String get kcalToEatToday => 'kcal to eat today';

  @override
  String kcalLeftOf(String target) {
    return 'kcal left of $target';
  }

  @override
  String kcalOverTarget(String target) {
    return 'kcal over your $target';
  }

  @override
  String proteinOfTarget(int eaten, int target) {
    return '$eaten of $target g protein';
  }

  @override
  String get proteinReached => 'Protein target reached';

  @override
  String proteinToGo(int grams) {
    return '$grams g protein still to go';
  }

  @override
  String mealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meals',
      one: '1 meal',
    );
    return '$_temp0';
  }

  @override
  String get pastDayEmpty => 'Nothing was logged on this day.';

  @override
  String get todayEmptyBody =>
      'Your first meal starts the climb. Photograph the plate and Kalorat fills in the rest.';

  @override
  String get openCamera => 'Open camera';

  @override
  String get tabCamera => 'Camera';

  @override
  String get tabProgress => 'Progress';

  @override
  String get bodyTitle => 'Body';

  @override
  String streakLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'logged $count days in a row',
      one: 'logged 1 day in a row',
    );
    return '$_temp0';
  }

  @override
  String get streakNone => 'Log something today to start a streak.';

  @override
  String get previousPeriod => 'Previous period';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get averagePerDay => 'Average per day';

  @override
  String get periodNoMeals => 'Nothing was logged in this period.';

  @override
  String proteinAveragePerDay(int average, int target) {
    return 'Protein $average of $target g a day';
  }

  @override
  String burnPerDay(int kcal) {
    return 'about $kcal kcal a day';
  }

  @override
  String gramsProtein(int grams) {
    return '$grams g protein';
  }

  @override
  String get moreActions => 'More actions';

  @override
  String todayAt(String time) {
    return 'Today, $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday, $time';
  }

  @override
  String get portionLess => 'Smaller portion';

  @override
  String get portionMore => 'Larger portion';

  @override
  String get portionEdit => 'Enter the portion';

  @override
  String confidenceShort(int percent) {
    return '$percent% sure';
  }

  @override
  String probablyBetween(int low, int high) {
    return 'probably $low–$high kcal';
  }

  @override
  String get quickLogShort => 'Type it';

  @override
  String get kcalPerDayPlan => 'kcal a day';

  @override
  String proteinPerDayPlan(int grams) {
    return '$grams g protein a day';
  }

  @override
  String get analysisNoConnection =>
      'No connection to Gemini. Check your internet and try again.';

  @override
  String get analysisRateLimited =>
      'Gemini is busy right now. Please try again in a moment.';

  @override
  String get analysisFailed => 'Analysis failed. Please try again.';
}
