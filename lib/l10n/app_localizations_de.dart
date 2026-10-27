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
  String get onboardingName => 'Wie heißt du?';

  @override
  String get onboardingNameHint => 'Dein Name';

  @override
  String get settings => 'Einstellungen';

  @override
  String get profile => 'Profil';

  @override
  String get age => 'Alter';

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
  String get analyzeMeal => 'Mahlzeit checken';

  @override
  String get analyzing => 'Analysiere …';

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
  String get offlineMessage =>
      'Du bist offline. Die AI wird die Mahlzeit analysieren, sobald du wieder online bist und die App öffnest.';

  @override
  String get pendingAnalysis => 'Ausstehende Analysen';

  @override
  String get processingQueue => 'Ausstehende Mahlzeiten werden verarbeitet …';

  @override
  String get analysisWaitingForResume =>
      'Wartet darauf, dass Kalorat fortgesetzt wird';

  @override
  String get analysisFailedTapToRetry =>
      'Analyse fehlgeschlagen · zum Wiederholen tippen';

  @override
  String analysisRetrying(int attempt) {
    return 'Neuer Versuch ($attempt/3)';
  }

  @override
  String get today => 'Heute';

  @override
  String get day => 'Tag';

  @override
  String get week => 'Woche';

  @override
  String get month => 'Monat';

  @override
  String get year => 'Jahr';

  @override
  String get addWeight => 'Gewicht eintragen';

  @override
  String get language => 'Sprache';

  @override
  String get apiKey => 'API-Key';

  @override
  String get apiKeyInfo => 'API-Key von ai.dev eintragen oder ändern.';

  @override
  String get exportData => 'Daten exportieren';

  @override
  String get exportMarkdown => 'Markdown exportieren';

  @override
  String get reportTitle => 'Kalorat - Ernährungsbericht';

  @override
  String get reportGeneratedOn => 'Erstellt am';

  @override
  String get reportUserProfile => 'Benutzerprofil';

  @override
  String get reportGoal => 'Ziel';

  @override
  String get reportActivityLevel => 'Aktivitätslevel';

  @override
  String get reportDailyCalories => 'Tägliches Kalorienziel';

  @override
  String get reportDailyProtein => 'Tägliches Proteinziel';

  @override
  String get reportDailyCarbs => 'Tägliches Kohlenhydrateziel';

  @override
  String get reportDailyFats => 'Tägliches Fettziel';

  @override
  String get reportWeight => 'Gewicht';

  @override
  String get reportDailyLog => 'Tagesprotokoll';

  @override
  String get reportNoMeals => '*Keine Mahlzeiten aufgezeichnet.*';

  @override
  String get reportDailyTotal => 'Tagesgesamt';

  @override
  String get reportUnnamedMeal => 'Unbenannte Mahlzeit';

  @override
  String get importData => 'Daten importieren';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get mealReminders => 'Mahlzeit-Erinnerungen';

  @override
  String get weightReminders => 'Gewichts-Erinnerungen';

  @override
  String get appBadge => 'Zähler am App-Symbol';

  @override
  String get appBadgeHint =>
      'Zeigt, wie viele Mahlzeiten noch auf ihre Analyse warten.';

  @override
  String get appBadgeDenied =>
      'Erlaube Mitteilungen für Kalorat in den Einstellungen deines Geräts, dann zeigt das App-Symbol den Zähler.';

  @override
  String get grantPermission => 'Berechtigung erteilen';

  @override
  String get startOnboarding => 'Onboarding starten';

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
  String get data => 'Daten';

  @override
  String get importSuccessful => 'Import erfolgreich';

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String get buildingPlan => 'Profil wird gespeichert …';

  @override
  String get nameValidationError => 'Bitte gib deinen Namen ein';

  @override
  String get logYourWeight => 'Gewicht eintragen';

  @override
  String get weightReminderBody => 'Gewicht von heute erfassen.';

  @override
  String get mealReminderTitle => 'Erinnerung: Mahlzeit';

  @override
  String get mealReminderBody => 'Mahlzeit erfassen.';

  @override
  String get loseWeight => 'Abnehmen';

  @override
  String get maintainWeight => 'Gewicht halten';

  @override
  String get gainMuscle => 'Muskeln aufbauen';

  @override
  String get male => 'Männlich';

  @override
  String get female => 'Weiblich';

  @override
  String healthyRange(String min, String max) {
    return 'Gesunder Bereich: $min - $max kg';
  }

  @override
  String get status => 'Status';

  @override
  String get proteinShort => 'Eiw.';

  @override
  String get carbsShort => 'KH';

  @override
  String get fatsShort => 'Fett';

  @override
  String get logWeight => 'Gewicht loggen';

  @override
  String get noDataAvailable => 'Keine Daten verfügbar';

  @override
  String get noFoodDetected => 'Kein Essen erkannt. Bitte versuche es erneut.';

  @override
  String get deleteQuestion => 'Löschen?';

  @override
  String get deleteMealConfirmation =>
      'Möchtest du diese Mahlzeit wirklich löschen?';

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
  String get reorderPhotosHint =>
      'Halten und ziehen, um die Reihenfolge zu ändern';

  @override
  String get coverPhoto => 'Titelbild';

  @override
  String get movePhotoEarlier => 'Nach vorne';

  @override
  String get movePhotoLater => 'Nach hinten';

  @override
  String get startAnalysis => 'Analyse starten';

  @override
  String get yourDescription => 'Deine Beschreibung';

  @override
  String get yourNote => 'Deine Notiz';

  @override
  String get saveMeal => 'Eintrag loggen';

  @override
  String get welcomeSlogan => 'Kalorien, präzise getrackt.';

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
  String get calculateMetabolicRate => 'Um deinen Grundumsatz zu berechnen.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get whatIsYourGoal => 'Was ist dein Ziel?';

  @override
  String get burnFatSubtitle => 'Kaloriendefizit';

  @override
  String get maintainSubtitle => 'Kalorienbalance';

  @override
  String get buildMassSubtitle => 'Kalorienüberschuss';

  @override
  String get aiConfigure => 'AI Konfigurieren';

  @override
  String get goTo => 'Gehe zu ';

  @override
  String get createKeyInstruction =>
      ' und erstelle einen kostenlosen Key. Kopiere ihn, füge ihn hier ein und starte das Tracking.';

  @override
  String get preferences => 'Einstellungen';

  @override
  String get integrations => 'Integrationen';

  @override
  String get accountAndData => 'Konto & Daten';

  @override
  String get enterApiKeyError => 'Bitte gib einen API-Key ein';

  @override
  String get invalidApiKeyError =>
      'Ungültiger API-Key. Bitte überprüfe deine Eingabe.';

  @override
  String get validateAndContinue => 'Validieren & Weiter';

  @override
  String get nameSubtitle => 'Wird in deinem Profil angezeigt.';

  @override
  String get cm => 'cm';

  @override
  String get kg => 'kg';

  @override
  String get kcal => 'kcal';

  @override
  String get grams => 'g';

  @override
  String get weightSaved => 'Gewicht gespeichert';

  @override
  String get editMealName => 'Mahlzeitnamen bearbeiten';

  @override
  String get editCalories => 'Kalorien bearbeiten';

  @override
  String get date => 'Datum';

  @override
  String get healthSyncEnabled => 'Mit Gesundheit synchronisieren';

  @override
  String get syncMeals => 'Mahlzeiten synchronisieren';

  @override
  String get syncWeight => 'Gewicht synchronisieren';

  @override
  String get healthConnected => 'Verbunden';

  @override
  String get healthConnectNotInstalled =>
      'Health Connect App nicht installiert';

  @override
  String get healthPermissionDenied => 'Gesundheitsberechtigungen verweigert';

  @override
  String get healthOnboardingTitle => 'Gesundheit verbinden';

  @override
  String get healthOnboardingDescription =>
      'Ernährung und Gewicht mit der Gesundheits-App deines Geräts synchronisieren.';

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
  String get logOut => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountConfirm =>
      'Bist du sicher? Alle deine Daten werden unwiderruflich gelöscht.';

  @override
  String get guestMode => 'Gastmodus';

  @override
  String get loginToSync => 'Anmelden um Daten zu synchronisieren';

  @override
  String get syncComplete => 'Synchronisierung abgeschlossen';

  @override
  String get accountDeleted => 'Konto gelöscht';

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
      'Heute sind schon 15 Mahlzeiten erfasst, das Tageslimit. Fasse kleine Snacks zu einer Mahlzeit zusammen.';

  @override
  String get rateLimitPhotos =>
      'Maximum erreicht. Limit von 5 Fotos pro Mahlzeit.';

  @override
  String get legal => 'Rechtliches';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

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
  String get streak => 'Serie';

  @override
  String get discardPhotos => 'Fotos verwerfen?';

  @override
  String get discardPhotosConfirm =>
      'Deine aufgenommenen Fotos gehen verloren.';

  @override
  String get cameraNotAvailableWeb => 'Kamera nicht verfügbar.';

  @override
  String get useGalleryInstead =>
      'Kamerazugriff erlauben oder Galerie verwenden.';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updateReady => 'Neue Version verfügbar.';

  @override
  String get reloadButton => 'Neu laden';

  @override
  String get laterButton => 'Später';

  @override
  String get mealContextTitle => 'Noch etwas hinzufügen?';

  @override
  String get mealContextHint =>
      'z. B. Vanillepudding, 200 g, Angaben von der Packung';

  @override
  String get mealContextSkip => 'Ohne Hinweis';

  @override
  String get mealContextAnalyze => 'Analysieren';

  @override
  String get mealContextBackground => 'Im Hintergrund';

  @override
  String get mealSavedBackground =>
      'Gespeichert. Die Analyse startet, sobald du online bist.';

  @override
  String get mealAnalysingBackground =>
      'Wird analysiert. Das Ergebnis erscheint gleich unter Heute.';

  @override
  String get saveToGallery => 'Foto speichern';

  @override
  String get saveToGallerySuccess => 'Foto in Galerie gespeichert';

  @override
  String get saveToGalleryError => 'Foto konnte nicht gespeichert werden.';

  @override
  String get dayStartsAt => 'Tag beginnt um';

  @override
  String get dayStartsAtHint =>
      'Mahlzeiten, die vor dieser Uhrzeit gespeichert werden, zählen zum Vortag';

  @override
  String get analysisTimedOut =>
      'Gemini hat nicht rechtzeitig geantwortet. Bitte erneut versuchen.';

  @override
  String get reference => 'Referenz';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String showAllWeights(int count) {
    return 'Alle $count Gewichte anzeigen';
  }

  @override
  String get editWeight => 'Gewicht bearbeiten';

  @override
  String get weightRangeError =>
      'Bitte ein Gewicht zwischen 20 und 400 kg eingeben.';

  @override
  String get largeWeightJump => 'Großer Gewichtssprung';

  @override
  String confirmWeightJump(String previous, String next) {
    return 'Änderung von $previous auf $next kg speichern?';
  }

  @override
  String weeklyDifference(String difference) {
    return '7-Tage-Differenz: $difference kg';
  }

  @override
  String get switchCamera => 'Kamera wechseln';

  @override
  String get flash => 'Blitz';

  @override
  String get flashUnavailable => 'Blitz nicht verfügbar';

  @override
  String get analysisUpdated => 'Analyse aktualisiert';

  @override
  String analysisConfidence(int percent) {
    return 'KI-Sicherheit: $percent%';
  }

  @override
  String get retryAnalysis => 'Analyse neu starten';

  @override
  String get syncData => 'Daten synchronisieren';

  @override
  String get downloadStarted => 'Download gestartet';

  @override
  String get restoreImportBackup => 'Letztes Import-Backup wiederherstellen';

  @override
  String get backupRestored => 'Backup wiederhergestellt.';

  @override
  String get close => 'Schließen';

  @override
  String get aBitAboutYou => 'Über dich';

  @override
  String get biologicalSex => 'Biologisches Geschlecht';

  @override
  String get yourMeasurements => 'Deine Maße';

  @override
  String get planReady => 'Plan berechnet';

  @override
  String get basedOnProfile => 'Basierend auf deinem Profil.';

  @override
  String get dailyCalorieTarget => 'Tägliches Kalorienziel';

  @override
  String get signUpToSave =>
      'Du kannst das in den Einstellungen ändern und dich dort anmelden, um deine Daten zu sichern.';

  @override
  String get createAccount => 'Weiter';

  @override
  String get cameraGuideText => 'Mahlzeit oder Barcode im Rahmen zentrieren.';

  @override
  String get apiKeyUnreachable => 'Google nicht erreichbar. Verbindung prüfen.';

  @override
  String get appVersion => 'Version';

  @override
  String get offlineShort => 'Offline';

  @override
  String get gramModeTitle => 'Gramm-Modus';

  @override
  String get gramModeSubtitle => 'Gramm statt Portionen anzeigen';

  @override
  String get accurateModeTitle => 'Genauigkeitsmodus';

  @override
  String get accurateModeSubtitle =>
      'Tiefere Analyse, genauer. Aus ist schneller.';

  @override
  String get gallery => 'Galerie';

  @override
  String get quickLogTitle => 'Schnell erfassen';

  @override
  String get quickLogHint =>
      'Beschreibe, was du gegessen hast, z. B. zwei Scheiben Toast mit Butter';

  @override
  String get offSearch => 'In Open Food Facts suchen';

  @override
  String get offSearchResults => 'Open Food Facts';

  @override
  String get offSearchNone =>
      'Keine Produkte mit Nährwerten gefunden. Versuch es mit Marke und Produktname.';

  @override
  String get offSearchFailed => 'Die Suche hat nicht geklappt. Bist du online?';

  @override
  String offPer100Ml(int kcal) {
    return '$kcal kcal pro 100 ml';
  }

  @override
  String get quickLogRecent => 'Nochmal essen';

  @override
  String get quickLogAgainAction => 'Nochmal erfassen';

  @override
  String quickLogLogged(String name) {
    return '$name erfasst';
  }

  @override
  String get quickLogUndo => 'Rückgängig';

  @override
  String get mealDeleted => 'Mahlzeit gelöscht';

  @override
  String get barcodeLookingUp => 'Produkt wird gesucht…';

  @override
  String get barcodeNotFound =>
      'Produkt nicht gefunden. Fotografiere stattdessen die Nährwerttabelle.';

  @override
  String barcodeNoNutrition(String name) {
    return 'Keine Nährwerte für $name. Fotografiere stattdessen die Nährwerttabelle.';
  }

  @override
  String get barcodeLookupFailed =>
      'Produkt konnte nicht gesucht werden. Fotografiere stattdessen die Nährwerttabelle.';

  @override
  String get barcodeLabelAction => 'Etikett fotografieren';

  @override
  String get barcodeLabelGuide => 'Fotografiere die Nährwerttabelle.';

  @override
  String barcodeLabelContext(String product) {
    return 'Nährwerttabelle von $product';
  }

  @override
  String barcodeSourceNote(String code) {
    return 'Nährwerte von Open Food Facts (Barcode $code).';
  }

  @override
  String get barcodeSwitchOn => 'Nährwerte von Open Food Facts verwenden';

  @override
  String get barcodeSwitchOff =>
      'Barcode ignoriert, das Foto wird als Mahlzeit analysiert';

  @override
  String get barcodeRetryHint =>
      'Ausschalten, um das Foto als Mahlzeit zu analysieren';

  @override
  String get retrySheetTitle => 'Analyse wiederholen';

  @override
  String get retrySheetSubtitle => 'Notiz für die KI, optional';

  @override
  String get retrySheetHint => 'z. B. 2 Portionen, extra Sauce';

  @override
  String get retryLeftoversTitle => 'Reste abziehen';

  @override
  String get retryLeftoversHint =>
      'Foto vom Rest auf dem Teller, er wird abgezogen.';

  @override
  String get retryLeftoversCamera => 'Rest fotografieren';

  @override
  String get retryLeftoversGallery => 'Aus Fotos';

  @override
  String retryLeftoversCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos vom Rest',
      one: '1 Foto vom Rest',
    );
    return '$_temp0';
  }

  @override
  String get retryLeftoversCountHint =>
      'Die Analyse zählt nur, was gegessen wurde.';

  @override
  String get retryLeftoversAddMore => 'Noch eins aufnehmen';

  @override
  String get retryLeftoverRemove => 'Foto entfernen';

  @override
  String get leftoversNeedOnline =>
      'Reste lassen sich nur abziehen, wenn die Analyse jetzt laufen kann. Entferne die Fotos vom Rest oder verbinde dich wieder.';

  @override
  String get photoTimeTitle => 'Zeit vom Foto';

  @override
  String get photoTimeOff => 'Jetzt';

  @override
  String get leftoversQuestion => 'Alles aufgegessen?';

  @override
  String get leftoversNone => 'Ja, alles';

  @override
  String get leftoversSome => 'Nein, Rest übrig';

  @override
  String get shareMeal => 'Teilen';

  @override
  String get shareMealTitle => 'Mahlzeit teilen';

  @override
  String get shareStylePhoto => 'Foto';

  @override
  String get shareStyleLight => 'Hell';

  @override
  String get shareStyleDark => 'Dunkel';

  @override
  String get shareImageAction => 'Bild teilen';

  @override
  String get shareSaveAction => 'In Fotos sichern';

  @override
  String get shareFailed => 'Das Bild konnte nicht geteilt werden.';

  @override
  String sharePhotoNumber(int number) {
    return 'Foto $number';
  }

  @override
  String get componentsTitle => 'Auf dem Teller';

  @override
  String get componentsTapToEdit => 'Tippen zum Ändern';

  @override
  String componentsTopShare(String first, String second, int percent) {
    return '$first und $second bringen $percent % der Kalorien';
  }

  @override
  String get componentEditHint => 'Menge ändern';

  @override
  String componentPer100(int kcal) {
    return '$kcal kcal pro 100 g';
  }

  @override
  String get componentSourceUsda => 'USDA';

  @override
  String get componentLess => 'Weniger';

  @override
  String get componentMore => 'Mehr';

  @override
  String componentMealNow(int kcal, int total) {
    return '$kcal kcal · Mahlzeit jetzt $total kcal';
  }

  @override
  String get componentRemove => 'Entfernen';

  @override
  String get componentApply => 'Übernehmen';

  @override
  String get analysisReadingPhoto => 'Foto wird gelesen';

  @override
  String get analysisReadingText => 'Beschreibung wird gelesen';

  @override
  String analysisParallel(int count) {
    return '$count Schätzungen laufen parallel';
  }

  @override
  String get analysisSingle => 'Eine schnelle Schätzung';

  @override
  String analysisComponentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Teile erkannt',
      one: '1 Teil erkannt',
    );
    return '$_temp0';
  }

  @override
  String get analysisAmounts => 'Mengen werden geschätzt';

  @override
  String analysisEstimateOf(int done, int total) {
    return 'Schätzung $done von $total';
  }

  @override
  String analysisSoFar(String values) {
    return 'Bisher $values kcal';
  }

  @override
  String analysisMedianOf(int count) {
    return 'Median aus $count Schätzungen';
  }

  @override
  String get analysisDone => 'Fertig geschätzt';

  @override
  String get retrySheetAction => 'Neu analysieren';

  @override
  String get analysisNoResult => 'Kein Ergebnis erhalten.';

  @override
  String get cameraDiagnosticsTitle => 'Kamera-Diagnose';

  @override
  String get cameraCanvasPreviewOn => 'Canvas-Vorschau: an';

  @override
  String get cameraCanvasPreviewOff => 'Canvas-Vorschau: aus';

  @override
  String get backupShareText => 'Kalorat-Backup';

  @override
  String get backupFailed =>
      'Das Backup konnte nicht erstellt werden. Versuch es noch einmal.';

  @override
  String get backupReminderTitle => 'Zeit für ein Backup';

  @override
  String get backupReminderNever =>
      'Deine Mahlzeiten liegen nur auf diesem Gerät und wurden noch nie gesichert. Ein Backup ist eine Datei, die du in Dateien oder iCloud ablegen kannst.';

  @override
  String backupReminderLast(int days) {
    return 'Deine Mahlzeiten liegen nur auf diesem Gerät. Letztes Backup vor $days Tagen.';
  }

  @override
  String get backupReminderAction => 'Jetzt sichern';

  @override
  String get backupReminderLater => 'Später';

  @override
  String get reportShareText => 'Kalorat-Markdown-Bericht';

  @override
  String get restoreBackupMissing => 'Kein Import-Backup vorhanden.';

  @override
  String get weeklyOnTarget => 'Im Ziel';

  @override
  String weeklyAboveTarget(String kcal) {
    return '$kcal kcal über dem Ziel';
  }

  @override
  String weeklyBelowTarget(String kcal) {
    return '$kcal kcal unter dem Ziel';
  }

  @override
  String weeklyDaysLogged(int count, int total) {
    return '$count von $total Tagen erfasst';
  }

  @override
  String get burnTitle => 'Geschätzter Tagesverbrauch';

  @override
  String burnBasis(int days, int weighIns) {
    return 'Aus $days erfassten Tagen und $weighIns Wiegungen der letzten 4 Wochen.';
  }

  @override
  String burnFormula(String kcal) {
    return 'Formel (Mifflin-St Jeor): $kcal kcal';
  }

  @override
  String burnNeedsData(int days, int weighIns) {
    return 'Für deinen echten Verbrauch braucht es mindestens 3 Wiegungen über 10 Tage und Mahlzeiten an den meisten dieser Tage. Bisher: $days Tage, $weighIns Wiegungen.';
  }

  @override
  String get burnImplausible =>
      'Die Werte passen nicht zusammen. Vermutlich fehlen Mahlzeiten oder Wiegungen.';

  @override
  String get burnDisclaimer =>
      'Eine Schätzung: Sie ist nur so genau wie deine erfassten Mahlzeiten und Wiegungen.';

  @override
  String get correctionLower => 'Weniger';

  @override
  String get correctionCurrent => 'Jetzt';

  @override
  String get correctionHigher => 'Mehr';

  @override
  String get validationInvalidMeal => 'Ungültige Mahlzeit.';

  @override
  String validationNegative(String field) {
    return '$field darf nicht negativ sein.';
  }

  @override
  String get validationNutrition => 'Unrealistische Nährwerte.';

  @override
  String get validationPortion => 'Unrealistische Portionsgröße.';

  @override
  String get validationPer100 => 'Ungültige Nährwerte pro 100 g.';

  @override
  String get validationMacrosPer100 =>
      'Makros pro 100 g dürfen 100 g nicht überschreiten.';

  @override
  String get validationWeightRange =>
      'Das Gewicht muss zwischen 20 und 400 kg liegen.';

  @override
  String get validationWeightFuture =>
      'Das Gewichtsdatum liegt in der Zukunft.';

  @override
  String get validationDuplicateMeals => 'Doppelte Mahlzeiten-IDs im Import.';

  @override
  String get hintGotIt => 'Verstanden';

  @override
  String get hintNotNow => 'Nicht jetzt';

  @override
  String get hintCameraTitle => 'Foto deiner Mahlzeit';

  @override
  String get hintCameraBody =>
      'Halte die Kamera auf deinen Teller und tippe auf den Auslöser. Vor der Analyse kannst du weitere Fotos, eine Notiz oder einen Barcode für Fertigprodukte hinzufügen.';

  @override
  String get hintBackupTitle => 'Sichere deine Mahlzeiten';

  @override
  String get hintBackupBody =>
      'Deine Daten liegen nur auf diesem Gerät. Mit Google anmelden sichert sie und macht sie auf anderen Geräten verfügbar.';

  @override
  String get hintBackupAction => 'Einstellungen öffnen';

  @override
  String get welcomeHaveAccount => 'Ich habe schon ein Konto';

  @override
  String get loginNewHere => 'Neu hier? Profil einrichten';

  @override
  String get themeTitle => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String todayWithDate(String date) {
    return 'Heute, $date';
  }

  @override
  String yesterdayWithDate(String date) {
    return 'Gestern, $date';
  }

  @override
  String get pickDay => 'Tag wählen';

  @override
  String get previousDay => 'Vorheriger Tag';

  @override
  String get nextDay => 'Nächster Tag';

  @override
  String kcalOfTarget(String target) {
    return 'kcal von $target';
  }

  @override
  String get kcalToEatToday => 'kcal für heute';

  @override
  String kcalLeftOf(String target) {
    return 'kcal übrig von $target';
  }

  @override
  String kcalOverTarget(String target) {
    return 'kcal über deinen $target';
  }

  @override
  String proteinOfTarget(int eaten, int target) {
    return '$eaten von $target g Protein';
  }

  @override
  String get proteinReached => 'Proteinziel erreicht';

  @override
  String proteinToGo(int grams) {
    return 'Noch $grams g Protein';
  }

  @override
  String mealsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mahlzeiten',
      one: '1 Mahlzeit',
    );
    return '$_temp0';
  }

  @override
  String mealsCountOfLimit(int count, int limit) {
    return '$count von $limit Mahlzeiten';
  }

  @override
  String get pastDayEmpty => 'An diesem Tag ist nichts eingetragen.';

  @override
  String get todayEmptyBody =>
      'Deine erste Mahlzeit beginnt den Aufstieg. Fotografiere den Teller, Kalorat erledigt den Rest.';

  @override
  String get openCamera => 'Kamera öffnen';

  @override
  String get tabCamera => 'Kamera';

  @override
  String get tabProgress => 'Fortschritt';

  @override
  String get bodyTitle => 'Körper';

  @override
  String streakLine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage in Folge eingetragen',
      one: '1 Tag in Folge eingetragen',
    );
    return '$_temp0';
  }

  @override
  String get streakNone => 'Trag heute etwas ein, um eine Serie zu starten.';

  @override
  String get previousPeriod => 'Vorheriger Zeitraum';

  @override
  String get nextPeriod => 'Nächster Zeitraum';

  @override
  String get averagePerDay => 'Durchschnitt pro Tag';

  @override
  String get periodNoMeals => 'In diesem Zeitraum ist nichts eingetragen.';

  @override
  String proteinAveragePerDay(int average, int target) {
    return 'Protein $average von $target g pro Tag';
  }

  @override
  String burnPerDay(int kcal) {
    return 'etwa $kcal kcal pro Tag';
  }

  @override
  String gramsProtein(int grams) {
    return '$grams g Protein';
  }

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String todayAt(String time) {
    return 'Heute, $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Gestern, $time';
  }

  @override
  String get portionLess => 'Kleinere Portion';

  @override
  String get portionMore => 'Größere Portion';

  @override
  String get portionEdit => 'Portion eingeben';

  @override
  String confidenceShort(int percent) {
    return 'Zu $percent % sicher';
  }

  @override
  String probablyBetween(int low, int high) {
    return 'wahrscheinlich $low–$high kcal';
  }

  @override
  String get quickLogShort => 'Eintippen';

  @override
  String get kcalPerDayPlan => 'kcal pro Tag';

  @override
  String proteinPerDayPlan(int grams) {
    return '$grams g Protein pro Tag';
  }

  @override
  String get analysisNoConnection =>
      'Keine Verbindung zu Gemini. Prüfe dein Internet und versuche es erneut.';

  @override
  String get analysisRateLimited =>
      'Gemini ist gerade ausgelastet. Bitte gleich nochmal versuchen.';

  @override
  String get analysisFailed =>
      'Analyse fehlgeschlagen. Bitte erneut versuchen.';
}
