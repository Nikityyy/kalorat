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
  /// **'Dein persönlicher Kalorientracker'**
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
  /// **'Home'**
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
  /// **'Mahlzeit analysieren'**
  String get analyzeMeal;

  /// No description provided for @analyzing.
  ///
  /// In de, this message translates to:
  /// **'Analysiere...'**
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
  /// **'Noch keine Gewichtsdaten vorhanden'**
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
