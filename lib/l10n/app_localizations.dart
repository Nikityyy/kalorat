import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Kalorat'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In de, this message translates to:
  /// **'Willkommen bei Kalorat'**
  String get welcome;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Begleiter am Berg.'**
  String get welcomeSubtitle;

  /// No description provided for @next.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get next;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @yes.
  ///
  /// In de, this message translates to:
  /// **'Ja'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In de, this message translates to:
  /// **'Nein'**
  String get no;

  /// No description provided for @onboardingName.
  ///
  /// In de, this message translates to:
  /// **'Wie heißt du?'**
  String get onboardingName;

  /// No description provided for @onboardingNameHint.
  ///
  /// In de, this message translates to:
  /// **'Dein Name'**
  String get onboardingNameHint;

  /// No description provided for @onboardingBirthdate.
  ///
  /// In de, this message translates to:
  /// **'Wann bist du geboren?'**
  String get onboardingBirthdate;

  /// No description provided for @onboardingHeight.
  ///
  /// In de, this message translates to:
  /// **'Wie groß bist du?'**
  String get onboardingHeight;

  /// No description provided for @onboardingHeightHint.
  ///
  /// In de, this message translates to:
  /// **'Größe in cm'**
  String get onboardingHeightHint;

  /// No description provided for @onboardingWeight.
  ///
  /// In de, this message translates to:
  /// **'Wie viel wiegst du?'**
  String get onboardingWeight;

  /// No description provided for @onboardingWeightHint.
  ///
  /// In de, this message translates to:
  /// **'Gewicht in kg'**
  String get onboardingWeightHint;

  /// No description provided for @onboardingLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache auswählen'**
  String get onboardingLanguage;

  /// No description provided for @onboardingApiKey.
  ///
  /// In de, this message translates to:
  /// **'Gemini API-Key eingeben'**
  String get onboardingApiKey;

  /// No description provided for @onboardingApiKeyHint.
  ///
  /// In de, this message translates to:
  /// **'API-Key'**
  String get onboardingApiKeyHint;

  /// No description provided for @onboardingApiKeyInfo.
  ///
  /// In de, this message translates to:
  /// **'API-Key von ai.dev eintragen. Gehe zu https://ai.dev → Konto → API Key erstellen → hier einfügen.'**
  String get onboardingApiKeyInfo;

  /// No description provided for @home.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get home;

  /// No description provided for @me.
  ///
  /// In de, this message translates to:
  /// **'Ich'**
  String get me;

  /// No description provided for @history.
  ///
  /// In de, this message translates to:
  /// **'Historie'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @age.
  ///
  /// In de, this message translates to:
  /// **'Alter'**
  String get age;

  /// No description provided for @years.
  ///
  /// In de, this message translates to:
  /// **'Jahre'**
  String get years;

  /// No description provided for @height.
  ///
  /// In de, this message translates to:
  /// **'Größe'**
  String get height;

  /// No description provided for @weight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get weight;

  /// No description provided for @bmi.
  ///
  /// In de, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @bmiUnderweight.
  ///
  /// In de, this message translates to:
  /// **'Untergewicht'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In de, this message translates to:
  /// **'Normalgewicht'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In de, this message translates to:
  /// **'Übergewicht'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In de, this message translates to:
  /// **'Adipositas'**
  String get bmiObese;

  /// No description provided for @takePhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get takePhoto;

  /// No description provided for @addMorePhotos.
  ///
  /// In de, this message translates to:
  /// **'Weitere Fotos hinzufügen'**
  String get addMorePhotos;

  /// No description provided for @analyzeMeal.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit checken'**
  String get analyzeMeal;

  /// No description provided for @analyzing.
  ///
  /// In de, this message translates to:
  /// **'Prüfe...'**
  String get analyzing;

  /// No description provided for @mealName.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit'**
  String get mealName;

  /// No description provided for @calories.
  ///
  /// In de, this message translates to:
  /// **'Kalorien'**
  String get calories;

  /// No description provided for @protein.
  ///
  /// In de, this message translates to:
  /// **'Eiweiß'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In de, this message translates to:
  /// **'Kohlenhydrate'**
  String get carbs;

  /// No description provided for @fats.
  ///
  /// In de, this message translates to:
  /// **'Fett'**
  String get fats;

  /// No description provided for @vitamins.
  ///
  /// In de, this message translates to:
  /// **'Vitamine'**
  String get vitamins;

  /// No description provided for @minerals.
  ///
  /// In de, this message translates to:
  /// **'Mineralstoffe'**
  String get minerals;

  /// No description provided for @manualEntry.
  ///
  /// In de, this message translates to:
  /// **'Manuell eingeben'**
  String get manualEntry;

  /// No description provided for @offlineMessage.
  ///
  /// In de, this message translates to:
  /// **'Du bist offline. Die AI wird die Mahlzeit analysieren, sobald du wieder online bist und die App öffnest.'**
  String get offlineMessage;

  /// No description provided for @pendingAnalysis.
  ///
  /// In de, this message translates to:
  /// **'Ausstehende Analysen'**
  String get pendingAnalysis;

  /// No description provided for @processingQueue.
  ///
  /// In de, this message translates to:
  /// **'Verarbeite ausstehende Mahlzeiten...'**
  String get processingQueue;

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In de, this message translates to:
  /// **'Dieser Monat'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In de, this message translates to:
  /// **'Dieses Jahr'**
  String get thisYear;

  /// No description provided for @day.
  ///
  /// In de, this message translates to:
  /// **'Tag'**
  String get day;

  /// No description provided for @week.
  ///
  /// In de, this message translates to:
  /// **'Woche'**
  String get week;

  /// No description provided for @month.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get month;

  /// No description provided for @year.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get year;

  /// No description provided for @total.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get total;

  /// No description provided for @weightTracking.
  ///
  /// In de, this message translates to:
  /// **'Gewichtsverlauf'**
  String get weightTracking;

  /// No description provided for @addWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht eintragen'**
  String get addWeight;

  /// No description provided for @weightHistory.
  ///
  /// In de, this message translates to:
  /// **'Gewichtsverlauf'**
  String get weightHistory;

  /// No description provided for @noWeightData.
  ///
  /// In de, this message translates to:
  /// **'Der Weg beginnt hier.'**
  String get noWeightData;

  /// No description provided for @statistics.
  ///
  /// In de, this message translates to:
  /// **'Statistiken'**
  String get statistics;

  /// No description provided for @noMealData.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Mahlzeiten erfasst'**
  String get noMealData;

  /// No description provided for @mealsLogged.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeiten erfasst'**
  String get mealsLogged;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @german.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @english.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @apiKey.
  ///
  /// In de, this message translates to:
  /// **'API-Key'**
  String get apiKey;

  /// No description provided for @apiKeyInfo.
  ///
  /// In de, this message translates to:
  /// **'API-Key von ai.dev eintragen oder ändern.'**
  String get apiKeyInfo;

  /// No description provided for @exportData.
  ///
  /// In de, this message translates to:
  /// **'Daten exportieren'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In de, this message translates to:
  /// **'Daten importieren'**
  String get importData;

  /// No description provided for @exportSuccess.
  ///
  /// In de, this message translates to:
  /// **'Daten erfolgreich exportiert'**
  String get exportSuccess;

  /// No description provided for @importSuccess.
  ///
  /// In de, this message translates to:
  /// **'Daten erfolgreich importiert'**
  String get importSuccess;

  /// No description provided for @importError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Importieren'**
  String get importError;

  /// No description provided for @notifications.
  ///
  /// In de, this message translates to:
  /// **'Benachrichtigungen'**
  String get notifications;

  /// No description provided for @mealReminders.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit-Erinnerungen'**
  String get mealReminders;

  /// No description provided for @weightReminders.
  ///
  /// In de, this message translates to:
  /// **'Gewichts-Erinnerungen'**
  String get weightReminders;

  /// No description provided for @confirmDelete.
  ///
  /// In de, this message translates to:
  /// **'Wirklich löschen?'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMeal.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du diese Mahlzeit wirklich löschen?'**
  String get confirmDeleteMeal;

  /// No description provided for @cameraPermission.
  ///
  /// In de, this message translates to:
  /// **'Kamera-Berechtigung wird benötigt'**
  String get cameraPermission;

  /// No description provided for @grantPermission.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung erteilen'**
  String get grantPermission;

  /// No description provided for @startOnboarding.
  ///
  /// In de, this message translates to:
  /// **'Onboarding starten'**
  String get startOnboarding;

  /// No description provided for @meTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get meTitle;

  /// No description provided for @deleteWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht löschen?'**
  String get deleteWeight;

  /// No description provided for @deleteWeightConfirm.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du diesen Eintrag wirklich löschen?'**
  String get deleteWeightConfirm;

  /// No description provided for @name.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @heightCm.
  ///
  /// In de, this message translates to:
  /// **'Größe (cm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In de, this message translates to:
  /// **'Gewicht (kg)'**
  String get weightKg;

  /// No description provided for @birthdate.
  ///
  /// In de, this message translates to:
  /// **'Geburtsdatum'**
  String get birthdate;

  /// No description provided for @ageYears.
  ///
  /// In de, this message translates to:
  /// **'{age} Jahre'**
  String ageYears(int age);

  /// No description provided for @saveChanges.
  ///
  /// In de, this message translates to:
  /// **'Änderungen speichern'**
  String get saveChanges;

  /// No description provided for @saved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert'**
  String get saved;

  /// No description provided for @data.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get data;

  /// No description provided for @exported.
  ///
  /// In de, this message translates to:
  /// **'Exportiert: {path}'**
  String exported(String path);

  /// No description provided for @importSuccessful.
  ///
  /// In de, this message translates to:
  /// **'Import erfolgreich'**
  String get importSuccessful;

  /// No description provided for @importFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen'**
  String get importFailed;

  /// No description provided for @buildingPlan.
  ///
  /// In de, this message translates to:
  /// **'Wir erstellen deinen Plan...'**
  String get buildingPlan;

  /// No description provided for @analyzingMetabolism.
  ///
  /// In de, this message translates to:
  /// **'Dein Stoffwechsel wird analysiert'**
  String get analyzingMetabolism;

  /// No description provided for @apiKeyValidationError.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen gültigen API-Key eingeben'**
  String get apiKeyValidationError;

  /// No description provided for @analysisError.
  ///
  /// In de, this message translates to:
  /// **'Fehler bei der Analyse: {error}'**
  String analysisError(String error);

  /// No description provided for @mealSaved.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit gespeichert'**
  String get mealSaved;

  /// No description provided for @logYourWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht eintragen'**
  String get logYourWeight;

  /// No description provided for @weightReminderBody.
  ///
  /// In de, this message translates to:
  /// **'Vergiss nicht, dein Gewicht heute einzutragen.'**
  String get weightReminderBody;

  /// No description provided for @mealReminderTitle.
  ///
  /// In de, this message translates to:
  /// **'Zeit zum Essen'**
  String get mealReminderTitle;

  /// No description provided for @mealReminderBody.
  ///
  /// In de, this message translates to:
  /// **'Denk daran, deine Mahlzeit zu erfassen.'**
  String get mealReminderBody;

  /// No description provided for @howOldAreYou.
  ///
  /// In de, this message translates to:
  /// **'Wie alt bist du?'**
  String get howOldAreYou;

  /// No description provided for @whatsYourGoal.
  ///
  /// In de, this message translates to:
  /// **'Was ist dein Ziel?'**
  String get whatsYourGoal;

  /// No description provided for @loseWeight.
  ///
  /// In de, this message translates to:
  /// **'Gesundes Tempo'**
  String get loseWeight;

  /// No description provided for @maintainWeight.
  ///
  /// In de, this message translates to:
  /// **'Pfad halten'**
  String get maintainWeight;

  /// No description provided for @gainMuscle.
  ///
  /// In de, this message translates to:
  /// **'Kraft aufbauen'**
  String get gainMuscle;

  /// No description provided for @whatsYourGender.
  ///
  /// In de, this message translates to:
  /// **'Was ist dein Geschlecht?'**
  String get whatsYourGender;

  /// No description provided for @male.
  ///
  /// In de, this message translates to:
  /// **'Männlich'**
  String get male;

  /// No description provided for @female.
  ///
  /// In de, this message translates to:
  /// **'Weiblich'**
  String get female;

  /// No description provided for @other.
  ///
  /// In de, this message translates to:
  /// **'Divers'**
  String get other;

  /// No description provided for @yourBmi.
  ///
  /// In de, this message translates to:
  /// **'DEIN BMI'**
  String get yourBmi;

  /// No description provided for @status.
  ///
  /// In de, this message translates to:
  /// **'STATUS'**
  String get status;

  /// No description provided for @weightProgress.
  ///
  /// In de, this message translates to:
  /// **'Gewichtsverlauf'**
  String get weightProgress;

  /// No description provided for @caloriesConsumed.
  ///
  /// In de, this message translates to:
  /// **'KALORIEN AUFGENOMMEN'**
  String get caloriesConsumed;

  /// No description provided for @proteinShort.
  ///
  /// In de, this message translates to:
  /// **'Eiw.'**
  String get proteinShort;

  /// No description provided for @carbsShort.
  ///
  /// In de, this message translates to:
  /// **'KH'**
  String get carbsShort;

  /// No description provided for @fatsShort.
  ///
  /// In de, this message translates to:
  /// **'Fett'**
  String get fatsShort;

  /// No description provided for @reminders.
  ///
  /// In de, this message translates to:
  /// **'Impulse'**
  String get reminders;

  /// No description provided for @logMeals.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeiten loggen'**
  String get logMeals;

  /// No description provided for @logMealsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Morgens, Mittags, Abends'**
  String get logMealsSubtitle;

  /// No description provided for @logWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht loggen'**
  String get logWeight;

  /// No description provided for @logWeightSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Tägliche Erinnerung'**
  String get logWeightSubtitle;

  /// No description provided for @noDataAvailable.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten verfügbar'**
  String get noDataAvailable;

  /// No description provided for @recentHistory.
  ///
  /// In de, this message translates to:
  /// **'Verlauf der letzten Tage'**
  String get recentHistory;

  /// No description provided for @noFoodDetected.
  ///
  /// In de, this message translates to:
  /// **'Kein Essen erkannt. Bitte versuche es erneut.'**
  String get noFoodDetected;

  /// No description provided for @myHistory.
  ///
  /// In de, this message translates to:
  /// **'Meine Historie'**
  String get myHistory;

  /// No description provided for @noMealsRecorded.
  ///
  /// In de, this message translates to:
  /// **'Dein Journal ist leer.'**
  String get noMealsRecorded;

  /// No description provided for @deleteQuestion.
  ///
  /// In de, this message translates to:
  /// **'Löschen?'**
  String get deleteQuestion;

  /// No description provided for @deleteMealConfirmation.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du diese Mahlzeit wirklich löschen?'**
  String get deleteMealConfirmation;

  /// No description provided for @analyzingMeal.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit wird geprüft...'**
  String get analyzingMeal;

  /// No description provided for @cameraNeeded.
  ///
  /// In de, this message translates to:
  /// **'Kamera benötigt'**
  String get cameraNeeded;

  /// No description provided for @cameraPermissionText.
  ///
  /// In de, this message translates to:
  /// **'Damit Kalorat deine Mahlzeiten analysieren kann, benötigen wir Zugriff auf deine Kamera.'**
  String get cameraPermissionText;

  /// No description provided for @backToSelection.
  ///
  /// In de, this message translates to:
  /// **'Zurück zur Auswahl'**
  String get backToSelection;

  /// No description provided for @reviewPhotos.
  ///
  /// In de, this message translates to:
  /// **'Fotos überprüfen'**
  String get reviewPhotos;

  /// No description provided for @discard.
  ///
  /// In de, this message translates to:
  /// **'Verwerfen'**
  String get discard;

  /// No description provided for @addPhoto.
  ///
  /// In de, this message translates to:
  /// **'+ Foto'**
  String get addPhoto;

  /// No description provided for @startAnalysis.
  ///
  /// In de, this message translates to:
  /// **'Analyse starten'**
  String get startAnalysis;

  /// No description provided for @analysisResult.
  ///
  /// In de, this message translates to:
  /// **'Analyse Ergebnis'**
  String get analysisResult;

  /// No description provided for @saveMeal.
  ///
  /// In de, this message translates to:
  /// **'Eintrag loggen'**
  String get saveMeal;

  /// No description provided for @welcomeSlogan.
  ///
  /// In de, this message translates to:
  /// **'Kalorien, schön getrackt.'**
  String get welcomeSlogan;

  /// No description provided for @getStarted.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s'**
  String get getStarted;

  /// No description provided for @genderLabel.
  ///
  /// In de, this message translates to:
  /// **'Geschlecht'**
  String get genderLabel;

  /// No description provided for @goalLabel.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get goalLabel;

  /// No description provided for @geminiApiKeyLabel.
  ///
  /// In de, this message translates to:
  /// **'Gemini API-Key'**
  String get geminiApiKeyLabel;

  /// No description provided for @ok.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @chooseGender.
  ///
  /// In de, this message translates to:
  /// **'Welches Geschlecht hast du?'**
  String get chooseGender;

  /// No description provided for @calculateMetabolicRate.
  ///
  /// In de, this message translates to:
  /// **'Um deinen Grundumsatz zu berechnen.'**
  String get calculateMetabolicRate;

  /// No description provided for @continueButton.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueButton;

  /// No description provided for @whatIsYourGoal.
  ///
  /// In de, this message translates to:
  /// **'Was ist dein Ziel?'**
  String get whatIsYourGoal;

  /// No description provided for @burnFatSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Fett verbrennen'**
  String get burnFatSubtitle;

  /// No description provided for @maintainSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Gesund & fit bleiben'**
  String get maintainSubtitle;

  /// No description provided for @buildMassSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Masse & Stärke'**
  String get buildMassSubtitle;

  /// No description provided for @createPlan.
  ///
  /// In de, this message translates to:
  /// **'Plan erstellen'**
  String get createPlan;

  /// No description provided for @aiConfigure.
  ///
  /// In de, this message translates to:
  /// **'AI Konfigurieren'**
  String get aiConfigure;

  /// No description provided for @goTo.
  ///
  /// In de, this message translates to:
  /// **'Gehe zu '**
  String get goTo;

  /// No description provided for @createKeyInstruction.
  ///
  /// In de, this message translates to:
  /// **' und erstelle einen kostenlosen Key. Kopiere ihn, füge ihn hier ein und tracke deine Kalorien.'**
  String get createKeyInstruction;

  /// No description provided for @enterApiKeyError.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen API-Key ein'**
  String get enterApiKeyError;

  /// No description provided for @invalidApiKeyError.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger API-Key. Bitte überprüfe deine Eingabe.'**
  String get invalidApiKeyError;

  /// No description provided for @validateAndContinue.
  ///
  /// In de, this message translates to:
  /// **'Validieren & Weiter'**
  String get validateAndContinue;

  /// No description provided for @nameSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wir möchten dich persönlich ansprechen.'**
  String get nameSubtitle;

  /// No description provided for @cm.
  ///
  /// In de, this message translates to:
  /// **'cm'**
  String get cm;

  /// No description provided for @kg.
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @kcal.
  ///
  /// In de, this message translates to:
  /// **'kcal'**
  String get kcal;

  /// No description provided for @grams.
  ///
  /// In de, this message translates to:
  /// **'g'**
  String get grams;

  /// No description provided for @weightSaved.
  ///
  /// In de, this message translates to:
  /// **'Gewicht gespeichert!'**
  String get weightSaved;

  /// No description provided for @goalWeightLoss.
  ///
  /// In de, this message translates to:
  /// **'Gewicht verlieren'**
  String get goalWeightLoss;

  /// No description provided for @goalMaintainWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht halten'**
  String get goalMaintainWeight;

  /// No description provided for @goalMuscleGain.
  ///
  /// In de, this message translates to:
  /// **'Muskeln aufbauen'**
  String get goalMuscleGain;

  /// No description provided for @editMealName.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeitnamen bearbeiten'**
  String get editMealName;

  /// No description provided for @editCalories.
  ///
  /// In de, this message translates to:
  /// **'Kalorien bearbeiten'**
  String get editCalories;

  /// No description provided for @date.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get date;

  /// No description provided for @healthIntegration.
  ///
  /// In de, this message translates to:
  /// **'Gesundheitsintegration'**
  String get healthIntegration;

  /// No description provided for @healthSyncEnabled.
  ///
  /// In de, this message translates to:
  /// **'Mit Gesundheit synchronisieren'**
  String get healthSyncEnabled;

  /// No description provided for @healthSyncDescription.
  ///
  /// In de, this message translates to:
  /// **'Teile Ernährungs- und Gewichtsdaten mit Apple Health oder Google Health Connect.'**
  String get healthSyncDescription;

  /// No description provided for @connectHealth.
  ///
  /// In de, this message translates to:
  /// **'Verbinden'**
  String get connectHealth;

  /// No description provided for @disconnectHealth.
  ///
  /// In de, this message translates to:
  /// **'Trennen'**
  String get disconnectHealth;

  /// No description provided for @syncMeals.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeiten synchronisieren'**
  String get syncMeals;

  /// No description provided for @syncWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht synchronisieren'**
  String get syncWeight;

  /// No description provided for @healthConnected.
  ///
  /// In de, this message translates to:
  /// **'Verbunden'**
  String get healthConnected;

  /// No description provided for @healthNotConnected.
  ///
  /// In de, this message translates to:
  /// **'Nicht verbunden'**
  String get healthNotConnected;

  /// No description provided for @healthConnectNotInstalled.
  ///
  /// In de, this message translates to:
  /// **'Health Connect App nicht installiert'**
  String get healthConnectNotInstalled;

  /// No description provided for @healthPermissionDenied.
  ///
  /// In de, this message translates to:
  /// **'Gesundheitsberechtigungen verweigert'**
  String get healthPermissionDenied;

  /// No description provided for @healthSyncSuccess.
  ///
  /// In de, this message translates to:
  /// **'Mit Gesundheits-App synchronisiert'**
  String get healthSyncSuccess;

  /// No description provided for @healthOnboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Gesundheit verbinden'**
  String get healthOnboardingTitle;

  /// No description provided for @healthOnboardingDescription.
  ///
  /// In de, this message translates to:
  /// **'Synchronisiere deine Ernährungs- und Gewichtsdaten mit der Gesundheits-App deines Geräts für einen vollständigen Überblick.'**
  String get healthOnboardingDescription;

  /// No description provided for @healthOnboardingBenefit1.
  ///
  /// In de, this message translates to:
  /// **'Automatisches Mahlzeiten-Logging'**
  String get healthOnboardingBenefit1;

  /// No description provided for @healthOnboardingBenefit2.
  ///
  /// In de, this message translates to:
  /// **'Gewicht über Apps synchronisieren'**
  String get healthOnboardingBenefit2;

  /// No description provided for @healthOnboardingBenefit3.
  ///
  /// In de, this message translates to:
  /// **'Einheitliches Gesundheits-Dashboard'**
  String get healthOnboardingBenefit3;

  /// No description provided for @connectNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt verbinden'**
  String get connectNow;

  /// No description provided for @skipForNow.
  ///
  /// In de, this message translates to:
  /// **'Später einrichten'**
  String get skipForNow;

  /// No description provided for @syncWith.
  ///
  /// In de, this message translates to:
  /// **'Mit {appName} synchronisieren'**
  String syncWith(String appName);

  /// No description provided for @connected.
  ///
  /// In de, this message translates to:
  /// **'Verbunden'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In de, this message translates to:
  /// **'Getrennt'**
  String get disconnected;

  /// No description provided for @healthConnectionFailed.
  ///
  /// In de, this message translates to:
  /// **'Verbindung fehlgeschlagen'**
  String get healthConnectionFailed;

  /// No description provided for @loginTitle.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Synchronisiere deine Daten auf all deinen Geräten'**
  String get loginSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In de, this message translates to:
  /// **'Mit Google anmelden'**
  String get signInWithGoogle;

  /// No description provided for @continueAsGuest.
  ///
  /// In de, this message translates to:
  /// **'Als Gast fortfahren'**
  String get continueAsGuest;

  /// No description provided for @guestWarning.
  ///
  /// In de, this message translates to:
  /// **'Gastdaten werden nur lokal gespeichert und können nicht wiederhergestellt werden, wenn du das Gerät wechselst.'**
  String get guestWarning;

  /// No description provided for @account.
  ///
  /// In de, this message translates to:
  /// **'Konto'**
  String get account;

  /// No description provided for @loggedInAs.
  ///
  /// In de, this message translates to:
  /// **'Angemeldet als {email}'**
  String loggedInAs(String email);

  /// No description provided for @logOut.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get logOut;

  /// No description provided for @deleteAccount.
  ///
  /// In de, this message translates to:
  /// **'Konto löschen'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In de, this message translates to:
  /// **'Bist du sicher? Alle deine Daten werden unwiderruflich gelöscht.'**
  String get deleteAccountConfirm;

  /// No description provided for @requestData.
  ///
  /// In de, this message translates to:
  /// **'Meine Daten anfordern'**
  String get requestData;

  /// No description provided for @guestMode.
  ///
  /// In de, this message translates to:
  /// **'Gastmodus'**
  String get guestMode;

  /// No description provided for @loginToSync.
  ///
  /// In de, this message translates to:
  /// **'Anmelden um Daten zu synchronisieren'**
  String get loginToSync;

  /// No description provided for @syncComplete.
  ///
  /// In de, this message translates to:
  /// **'Synchronisierung abgeschlossen'**
  String get syncComplete;

  /// No description provided for @accountDeleted.
  ///
  /// In de, this message translates to:
  /// **'Konto gelöscht'**
  String get accountDeleted;

  /// No description provided for @dataExported.
  ///
  /// In de, this message translates to:
  /// **'Daten exportiert'**
  String get dataExported;

  /// No description provided for @accountSection.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten werden nur lokal gespeichert'**
  String get accountSection;

  /// No description provided for @settingsSaved.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen gespeichert'**
  String get settingsSaved;

  /// No description provided for @logOutConfirm.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du dich wirklich abmelden?'**
  String get logOutConfirm;

  /// No description provided for @loggedOut.
  ///
  /// In de, this message translates to:
  /// **'Erfolgreich abgemeldet'**
  String get loggedOut;

  /// No description provided for @error.
  ///
  /// In de, this message translates to:
  /// **'Fehler'**
  String get error;

  /// No description provided for @rateLimitMeals.
  ///
  /// In de, this message translates to:
  /// **'Der Guide sagt: Ruh dich etwas aus, du hast heute genug getrackt.'**
  String get rateLimitMeals;

  /// No description provided for @rateLimitPhotos.
  ///
  /// In de, this message translates to:
  /// **'Der Guide sagt: Pack leicht. 5 Fotos genügen.'**
  String get rateLimitPhotos;

  /// No description provided for @legal.
  ///
  /// In de, this message translates to:
  /// **'Rechtliches'**
  String get legal;

  /// No description provided for @privacyPolicy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutzerklärung'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In de, this message translates to:
  /// **'Nutzungsbedingungen'**
  String get termsOfService;

  /// No description provided for @featureOnlyInApp.
  ///
  /// In de, this message translates to:
  /// **'Nur in der App'**
  String get featureOnlyInApp;

  /// No description provided for @healthNotAvailableWeb.
  ///
  /// In de, this message translates to:
  /// **'Die Gesundheitsintegration erfordert die native App'**
  String get healthNotAvailableWeb;

  /// No description provided for @activityLevel.
  ///
  /// In de, this message translates to:
  /// **'Aktivitätslevel'**
  String get activityLevel;

  /// No description provided for @sedentary.
  ///
  /// In de, this message translates to:
  /// **'Sitzend'**
  String get sedentary;

  /// No description provided for @lightlyActive.
  ///
  /// In de, this message translates to:
  /// **'Leicht aktiv'**
  String get lightlyActive;

  /// No description provided for @moderatelyActive.
  ///
  /// In de, this message translates to:
  /// **'Moderat aktiv'**
  String get moderatelyActive;

  /// No description provided for @activeLevel.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get activeLevel;

  /// No description provided for @veryActive.
  ///
  /// In de, this message translates to:
  /// **'Sehr aktiv'**
  String get veryActive;

  /// No description provided for @activityLevelSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Für die Berechnung deines Kalorienbedarfs.'**
  String get activityLevelSubtitle;

  /// No description provided for @sedentarySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Büroarbeit, wenig Bewegung'**
  String get sedentarySubtitle;

  /// No description provided for @lightlyActiveSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Leichte Aktivität, 1-3x pro Woche'**
  String get lightlyActiveSubtitle;

  /// No description provided for @moderatelyActiveSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Sport 3-5x pro Woche'**
  String get moderatelyActiveSubtitle;

  /// No description provided for @activeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Sport 6-7x pro Woche'**
  String get activeSubtitle;

  /// No description provided for @veryActiveSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Schwere körperliche Arbeit'**
  String get veryActiveSubtitle;

  /// No description provided for @dailyAvg.
  ///
  /// In de, this message translates to:
  /// **'ø / Tag'**
  String get dailyAvg;

  /// No description provided for @streak.
  ///
  /// In de, this message translates to:
  /// **'Serie'**
  String get streak;

  /// No description provided for @streakDays.
  ///
  /// In de, this message translates to:
  /// **'{count} Tage'**
  String streakDays(int count);

  /// No description provided for @discardPhotos.
  ///
  /// In de, this message translates to:
  /// **'Fotos verwerfen?'**
  String get discardPhotos;

  /// No description provided for @discardPhotosConfirm.
  ///
  /// In de, this message translates to:
  /// **'Deine aufgenommenen Fotos gehen verloren.'**
  String get discardPhotosConfirm;

  /// No description provided for @selectDate.
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get selectDate;

  /// No description provided for @cameraNotAvailableWeb.
  ///
  /// In de, this message translates to:
  /// **'Kamera im Browser nicht verfügbar.'**
  String get cameraNotAvailableWeb;

  /// No description provided for @useGalleryInstead.
  ///
  /// In de, this message translates to:
  /// **'Nutze die Galerie unten, um Fotos auszuwählen.'**
  String get useGalleryInstead;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
