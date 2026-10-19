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

  /// No description provided for @analyzeMeal.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit checken'**
  String get analyzeMeal;

  /// No description provided for @analyzing.
  ///
  /// In de, this message translates to:
  /// **'Analysiere …'**
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
  /// **'Ausstehende Mahlzeiten werden verarbeitet …'**
  String get processingQueue;

  /// No description provided for @analysisWaitingForResume.
  ///
  /// In de, this message translates to:
  /// **'Wartet darauf, dass Kalorat fortgesetzt wird'**
  String get analysisWaitingForResume;

  /// No description provided for @analysisFailedTapToRetry.
  ///
  /// In de, this message translates to:
  /// **'Analyse fehlgeschlagen · zum Wiederholen tippen'**
  String get analysisFailedTapToRetry;

  /// No description provided for @analysisRetrying.
  ///
  /// In de, this message translates to:
  /// **'Neuer Versuch ({attempt}/3)'**
  String analysisRetrying(int attempt);

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

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

  /// No description provided for @addWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht eintragen'**
  String get addWeight;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

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

  /// No description provided for @exportMarkdown.
  ///
  /// In de, this message translates to:
  /// **'Markdown exportieren'**
  String get exportMarkdown;

  /// No description provided for @reportTitle.
  ///
  /// In de, this message translates to:
  /// **'Kalorat - Ernährungsbericht'**
  String get reportTitle;

  /// No description provided for @reportGeneratedOn.
  ///
  /// In de, this message translates to:
  /// **'Erstellt am'**
  String get reportGeneratedOn;

  /// No description provided for @reportUserProfile.
  ///
  /// In de, this message translates to:
  /// **'Benutzerprofil'**
  String get reportUserProfile;

  /// No description provided for @reportGoal.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get reportGoal;

  /// No description provided for @reportActivityLevel.
  ///
  /// In de, this message translates to:
  /// **'Aktivitätslevel'**
  String get reportActivityLevel;

  /// No description provided for @reportDailyCalories.
  ///
  /// In de, this message translates to:
  /// **'Tägliches Kalorienziel'**
  String get reportDailyCalories;

  /// No description provided for @reportDailyProtein.
  ///
  /// In de, this message translates to:
  /// **'Tägliches Proteinziel'**
  String get reportDailyProtein;

  /// No description provided for @reportDailyCarbs.
  ///
  /// In de, this message translates to:
  /// **'Tägliches Kohlenhydrateziel'**
  String get reportDailyCarbs;

  /// No description provided for @reportDailyFats.
  ///
  /// In de, this message translates to:
  /// **'Tägliches Fettziel'**
  String get reportDailyFats;

  /// No description provided for @reportWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get reportWeight;

  /// No description provided for @reportDailyLog.
  ///
  /// In de, this message translates to:
  /// **'Tagesprotokoll'**
  String get reportDailyLog;

  /// No description provided for @reportNoMeals.
  ///
  /// In de, this message translates to:
  /// **'*Keine Mahlzeiten aufgezeichnet.*'**
  String get reportNoMeals;

  /// No description provided for @reportDailyTotal.
  ///
  /// In de, this message translates to:
  /// **'Tagesgesamt'**
  String get reportDailyTotal;

  /// No description provided for @reportUnnamedMeal.
  ///
  /// In de, this message translates to:
  /// **'Unbenannte Mahlzeit'**
  String get reportUnnamedMeal;

  /// No description provided for @importData.
  ///
  /// In de, this message translates to:
  /// **'Daten importieren'**
  String get importData;

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

  /// No description provided for @data.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get data;

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
  /// **'Profil wird gespeichert …'**
  String get buildingPlan;

  /// No description provided for @nameValidationError.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib deinen Namen ein'**
  String get nameValidationError;

  /// No description provided for @logYourWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht eintragen'**
  String get logYourWeight;

  /// No description provided for @weightReminderBody.
  ///
  /// In de, this message translates to:
  /// **'Gewicht von heute erfassen.'**
  String get weightReminderBody;

  /// No description provided for @mealReminderTitle.
  ///
  /// In de, this message translates to:
  /// **'Erinnerung: Mahlzeit'**
  String get mealReminderTitle;

  /// No description provided for @mealReminderBody.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit erfassen.'**
  String get mealReminderBody;

  /// No description provided for @loseWeight.
  ///
  /// In de, this message translates to:
  /// **'Abnehmen'**
  String get loseWeight;

  /// No description provided for @maintainWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht halten'**
  String get maintainWeight;

  /// No description provided for @gainMuscle.
  ///
  /// In de, this message translates to:
  /// **'Muskeln aufbauen'**
  String get gainMuscle;

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

  /// No description provided for @healthyRange.
  ///
  /// In de, this message translates to:
  /// **'Gesunder Bereich: {min} - {max} kg'**
  String healthyRange(String min, String max);

  /// No description provided for @status.
  ///
  /// In de, this message translates to:
  /// **'Status'**
  String get status;

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

  /// No description provided for @logWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht loggen'**
  String get logWeight;

  /// No description provided for @noDataAvailable.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten verfügbar'**
  String get noDataAvailable;

  /// No description provided for @noFoodDetected.
  ///
  /// In de, this message translates to:
  /// **'Kein Essen erkannt. Bitte versuche es erneut.'**
  String get noFoodDetected;

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

  /// No description provided for @reorderPhotosHint.
  ///
  /// In de, this message translates to:
  /// **'Halten und ziehen, um die Reihenfolge zu ändern'**
  String get reorderPhotosHint;

  /// No description provided for @coverPhoto.
  ///
  /// In de, this message translates to:
  /// **'Titelbild'**
  String get coverPhoto;

  /// No description provided for @movePhotoEarlier.
  ///
  /// In de, this message translates to:
  /// **'Nach vorne'**
  String get movePhotoEarlier;

  /// No description provided for @movePhotoLater.
  ///
  /// In de, this message translates to:
  /// **'Nach hinten'**
  String get movePhotoLater;

  /// No description provided for @startAnalysis.
  ///
  /// In de, this message translates to:
  /// **'Analyse starten'**
  String get startAnalysis;

  /// No description provided for @yourDescription.
  ///
  /// In de, this message translates to:
  /// **'Deine Beschreibung'**
  String get yourDescription;

  /// No description provided for @yourNote.
  ///
  /// In de, this message translates to:
  /// **'Deine Notiz'**
  String get yourNote;

  /// No description provided for @saveMeal.
  ///
  /// In de, this message translates to:
  /// **'Eintrag loggen'**
  String get saveMeal;

  /// No description provided for @welcomeSlogan.
  ///
  /// In de, this message translates to:
  /// **'Kalorien, präzise getrackt.'**
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
  /// **'Kaloriendefizit'**
  String get burnFatSubtitle;

  /// No description provided for @maintainSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Kalorienbalance'**
  String get maintainSubtitle;

  /// No description provided for @buildMassSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Kalorienüberschuss'**
  String get buildMassSubtitle;

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
  /// **' und erstelle einen kostenlosen Key. Kopiere ihn, füge ihn hier ein und starte das Tracking.'**
  String get createKeyInstruction;

  /// No description provided for @preferences.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get preferences;

  /// No description provided for @integrations.
  ///
  /// In de, this message translates to:
  /// **'Integrationen'**
  String get integrations;

  /// No description provided for @accountAndData.
  ///
  /// In de, this message translates to:
  /// **'Konto & Daten'**
  String get accountAndData;

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
  /// **'Wird in deinem Profil angezeigt.'**
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
  /// **'Gewicht gespeichert'**
  String get weightSaved;

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

  /// No description provided for @healthSyncEnabled.
  ///
  /// In de, this message translates to:
  /// **'Mit Gesundheit synchronisieren'**
  String get healthSyncEnabled;

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

  /// No description provided for @healthOnboardingTitle.
  ///
  /// In de, this message translates to:
  /// **'Gesundheit verbinden'**
  String get healthOnboardingTitle;

  /// No description provided for @healthOnboardingDescription.
  ///
  /// In de, this message translates to:
  /// **'Ernährung und Gewicht mit der Gesundheits-App deines Geräts synchronisieren.'**
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
  /// **'Maximum erreicht. Limit von 15 Mahlzeiten pro Tag.'**
  String get rateLimitMeals;

  /// No description provided for @rateLimitPhotos.
  ///
  /// In de, this message translates to:
  /// **'Maximum erreicht. Limit von 5 Fotos pro Mahlzeit.'**
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

  /// No description provided for @featureOnlyInApp.
  ///
  /// In de, this message translates to:
  /// **'Nur in der App'**
  String get featureOnlyInApp;

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

  /// No description provided for @streak.
  ///
  /// In de, this message translates to:
  /// **'Serie'**
  String get streak;

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

  /// No description provided for @cameraNotAvailableWeb.
  ///
  /// In de, this message translates to:
  /// **'Kamera nicht verfügbar.'**
  String get cameraNotAvailableWeb;

  /// No description provided for @useGalleryInstead.
  ///
  /// In de, this message translates to:
  /// **'Kamerazugriff erlauben oder Galerie verwenden.'**
  String get useGalleryInstead;

  /// No description provided for @updateAvailable.
  ///
  /// In de, this message translates to:
  /// **'Update verfügbar'**
  String get updateAvailable;

  /// No description provided for @updateReady.
  ///
  /// In de, this message translates to:
  /// **'Neue Version verfügbar.'**
  String get updateReady;

  /// No description provided for @reloadButton.
  ///
  /// In de, this message translates to:
  /// **'Neu laden'**
  String get reloadButton;

  /// No description provided for @laterButton.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get laterButton;

  /// No description provided for @mealContextTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch etwas hinzufügen?'**
  String get mealContextTitle;

  /// No description provided for @mealContextHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Vanillepudding, 200 g, Angaben von der Packung'**
  String get mealContextHint;

  /// No description provided for @mealContextSkip.
  ///
  /// In de, this message translates to:
  /// **'Ohne Hinweis'**
  String get mealContextSkip;

  /// No description provided for @mealContextAnalyze.
  ///
  /// In de, this message translates to:
  /// **'Analysieren'**
  String get mealContextAnalyze;

  /// No description provided for @mealContextBackground.
  ///
  /// In de, this message translates to:
  /// **'Im Hintergrund'**
  String get mealContextBackground;

  /// No description provided for @mealSavedBackground.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert. Die Analyse läuft weiter, sobald Kalorat geöffnet und online ist.'**
  String get mealSavedBackground;

  /// No description provided for @saveToGallery.
  ///
  /// In de, this message translates to:
  /// **'Foto speichern'**
  String get saveToGallery;

  /// No description provided for @saveToGallerySuccess.
  ///
  /// In de, this message translates to:
  /// **'Foto in Galerie gespeichert'**
  String get saveToGallerySuccess;

  /// No description provided for @saveToGalleryError.
  ///
  /// In de, this message translates to:
  /// **'Foto konnte nicht gespeichert werden.'**
  String get saveToGalleryError;

  /// No description provided for @dayStartsAt.
  ///
  /// In de, this message translates to:
  /// **'Tag beginnt um'**
  String get dayStartsAt;

  /// No description provided for @dayStartsAtHint.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeiten, die vor dieser Uhrzeit gespeichert werden, zählen zum Vortag'**
  String get dayStartsAtHint;

  /// No description provided for @aiThinkingTitle.
  ///
  /// In de, this message translates to:
  /// **'KI-Analyse'**
  String get aiThinkingTitle;

  /// No description provided for @aiThinkingLabel.
  ///
  /// In de, this message translates to:
  /// **'Denkt nach …'**
  String get aiThinkingLabel;

  /// No description provided for @analysisTimedOut.
  ///
  /// In de, this message translates to:
  /// **'Gemini hat nicht rechtzeitig geantwortet. Bitte erneut versuchen.'**
  String get analysisTimedOut;

  /// No description provided for @reference.
  ///
  /// In de, this message translates to:
  /// **'Referenz'**
  String get reference;

  /// No description provided for @showLess.
  ///
  /// In de, this message translates to:
  /// **'Weniger anzeigen'**
  String get showLess;

  /// No description provided for @showAllWeights.
  ///
  /// In de, this message translates to:
  /// **'Alle {count} Gewichte anzeigen'**
  String showAllWeights(int count);

  /// No description provided for @editWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht bearbeiten'**
  String get editWeight;

  /// No description provided for @weightRangeError.
  ///
  /// In de, this message translates to:
  /// **'Bitte ein Gewicht zwischen 20 und 400 kg eingeben.'**
  String get weightRangeError;

  /// No description provided for @largeWeightJump.
  ///
  /// In de, this message translates to:
  /// **'Großer Gewichtssprung'**
  String get largeWeightJump;

  /// No description provided for @confirmWeightJump.
  ///
  /// In de, this message translates to:
  /// **'Änderung von {previous} auf {next} kg speichern?'**
  String confirmWeightJump(String previous, String next);

  /// No description provided for @weeklyDifference.
  ///
  /// In de, this message translates to:
  /// **'7-Tage-Differenz: {difference} kg'**
  String weeklyDifference(String difference);

  /// No description provided for @switchCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera wechseln'**
  String get switchCamera;

  /// No description provided for @flash.
  ///
  /// In de, this message translates to:
  /// **'Blitz'**
  String get flash;

  /// No description provided for @flashUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Blitz nicht verfügbar'**
  String get flashUnavailable;

  /// No description provided for @analysisUpdated.
  ///
  /// In de, this message translates to:
  /// **'Analyse aktualisiert'**
  String get analysisUpdated;

  /// No description provided for @analysisConfidence.
  ///
  /// In de, this message translates to:
  /// **'KI-Sicherheit: {percent}%'**
  String analysisConfidence(int percent);

  /// No description provided for @retryAnalysis.
  ///
  /// In de, this message translates to:
  /// **'Analyse neu starten'**
  String get retryAnalysis;

  /// No description provided for @syncData.
  ///
  /// In de, this message translates to:
  /// **'Daten synchronisieren'**
  String get syncData;

  /// No description provided for @downloadStarted.
  ///
  /// In de, this message translates to:
  /// **'Download gestartet'**
  String get downloadStarted;

  /// No description provided for @restoreImportBackup.
  ///
  /// In de, this message translates to:
  /// **'Letztes Import-Backup wiederherstellen'**
  String get restoreImportBackup;

  /// No description provided for @backupRestored.
  ///
  /// In de, this message translates to:
  /// **'Backup wiederhergestellt.'**
  String get backupRestored;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @aBitAboutYou.
  ///
  /// In de, this message translates to:
  /// **'Über dich'**
  String get aBitAboutYou;

  /// No description provided for @biologicalSex.
  ///
  /// In de, this message translates to:
  /// **'Biologisches Geschlecht'**
  String get biologicalSex;

  /// No description provided for @yourMeasurements.
  ///
  /// In de, this message translates to:
  /// **'Deine Maße'**
  String get yourMeasurements;

  /// No description provided for @planReady.
  ///
  /// In de, this message translates to:
  /// **'Plan berechnet'**
  String get planReady;

  /// No description provided for @basedOnProfile.
  ///
  /// In de, this message translates to:
  /// **'Basierend auf deinem Profil.'**
  String get basedOnProfile;

  /// No description provided for @dailyCalorieTarget.
  ///
  /// In de, this message translates to:
  /// **'Tägliches Kalorienziel'**
  String get dailyCalorieTarget;

  /// No description provided for @signUpToSave.
  ///
  /// In de, this message translates to:
  /// **'Du kannst das in den Einstellungen ändern und dich dort anmelden, um deine Daten zu sichern.'**
  String get signUpToSave;

  /// No description provided for @createAccount.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get createAccount;

  /// No description provided for @cameraGuideText.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit oder Barcode im Rahmen zentrieren.'**
  String get cameraGuideText;

  /// No description provided for @apiKeyUnreachable.
  ///
  /// In de, this message translates to:
  /// **'Google nicht erreichbar. Verbindung prüfen.'**
  String get apiKeyUnreachable;

  /// No description provided for @appVersion.
  ///
  /// In de, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @offlineShort.
  ///
  /// In de, this message translates to:
  /// **'Offline'**
  String get offlineShort;

  /// No description provided for @gramModeTitle.
  ///
  /// In de, this message translates to:
  /// **'Gramm-Modus'**
  String get gramModeTitle;

  /// No description provided for @gramModeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Gramm statt Portionen anzeigen'**
  String get gramModeSubtitle;

  /// No description provided for @accurateModeTitle.
  ///
  /// In de, this message translates to:
  /// **'Genauigkeitsmodus'**
  String get accurateModeTitle;

  /// No description provided for @accurateModeSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Tiefere Analyse, genauer. Aus ist schneller.'**
  String get accurateModeSubtitle;

  /// No description provided for @gallery.
  ///
  /// In de, this message translates to:
  /// **'Galerie'**
  String get gallery;

  /// No description provided for @quickLogTitle.
  ///
  /// In de, this message translates to:
  /// **'Schnell erfassen'**
  String get quickLogTitle;

  /// No description provided for @quickLogHint.
  ///
  /// In de, this message translates to:
  /// **'Beschreibe, was du gegessen hast, z. B. zwei Scheiben Toast mit Butter'**
  String get quickLogHint;

  /// No description provided for @quickLogRecent.
  ///
  /// In de, this message translates to:
  /// **'Nochmal essen'**
  String get quickLogRecent;

  /// No description provided for @quickLogAgainAction.
  ///
  /// In de, this message translates to:
  /// **'Nochmal erfassen'**
  String get quickLogAgainAction;

  /// No description provided for @quickLogLogged.
  ///
  /// In de, this message translates to:
  /// **'{name} erfasst'**
  String quickLogLogged(String name);

  /// No description provided for @quickLogUndo.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get quickLogUndo;

  /// No description provided for @mealDeleted.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit gelöscht'**
  String get mealDeleted;

  /// No description provided for @barcodeLookingUp.
  ///
  /// In de, this message translates to:
  /// **'Produkt wird gesucht…'**
  String get barcodeLookingUp;

  /// No description provided for @barcodeNotFound.
  ///
  /// In de, this message translates to:
  /// **'Produkt nicht gefunden. Fotografiere stattdessen die Nährwerttabelle.'**
  String get barcodeNotFound;

  /// No description provided for @barcodeNoNutrition.
  ///
  /// In de, this message translates to:
  /// **'Keine Nährwerte für {name}. Fotografiere stattdessen die Nährwerttabelle.'**
  String barcodeNoNutrition(String name);

  /// No description provided for @barcodeLookupFailed.
  ///
  /// In de, this message translates to:
  /// **'Produkt konnte nicht gesucht werden. Fotografiere stattdessen die Nährwerttabelle.'**
  String get barcodeLookupFailed;

  /// No description provided for @barcodeLabelAction.
  ///
  /// In de, this message translates to:
  /// **'Etikett fotografieren'**
  String get barcodeLabelAction;

  /// No description provided for @barcodeLabelGuide.
  ///
  /// In de, this message translates to:
  /// **'Fotografiere die Nährwerttabelle.'**
  String get barcodeLabelGuide;

  /// No description provided for @barcodeLabelContext.
  ///
  /// In de, this message translates to:
  /// **'Nährwerttabelle von {product}'**
  String barcodeLabelContext(String product);

  /// No description provided for @barcodeSourceNote.
  ///
  /// In de, this message translates to:
  /// **'Nährwerte von Open Food Facts (Barcode {code}).'**
  String barcodeSourceNote(String code);

  /// No description provided for @barcodeSwitchOn.
  ///
  /// In de, this message translates to:
  /// **'Nährwerte von Open Food Facts verwenden'**
  String get barcodeSwitchOn;

  /// No description provided for @barcodeSwitchOff.
  ///
  /// In de, this message translates to:
  /// **'Barcode ignoriert, das Foto wird als Mahlzeit analysiert'**
  String get barcodeSwitchOff;

  /// No description provided for @barcodeRetryHint.
  ///
  /// In de, this message translates to:
  /// **'Ausschalten, um das Foto als Mahlzeit zu analysieren'**
  String get barcodeRetryHint;

  /// No description provided for @retrySheetTitle.
  ///
  /// In de, this message translates to:
  /// **'Analyse wiederholen'**
  String get retrySheetTitle;

  /// No description provided for @retrySheetSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Hinweis bearbeiten oder direkt neu analysieren'**
  String get retrySheetSubtitle;

  /// No description provided for @retrySheetHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. 2 Portionen, extra Sauce'**
  String get retrySheetHint;

  /// No description provided for @retrySheetAction.
  ///
  /// In de, this message translates to:
  /// **'Neu analysieren'**
  String get retrySheetAction;

  /// No description provided for @analysisNoResult.
  ///
  /// In de, this message translates to:
  /// **'Kein Ergebnis erhalten.'**
  String get analysisNoResult;

  /// No description provided for @cameraDiagnosticsTitle.
  ///
  /// In de, this message translates to:
  /// **'Kamera-Diagnose'**
  String get cameraDiagnosticsTitle;

  /// No description provided for @cameraCanvasPreviewOn.
  ///
  /// In de, this message translates to:
  /// **'Canvas-Vorschau: an'**
  String get cameraCanvasPreviewOn;

  /// No description provided for @cameraCanvasPreviewOff.
  ///
  /// In de, this message translates to:
  /// **'Canvas-Vorschau: aus'**
  String get cameraCanvasPreviewOff;

  /// No description provided for @backupShareText.
  ///
  /// In de, this message translates to:
  /// **'Kalorat-Backup'**
  String get backupShareText;

  /// No description provided for @reportShareText.
  ///
  /// In de, this message translates to:
  /// **'Kalorat-Markdown-Bericht'**
  String get reportShareText;

  /// No description provided for @restoreBackupMissing.
  ///
  /// In de, this message translates to:
  /// **'Kein Import-Backup vorhanden.'**
  String get restoreBackupMissing;

  /// No description provided for @weeklyOnTarget.
  ///
  /// In de, this message translates to:
  /// **'Im Ziel'**
  String get weeklyOnTarget;

  /// No description provided for @weeklyAboveTarget.
  ///
  /// In de, this message translates to:
  /// **'{kcal} kcal über dem Ziel'**
  String weeklyAboveTarget(String kcal);

  /// No description provided for @weeklyBelowTarget.
  ///
  /// In de, this message translates to:
  /// **'{kcal} kcal unter dem Ziel'**
  String weeklyBelowTarget(String kcal);

  /// No description provided for @weeklyDaysLogged.
  ///
  /// In de, this message translates to:
  /// **'{count} von {total} Tagen erfasst'**
  String weeklyDaysLogged(int count, int total);

  /// No description provided for @burnTitle.
  ///
  /// In de, this message translates to:
  /// **'Geschätzter Tagesverbrauch'**
  String get burnTitle;

  /// No description provided for @burnBasis.
  ///
  /// In de, this message translates to:
  /// **'Aus {days} erfassten Tagen und {weighIns} Wiegungen der letzten 4 Wochen.'**
  String burnBasis(int days, int weighIns);

  /// No description provided for @burnFormula.
  ///
  /// In de, this message translates to:
  /// **'Formel (Mifflin-St Jeor): {kcal} kcal'**
  String burnFormula(String kcal);

  /// No description provided for @burnNeedsData.
  ///
  /// In de, this message translates to:
  /// **'Für deinen echten Verbrauch braucht es mindestens 3 Wiegungen über 10 Tage und Mahlzeiten an den meisten dieser Tage. Bisher: {days} Tage, {weighIns} Wiegungen.'**
  String burnNeedsData(int days, int weighIns);

  /// No description provided for @burnImplausible.
  ///
  /// In de, this message translates to:
  /// **'Die Werte passen nicht zusammen. Vermutlich fehlen Mahlzeiten oder Wiegungen.'**
  String get burnImplausible;

  /// No description provided for @burnDisclaimer.
  ///
  /// In de, this message translates to:
  /// **'Eine Schätzung: Sie ist nur so genau wie deine erfassten Mahlzeiten und Wiegungen.'**
  String get burnDisclaimer;

  /// No description provided for @correctionLower.
  ///
  /// In de, this message translates to:
  /// **'Weniger'**
  String get correctionLower;

  /// No description provided for @correctionCurrent.
  ///
  /// In de, this message translates to:
  /// **'Jetzt'**
  String get correctionCurrent;

  /// No description provided for @correctionHigher.
  ///
  /// In de, this message translates to:
  /// **'Mehr'**
  String get correctionHigher;

  /// No description provided for @validationInvalidMeal.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Mahlzeit.'**
  String get validationInvalidMeal;

  /// No description provided for @validationNegative.
  ///
  /// In de, this message translates to:
  /// **'{field} darf nicht negativ sein.'**
  String validationNegative(String field);

  /// No description provided for @validationNutrition.
  ///
  /// In de, this message translates to:
  /// **'Unrealistische Nährwerte.'**
  String get validationNutrition;

  /// No description provided for @validationPortion.
  ///
  /// In de, this message translates to:
  /// **'Unrealistische Portionsgröße.'**
  String get validationPortion;

  /// No description provided for @validationPer100.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Nährwerte pro 100 g.'**
  String get validationPer100;

  /// No description provided for @validationMacrosPer100.
  ///
  /// In de, this message translates to:
  /// **'Makros pro 100 g dürfen 100 g nicht überschreiten.'**
  String get validationMacrosPer100;

  /// No description provided for @validationWeightRange.
  ///
  /// In de, this message translates to:
  /// **'Das Gewicht muss zwischen 20 und 400 kg liegen.'**
  String get validationWeightRange;

  /// No description provided for @validationWeightFuture.
  ///
  /// In de, this message translates to:
  /// **'Das Gewichtsdatum liegt in der Zukunft.'**
  String get validationWeightFuture;

  /// No description provided for @validationDuplicateMeals.
  ///
  /// In de, this message translates to:
  /// **'Doppelte Mahlzeiten-IDs im Import.'**
  String get validationDuplicateMeals;

  /// No description provided for @hintGotIt.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get hintGotIt;

  /// No description provided for @hintNotNow.
  ///
  /// In de, this message translates to:
  /// **'Nicht jetzt'**
  String get hintNotNow;

  /// No description provided for @hintCameraTitle.
  ///
  /// In de, this message translates to:
  /// **'Foto deiner Mahlzeit'**
  String get hintCameraTitle;

  /// No description provided for @hintCameraBody.
  ///
  /// In de, this message translates to:
  /// **'Halte die Kamera auf deinen Teller und tippe auf den Auslöser. Vor der Analyse kannst du weitere Fotos, eine Notiz oder einen Barcode für Fertigprodukte hinzufügen.'**
  String get hintCameraBody;

  /// No description provided for @hintBackupTitle.
  ///
  /// In de, this message translates to:
  /// **'Sichere deine Mahlzeiten'**
  String get hintBackupTitle;

  /// No description provided for @hintBackupBody.
  ///
  /// In de, this message translates to:
  /// **'Deine Daten liegen nur auf diesem Gerät. Mit Google anmelden sichert sie und macht sie auf anderen Geräten verfügbar.'**
  String get hintBackupBody;

  /// No description provided for @hintBackupAction.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen öffnen'**
  String get hintBackupAction;

  /// No description provided for @welcomeHaveAccount.
  ///
  /// In de, this message translates to:
  /// **'Ich habe schon ein Konto'**
  String get welcomeHaveAccount;

  /// No description provided for @loginNewHere.
  ///
  /// In de, this message translates to:
  /// **'Neu hier? Profil einrichten'**
  String get loginNewHere;

  /// No description provided for @themeTitle.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @todayWithDate.
  ///
  /// In de, this message translates to:
  /// **'Heute, {date}'**
  String todayWithDate(String date);

  /// No description provided for @yesterdayWithDate.
  ///
  /// In de, this message translates to:
  /// **'Gestern, {date}'**
  String yesterdayWithDate(String date);

  /// No description provided for @pickDay.
  ///
  /// In de, this message translates to:
  /// **'Tag wählen'**
  String get pickDay;

  /// No description provided for @previousDay.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Tag'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In de, this message translates to:
  /// **'Nächster Tag'**
  String get nextDay;

  /// No description provided for @kcalOfTarget.
  ///
  /// In de, this message translates to:
  /// **'kcal von {target}'**
  String kcalOfTarget(String target);

  /// No description provided for @kcalToEatToday.
  ///
  /// In de, this message translates to:
  /// **'kcal für heute'**
  String get kcalToEatToday;

  /// No description provided for @kcalLeftOf.
  ///
  /// In de, this message translates to:
  /// **'kcal übrig von {target}'**
  String kcalLeftOf(String target);

  /// No description provided for @kcalOverTarget.
  ///
  /// In de, this message translates to:
  /// **'kcal über deinen {target}'**
  String kcalOverTarget(String target);

  /// No description provided for @proteinOfTarget.
  ///
  /// In de, this message translates to:
  /// **'{eaten} von {target} g Protein'**
  String proteinOfTarget(int eaten, int target);

  /// No description provided for @proteinReached.
  ///
  /// In de, this message translates to:
  /// **'Proteinziel erreicht'**
  String get proteinReached;

  /// No description provided for @proteinToGo.
  ///
  /// In de, this message translates to:
  /// **'Noch {grams} g Protein'**
  String proteinToGo(int grams);

  /// No description provided for @mealsCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Mahlzeit} other{{count} Mahlzeiten}}'**
  String mealsCount(int count);

  /// No description provided for @pastDayEmpty.
  ///
  /// In de, this message translates to:
  /// **'An diesem Tag ist nichts eingetragen.'**
  String get pastDayEmpty;

  /// No description provided for @todayEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Deine erste Mahlzeit beginnt den Aufstieg. Fotografiere den Teller, Kalorat erledigt den Rest.'**
  String get todayEmptyBody;

  /// No description provided for @openCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera öffnen'**
  String get openCamera;

  /// No description provided for @tabCamera.
  ///
  /// In de, this message translates to:
  /// **'Kamera'**
  String get tabCamera;

  /// No description provided for @tabProgress.
  ///
  /// In de, this message translates to:
  /// **'Fortschritt'**
  String get tabProgress;

  /// No description provided for @bodyTitle.
  ///
  /// In de, this message translates to:
  /// **'Körper'**
  String get bodyTitle;

  /// No description provided for @streakLine.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag in Folge eingetragen} other{{count} Tage in Folge eingetragen}}'**
  String streakLine(int count);

  /// No description provided for @streakNone.
  ///
  /// In de, this message translates to:
  /// **'Trag heute etwas ein, um eine Serie zu starten.'**
  String get streakNone;

  /// No description provided for @previousPeriod.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Zeitraum'**
  String get previousPeriod;

  /// No description provided for @nextPeriod.
  ///
  /// In de, this message translates to:
  /// **'Nächster Zeitraum'**
  String get nextPeriod;

  /// No description provided for @averagePerDay.
  ///
  /// In de, this message translates to:
  /// **'Durchschnitt pro Tag'**
  String get averagePerDay;

  /// No description provided for @periodNoMeals.
  ///
  /// In de, this message translates to:
  /// **'In diesem Zeitraum ist nichts eingetragen.'**
  String get periodNoMeals;

  /// No description provided for @proteinAveragePerDay.
  ///
  /// In de, this message translates to:
  /// **'Protein {average} von {target} g pro Tag'**
  String proteinAveragePerDay(int average, int target);

  /// No description provided for @burnPerDay.
  ///
  /// In de, this message translates to:
  /// **'etwa {kcal} kcal pro Tag'**
  String burnPerDay(int kcal);

  /// No description provided for @gramsProtein.
  ///
  /// In de, this message translates to:
  /// **'{grams} g Protein'**
  String gramsProtein(int grams);

  /// No description provided for @moreActions.
  ///
  /// In de, this message translates to:
  /// **'Weitere Aktionen'**
  String get moreActions;

  /// No description provided for @todayAt.
  ///
  /// In de, this message translates to:
  /// **'Heute, {time}'**
  String todayAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In de, this message translates to:
  /// **'Gestern, {time}'**
  String yesterdayAt(String time);

  /// No description provided for @portionLess.
  ///
  /// In de, this message translates to:
  /// **'Kleinere Portion'**
  String get portionLess;

  /// No description provided for @portionMore.
  ///
  /// In de, this message translates to:
  /// **'Größere Portion'**
  String get portionMore;

  /// No description provided for @portionEdit.
  ///
  /// In de, this message translates to:
  /// **'Portion eingeben'**
  String get portionEdit;

  /// No description provided for @confidenceShort.
  ///
  /// In de, this message translates to:
  /// **'Zu {percent} % sicher'**
  String confidenceShort(int percent);

  /// No description provided for @probablyBetween.
  ///
  /// In de, this message translates to:
  /// **'wahrscheinlich {low}–{high} kcal'**
  String probablyBetween(int low, int high);

  /// No description provided for @kcalLeftToday.
  ///
  /// In de, this message translates to:
  /// **'{kcal} kcal heute übrig'**
  String kcalLeftToday(int kcal);

  /// No description provided for @kcalOverToday.
  ///
  /// In de, this message translates to:
  /// **'{kcal} kcal über dem Ziel'**
  String kcalOverToday(int kcal);

  /// No description provided for @quickLogShort.
  ///
  /// In de, this message translates to:
  /// **'Eintippen'**
  String get quickLogShort;

  /// No description provided for @kcalPerDayPlan.
  ///
  /// In de, this message translates to:
  /// **'kcal pro Tag'**
  String get kcalPerDayPlan;

  /// No description provided for @proteinPerDayPlan.
  ///
  /// In de, this message translates to:
  /// **'{grams} g Protein pro Tag'**
  String proteinPerDayPlan(int grams);

  /// No description provided for @analysisNoConnection.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung zu Gemini. Prüfe dein Internet und versuche es erneut.'**
  String get analysisNoConnection;

  /// No description provided for @analysisRateLimited.
  ///
  /// In de, this message translates to:
  /// **'Gemini ist gerade ausgelastet. Bitte gleich nochmal versuchen.'**
  String get analysisRateLimited;

  /// No description provided for @analysisFailed.
  ///
  /// In de, this message translates to:
  /// **'Analyse fehlgeschlagen. Bitte erneut versuchen.'**
  String get analysisFailed;

  /// No description provided for @hapticsTest.
  ///
  /// In de, this message translates to:
  /// **'Haptik testen'**
  String get hapticsTest;

  /// No description provided for @hapticsTestIntro.
  ///
  /// In de, this message translates to:
  /// **'Tippe jede Zeile an und hake an, was du gespürt hast. Schick mir dann einen Screenshot. 0 ist der echte iOS-Schalter: Spürst du dort nichts, gibt das iPhone gar keine Schalter-Haptik aus (z. B. Systemhaptik in den Einstellungen aus).'**
  String get hapticsTestIntro;

  /// No description provided for @hapticsTestNative.
  ///
  /// In de, this message translates to:
  /// **'iOS-Schalter von Hand'**
  String get hapticsTestNative;

  /// No description provided for @hapticsTestFelt.
  ///
  /// In de, this message translates to:
  /// **'gespürt'**
  String get hapticsTestFelt;
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
