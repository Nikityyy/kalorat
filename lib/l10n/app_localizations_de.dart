// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Kalorat';

  @override
  String get welcome => 'Willkommen bei Kalorat';

  @override
  String get welcomeSubtitle => 'Dein persönlicher Kalorientracker';

  @override
  String get next => 'Weiter';

  @override
  String get back => 'Zurück';

  @override
  String get done => 'Fertig';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get onboardingName => 'Wie heißt du?';

  @override
  String get onboardingNameHint => 'Dein Name';

  @override
  String get onboardingBirthdate => 'Wann bist du geboren?';

  @override
  String get onboardingHeight => 'Wie groß bist du?';

  @override
  String get onboardingHeightHint => 'Größe in cm';

  @override
  String get onboardingWeight => 'Wie viel wiegst du?';

  @override
  String get onboardingWeightHint => 'Gewicht in kg';

  @override
  String get onboardingLanguage => 'Sprache auswählen';

  @override
  String get onboardingApiKey => 'Gemini API-Key eingeben';

  @override
  String get onboardingApiKeyHint => 'API-Key';

  @override
  String get onboardingApiKeyInfo =>
      'API-Key von ai.dev eintragen. Gehe zu https://ai.dev → Konto → API Key erstellen → hier einfügen.';

  @override
  String get home => 'Start';

  @override
  String get me => 'Ich';

  @override
  String get history => 'Historie';

  @override
  String get settings => 'Einstellungen';

  @override
  String get profile => 'Profil';

  @override
  String get age => 'Alter';

  @override
  String get years => 'Jahre';

  @override
  String get height => 'Größe';

  @override
  String get weight => 'Gewicht';

  @override
  String get bmi => 'BMI';

  @override
  String get bmiUnderweight => 'Untergewicht';

  @override
  String get bmiNormal => 'Normalgewicht';

  @override
  String get bmiOverweight => 'Übergewicht';

  @override
  String get bmiObese => 'Adipositas';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get addMorePhotos => 'Weitere Fotos hinzufügen';

  @override
  String get analyzeMeal => 'Mahlzeit analysieren';

  @override
  String get analyzing => 'Analysiere...';

  @override
  String get mealName => 'Mahlzeit';

  @override
  String get calories => 'Kalorien';

  @override
  String get protein => 'Eiweiß';

  @override
  String get carbs => 'Kohlenhydrate';

  @override
  String get fats => 'Fett';

  @override
  String get vitamins => 'Vitamine';

  @override
  String get minerals => 'Mineralstoffe';

  @override
  String get manualEntry => 'Manuell eingeben';

  @override
  String get offlineMessage =>
      'Du bist offline. Die AI wird die Mahlzeit analysieren, sobald du wieder online bist und die App öffnest.';

  @override
  String get pendingAnalysis => 'Ausstehende Analysen';

  @override
  String get processingQueue => 'Verarbeite ausstehende Mahlzeiten...';

  @override
  String get today => 'Heute';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get thisMonth => 'Dieser Monat';

  @override
  String get thisYear => 'Dieses Jahr';

  @override
  String get day => 'Tag';

  @override
  String get week => 'Woche';

  @override
  String get month => 'Monat';

  @override
  String get year => 'Jahr';

  @override
  String get total => 'Gesamt';

  @override
  String get weightTracking => 'Gewichtsverlauf';

  @override
  String get addWeight => 'Gewicht eintragen';

  @override
  String get weightHistory => 'Gewichtsverlauf';

  @override
  String get noWeightData => 'Noch keine Gewichtsdaten vorhanden';

  @override
  String get statistics => 'Statistiken';

  @override
  String get noMealData => 'Noch keine Mahlzeiten erfasst';

  @override
  String get mealsLogged => 'Mahlzeiten erfasst';

  @override
  String get language => 'Sprache';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'English';

  @override
  String get apiKey => 'API-Key';

  @override
  String get apiKeyInfo => 'API-Key von ai.dev eintragen oder ändern.';

  @override
  String get exportData => 'Daten exportieren';

  @override
  String get importData => 'Daten importieren';

  @override
  String get exportSuccess => 'Daten erfolgreich exportiert';

  @override
  String get importSuccess => 'Daten erfolgreich importiert';

  @override
  String get importError => 'Fehler beim Importieren';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get mealReminders => 'Mahlzeit-Erinnerungen';

  @override
  String get weightReminders => 'Gewichts-Erinnerungen';

  @override
  String get confirmDelete => 'Wirklich löschen?';

  @override
  String get confirmDeleteMeal =>
      'Möchtest du diese Mahlzeit wirklich löschen?';

  @override
  String get cameraPermission => 'Kamera-Berechtigung wird benötigt';

  @override
  String get grantPermission => 'Berechtigung erteilen';

  @override
  String get name => 'Name';

  @override
  String get heightCm => 'Größe (cm)';

  @override
  String get weightKg => 'Gewicht (kg)';

  @override
  String get birthdate => 'Geburtsdatum';

  @override
  String ageYears(int age) {
    return '$age Jahre';
  }

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get saved => 'Gespeichert';

  @override
  String get data => 'Daten';

  @override
  String exported(String path) {
    return 'Exportiert: $path';
  }

  @override
  String get importSuccessful => 'Import erfolgreich';

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String get buildingPlan => 'Wir erstellen deinen Plan...';

  @override
  String get analyzingMetabolism => 'Metabolismus wird analysiert';

  @override
  String get apiKeyValidationError => 'Bitte einen gültigen API-Key eingeben';

  @override
  String analysisError(String error) {
    return 'Fehler bei der Analyse: $error';
  }

  @override
  String get mealSaved => 'Mahlzeit gespeichert';

  @override
  String get logYourWeight => 'Gewicht eintragen';

  @override
  String get weightReminderBody =>
      'Vergiss nicht, dein Gewicht heute einzutragen.';

  @override
  String get mealReminderTitle => 'Zeit zum Essen';

  @override
  String get mealReminderBody => 'Denk daran, deine Mahlzeit zu erfassen.';

  @override
  String get howOldAreYou => 'Wie alt bist du?';

  @override
  String get whatsYourGoal => 'Was ist dein Ziel?';

  @override
  String get loseWeight => 'Abnehmen';

  @override
  String get maintainWeight => 'Gewicht halten';

  @override
  String get gainMuscle => 'Muskeln aufbauen';

  @override
  String get whatsYourGender => 'Was ist dein Geschlecht?';

  @override
  String get male => 'Männlich';

  @override
  String get female => 'Weiblich';

  @override
  String get other => 'Divers';

  @override
  String get yourBmi => 'DEIN BMI';

  @override
  String get status => 'STATUS';

  @override
  String get weightProgress => 'Gewichtsverlauf';

  @override
  String get caloriesConsumed => 'KALORIEN AUFGENOMMEN';

  @override
  String get proteinShort => 'Eiw.';

  @override
  String get carbsShort => 'KH';

  @override
  String get fatsShort => 'Fett';

  @override
  String get reminders => 'Erinnerungen';

  @override
  String get logMeals => 'Mahlzeiten loggen';

  @override
  String get logMealsSubtitle => 'Morgens, Mittags, Abends';

  @override
  String get logWeight => 'Gewicht loggen';

  @override
  String get logWeightSubtitle => 'Tägliche Erinnerung';

  @override
  String get noDataAvailable => 'Keine Daten verfügbar';

  @override
  String get recentHistory => 'Verlauf der letzten Tage';

  @override
  String get noFoodDetected => 'Kein Essen erkannt. Bitte versuche es erneut.';

  @override
  String get myHistory => 'Meine Historie';

  @override
  String get noMealsRecorded => 'Noch keine Mahlzeiten erfasst';

  @override
  String get deleteQuestion => 'Löschen?';

  @override
  String get deleteMealConfirmation =>
      'Möchtest du diese Mahlzeit wirklich löschen?';

  @override
  String get analyzingMeal => 'Mahlzeit wird analysiert...';

  @override
  String get cameraNeeded => 'Kamera benötigt';

  @override
  String get cameraPermissionText =>
      'Damit Kalorat deine Mahlzeiten analysieren kann, benötigen wir Zugriff auf deine Kamera.';

  @override
  String get backToSelection => 'Zurück zur Auswahl';

  @override
  String get reviewPhotos => 'Fotos überprüfen';

  @override
  String get discard => 'Verwerfen';

  @override
  String get addPhoto => '+ Foto';

  @override
  String get startAnalysis => 'Analyse starten';

  @override
  String get analysisResult => 'Analyse Ergebnis';

  @override
  String get saveMeal => 'Speichern';

  @override
  String get welcomeSlogan => 'Kalorien, schön getrackt.';

  @override
  String get getStarted => 'Los geht\'s';

  @override
  String get genderLabel => 'Geschlecht';

  @override
  String get goalLabel => 'Ziel';

  @override
  String get geminiApiKeyLabel => 'Gemini API-Key';

  @override
  String get ok => 'OK';

  @override
  String get chooseGender => 'Wähle dein Geschlecht';

  @override
  String get calculateMetabolicRate => 'Um deinen Grundumsatz zu berechnen.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get whatIsYourGoal => 'Was ist dein Ziel?';

  @override
  String get burnFatSubtitle => 'Fett verbrennen';

  @override
  String get maintainSubtitle => 'Gesund & fit bleiben';

  @override
  String get buildMassSubtitle => 'Masse & Stärke';

  @override
  String get createPlan => 'Plan erstellen';

  @override
  String get aiConfigure => 'AI Konfigurieren';

  @override
  String get goTo => 'Gehe zu ';

  @override
  String get createKeyInstruction =>
      ' und erstelle einen kostenlosen Key. Kopiere ihn, füge ihn hier ein und tracke deine Kalorien.';

  @override
  String get enterApiKeyError => 'Bitte gib einen API-Key ein';

  @override
  String get invalidApiKeyError =>
      'Ungültiger API-Key. Bitte überprüfe deine Eingabe.';

  @override
  String get validateAndContinue => 'Validieren & Weiter';

  @override
  String get nameSubtitle => 'Wir möchten dich persönlich ansprechen.';

  @override
  String get cm => 'cm';

  @override
  String get kg => 'kg';

  @override
  String get kcal => 'kcal';

  @override
  String get grams => 'g';

  @override
  String get weightSaved => 'Gewicht gespeichert!';

  @override
  String get goalWeightLoss => 'Gewicht verlieren';

  @override
  String get goalMaintainWeight => 'Gewicht halten';

  @override
  String get goalMuscleGain => 'Muskeln aufbauen';

  @override
  String get date => 'Datum';
}
