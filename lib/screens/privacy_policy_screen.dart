import 'package:flutter/material.dart';
import '../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// One titled block of the privacy policy.
class PolicySection {
  final String title;
  final String body;

  const PolicySection(this.title, this.body);
}

const privacyContactEmail = 'bergernikita1807@gmail.com';

/// The policy text. Kept next to the screen so it changes together with the
/// features it describes (what is stored, what leaves the device, and where).
List<PolicySection> privacyPolicySections(String language) =>
    language == 'de' ? _sectionsDe : _sectionsEn;

const _sectionsEn = [
  PolicySection(
    'Who is responsible',
    'Kalorat is published by Nikita Berger. This policy describes what the '
        'app does with your data.',
  ),
  PolicySection(
    'What stays on your device',
    'Your profile (name, birthdate, height, weight, goal, gender, activity '
        'level), your meals with their nutrition values, your meal photos, your '
        'weight log and your settings are stored on your device. In the web '
        'app, that is the storage of your browser for this site. Photos are '
        'kept as reduced copies and are never uploaded to a server of ours.',
  ),
  PolicySection(
    'Meal analysis with Gemini',
    'To analyse a meal, the app sends its photos and your optional note '
        'directly from your device to Google\'s Gemini API. You provide your '
        'own API key for this. There is no Kalorat server in between. Google '
        'processes the photos under its own terms for the Gemini API. If you do '
        'not want that, do not analyse meals with photos or add them manually.',
  ),
  PolicySection(
    'Your API key',
    'Your Gemini API key is stored on your device in secure storage (Keychain '
        'or Keystore in the native apps, the app\'s storage in the browser). It '
        'is sent only to Google, in a request header, to authorise your '
        'requests. It is never synced to the cloud.',
  ),
  PolicySection(
    'Account and cloud sync (optional)',
    'If you sign in with Google, your Google account email address is kept for '
        'sign-in, and your data is also stored with our backend provider, '
        'Supabase, so it can sync between your devices: your profile '
        '(name, birthdate, height, weight, language, goal, gender, activity '
        'level, day start, analysis mode and profile picture address), your '
        'meals (name, nutrition values, time, portion, notes) and your weight '
        'entries, plus records of what you deleted. Photos and your API key '
        'are not synced. Without an account, nothing is stored in the cloud.',
  ),
  PolicySection(
    'Health data (native apps only)',
    'If you allow it, the app writes the nutrition values of your meals and '
        'your weight to Apple Health or Health Connect. You can revoke this '
        'at any time in the system settings.',
  ),
  PolicySection(
    'Notifications',
    'Reminders are scheduled on your device. They do not use a server.',
  ),
  PolicySection(
    'What the app does not do',
    'Kalorat contains no advertising and no analytics or tracking tools. Your '
        'data is not sold or shared with third parties other than Google '
        '(meal analysis) and Supabase (account sync, only if you sign in).',
  ),
  PolicySection(
    'Your choices',
    'In Settings you can export all your data, import a backup, and delete '
        'your account, which removes your data from the cloud. Local data is '
        'removed by deleting the app, or by clearing the site data of the web '
        'app in your browser.',
  ),
  PolicySection(
    'Contact',
    'Questions about your data or this policy: $privacyContactEmail',
  ),
  PolicySection(
    'Changes',
    'If a new version changes what happens with your data, this policy is '
        'updated in the same version. Last updated: October 2026.',
  ),
];

const _sectionsDe = [
  PolicySection(
    'Wer verantwortlich ist',
    'Kalorat wird von Nikita Berger herausgegeben. Diese Erklärung '
        'beschreibt, was die App mit deinen Daten macht.',
  ),
  PolicySection(
    'Was auf deinem Gerät bleibt',
    'Dein Profil (Name, Geburtsdatum, Größe, Gewicht, Ziel, Geschlecht, '
        'Aktivitätslevel), deine Mahlzeiten mit Nährwerten, deine '
        'Mahlzeitenfotos, dein Gewichtsverlauf und deine Einstellungen werden '
        'auf deinem Gerät gespeichert. In der Web-App ist das der Speicher '
        'deines Browsers für diese Seite. Fotos werden als verkleinerte Kopien '
        'gespeichert und nie auf einen Server von uns hochgeladen.',
  ),
  PolicySection(
    'Mahlzeitenanalyse mit Gemini',
    'Für die Analyse einer Mahlzeit sendet die App die Fotos und deine '
        'optionale Notiz direkt von deinem Gerät an die Gemini-API von Google. '
        'Den API-Schlüssel dafür stellst du selbst bereit. Es gibt keinen '
        'Kalorat-Server dazwischen. Google verarbeitet die Fotos nach eigenen '
        'Bedingungen für die Gemini-API. Wenn du das nicht möchtest, analysiere '
        'keine Mahlzeiten mit Fotos oder trage sie manuell ein.',
  ),
  PolicySection(
    'Dein API-Schlüssel',
    'Dein Gemini-API-Schlüssel wird auf deinem Gerät im sicheren Speicher '
        'abgelegt (Keychain oder Keystore in den nativen Apps, der '
        'App-Speicher im Browser). Er wird nur an Google gesendet, in einem '
        'Anfrage-Header, um deine Anfragen zu autorisieren. Er wird nie in die '
        'Cloud synchronisiert.',
  ),
  PolicySection(
    'Konto und Cloud-Sync (optional)',
    'Wenn du dich mit Google anmeldest, wird die E-Mail-Adresse deines '
        'Google-Kontos für die Anmeldung gespeichert, und deine Daten werden '
        'zusätzlich bei unserem Backend-Anbieter Supabase gespeichert, damit '
        'sie zwischen deinen Geräten synchronisiert werden: dein Profil (Name, '
        'Geburtsdatum, Größe, Gewicht, Sprache, Ziel, Geschlecht, '
        'Aktivitätslevel, Tagesbeginn, Analysemodus und Adresse des '
        'Profilbilds), deine Mahlzeiten (Name, Nährwerte, Zeit, Portion, '
        'Notizen) und deine Gewichtseinträge, dazu Vermerke über Gelöschtes. '
        'Fotos und dein API-Schlüssel werden nicht synchronisiert. Ohne Konto '
        'wird nichts in der Cloud gespeichert.',
  ),
  PolicySection(
    'Gesundheitsdaten (nur native Apps)',
    'Wenn du es erlaubst, schreibt die App die Nährwerte deiner Mahlzeiten '
        'und dein Gewicht in Apple Health oder Health Connect. Du kannst das '
        'jederzeit in den Systemeinstellungen widerrufen.',
  ),
  PolicySection(
    'Benachrichtigungen',
    'Erinnerungen werden auf deinem Gerät geplant. Dafür wird kein Server '
        'verwendet.',
  ),
  PolicySection(
    'Was die App nicht tut',
    'Kalorat enthält keine Werbung und keine Analyse- oder Tracking-Werkzeuge. '
        'Deine Daten werden nicht verkauft und nicht an Dritte weitergegeben, '
        'außer an Google (Mahlzeitenanalyse) und Supabase (Konto-Sync, nur wenn '
        'du dich anmeldest).',
  ),
  PolicySection(
    'Deine Möglichkeiten',
    'In den Einstellungen kannst du alle Daten exportieren, ein Backup '
        'importieren und dein Konto löschen, wodurch deine Daten aus der Cloud '
        'entfernt werden. Lokale Daten entfernst du, indem du die App löschst '
        'oder in deinem Browser die Websitedaten der Web-App löschst.',
  ),
  PolicySection(
    'Kontakt',
    'Fragen zu deinen Daten oder dieser Erklärung: $privacyContactEmail',
  ),
  PolicySection(
    'Änderungen',
    'Wenn eine neue Version ändert, was mit deinen Daten passiert, wird diese '
        'Erklärung in derselben Version angepasst. Stand: Oktober 2026.',
  ),
];

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = privacyPolicySections(
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyPolicy), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          for (final section in sections) ...[
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(section.title, style: AppTypography.titleLarge),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.slate,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
