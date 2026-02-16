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
  String get welcomeSubtitle => 'Dein Begleiter am Berg.';

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
  String get analyzeMeal => 'Mahlzeit checken';

  @override
  String get analyzing => 'Prüfe...';

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
  String get noWeightData => 'Der Weg beginnt hier.';

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
  String get startOnboarding => 'Onboarding starten';

  @override
  String get meTitle => 'Profil';

  @override
  String get deleteWeight => 'Gewicht löschen?';

  @override
  String get deleteWeightConfirm =>
      'Möchtest du diesen Eintrag wirklich löschen?';

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
  String get analyzingMetabolism => 'Dein Stoffwechsel wird analysiert';

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
  String get loseWeight => 'Gesundes Tempo';

  @override
  String get maintainWeight => 'Pfad halten';

  @override
  String get gainMuscle => 'Kraft aufbauen';

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
  String healthyRange(String min, String max) {
    return 'Gesunder Bereich: $min - $max kg';
  }

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
  String get reminders => 'Impulse';

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
  String get noMealsRecorded => 'Dein Journal ist leer.';

  @override
  String get deleteQuestion => 'Löschen?';

  @override
  String get deleteMealConfirmation =>
      'Möchtest du diese Mahlzeit wirklich löschen?';

  @override
  String get analyzingMeal => 'Mahlzeit wird geprüft...';

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
  String get saveMeal => 'Eintrag loggen';

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
  String get chooseGender => 'Welches Geschlecht hast du?';

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
  String get editMealName => 'Mahlzeitnamen bearbeiten';

  @override
  String get editCalories => 'Kalorien bearbeiten';

  @override
  String get date => 'Datum';

  @override
  String get healthIntegration => 'Gesundheitsintegration';

  @override
  String get healthSyncEnabled => 'Mit Gesundheit synchronisieren';

  @override
  String get healthSyncDescription =>
      'Teile Ernährungs- und Gewichtsdaten mit Apple Health oder Google Health Connect.';

  @override
  String get connectHealth => 'Verbinden';

  @override
  String get disconnectHealth => 'Trennen';

  @override
  String get syncMeals => 'Mahlzeiten synchronisieren';

  @override
  String get syncWeight => 'Gewicht synchronisieren';

  @override
  String get healthConnected => 'Verbunden';

  @override
  String get healthNotConnected => 'Nicht verbunden';

  @override
  String get healthConnectNotInstalled =>
      'Health Connect App nicht installiert';

  @override
  String get healthPermissionDenied => 'Gesundheitsberechtigungen verweigert';

  @override
  String get healthSyncSuccess => 'Mit Gesundheits-App synchronisiert';

  @override
  String get healthOnboardingTitle => 'Gesundheit verbinden';

  @override
  String get healthOnboardingDescription =>
      'Synchronisiere deine Ernährungs- und Gewichtsdaten mit der Gesundheits-App deines Geräts für einen vollständigen Überblick.';

  @override
  String get healthOnboardingBenefit1 => 'Automatisches Mahlzeiten-Logging';

  @override
  String get healthOnboardingBenefit2 => 'Gewicht über Apps synchronisieren';

  @override
  String get healthOnboardingBenefit3 => 'Einheitliches Gesundheits-Dashboard';

  @override
  String get connectNow => 'Jetzt verbinden';

  @override
  String get skipForNow => 'Später einrichten';

  @override
  String syncWith(String appName) {
    return 'Mit $appName synchronisieren';
  }

  @override
  String get connected => 'Verbunden';

  @override
  String get disconnected => 'Getrennt';

  @override
  String get healthConnectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get loginSubtitle =>
      'Synchronisiere deine Daten auf all deinen Geräten';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get continueAsGuest => 'Als Gast fortfahren';

  @override
  String get guestWarning =>
      'Gastdaten werden nur lokal gespeichert und können nicht wiederhergestellt werden, wenn du das Gerät wechselst.';

  @override
  String get account => 'Konto';

  @override
  String loggedInAs(String email) {
    return 'Angemeldet als $email';
  }

  @override
  String get logOut => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountConfirm =>
      'Bist du sicher? Alle deine Daten werden unwiderruflich gelöscht.';

  @override
  String get requestData => 'Meine Daten anfordern';

  @override
  String get guestMode => 'Gastmodus';

  @override
  String get loginToSync => 'Anmelden um Daten zu synchronisieren';

  @override
  String get syncComplete => 'Synchronisierung abgeschlossen';

  @override
  String get accountDeleted => 'Konto gelöscht';

  @override
  String get dataExported => 'Daten exportiert';

  @override
  String get accountSection => 'Deine Daten werden nur lokal gespeichert';

  @override
  String get settingsSaved => 'Einstellungen gespeichert';

  @override
  String get logOutConfirm => 'Möchtest du dich wirklich abmelden?';

  @override
  String get loggedOut => 'Erfolgreich abgemeldet';

  @override
  String get error => 'Fehler';

  @override
  String get rateLimitMeals =>
      'Der Guide sagt: Ruh dich etwas aus, du hast heute genug getrackt.';

  @override
  String get rateLimitPhotos => 'Der Guide sagt: Pack leicht. 5 Fotos genügen.';

  @override
  String get legal => 'Rechtliches';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get featureOnlyInApp => 'Nur in der App';

  @override
  String get healthNotAvailableWeb =>
      'Die Gesundheitsintegration erfordert die native App';

  @override
  String get activityLevel => 'Aktivitätslevel';

  @override
  String get sedentary => 'Sitzend';

  @override
  String get lightlyActive => 'Leicht aktiv';

  @override
  String get moderatelyActive => 'Moderat aktiv';

  @override
  String get activeLevel => 'Aktiv';

  @override
  String get veryActive => 'Sehr aktiv';

  @override
  String get activityLevelSubtitle =>
      'Für die Berechnung deines Kalorienbedarfs.';

  @override
  String get sedentarySubtitle => 'Büroarbeit, wenig Bewegung';

  @override
  String get lightlyActiveSubtitle => 'Leichte Aktivität, 1-3x pro Woche';

  @override
  String get moderatelyActiveSubtitle => 'Sport 3-5x pro Woche';

  @override
  String get activeSubtitle => 'Sport 6-7x pro Woche';

  @override
  String get veryActiveSubtitle => 'Schwere körperliche Arbeit';

  @override
  String get dailyAvg => 'ø / Tag';

  @override
  String get streak => 'Serie';

  @override
  String streakDays(int count) {
    return '$count Tage';
  }

  @override
  String get discardPhotos => 'Fotos verwerfen?';

  @override
  String get discardPhotosConfirm =>
      'Deine aufgenommenen Fotos gehen verloren.';

  @override
  String get selectDate => 'Datum wählen';

  @override
  String get cameraNotAvailableWeb => 'Kamera im Browser nicht verfügbar.';

  @override
  String get useGalleryInstead =>
      'Nutze die Galerie unten, um Fotos auszuwählen.';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updateReady =>
      'Eine neue Version von Kalorat ist bereit. Jetzt aktualisieren für die neuesten Features.';

  @override
  String get reloadButton => 'Neu laden';

  @override
  String get laterButton => 'Später';
}
