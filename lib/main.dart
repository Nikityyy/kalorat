import 'package:flutter/material.dart';

import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge for modern UI
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await Supabase.initialize(
    url: 'https://likdthixmzuugbtgrdqz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxpa2R0aGl4bXp1dWdidGdyZHF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0NjEzMTQsImV4cCI6MjA4NjAzNzMxNH0.E2pe3eIM1QsL0bs5H9-nuf3ACRWdw4vr2rvGuZNNXHQ',
  );

  runApp(const KaloratApp());
}

class KaloratApp extends StatelessWidget {
  const KaloratApp({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityProvider(
      child: ChangeNotifierProvider(
        create: (_) => AppProvider()..init(),
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            Widget homeWidget;
            if (!provider.isInitialized) {
              homeWidget = Scaffold(
                backgroundColor: AppColors.limestone,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/kalorat-favicon-android.webp',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      const CircularProgressIndicator(
                        color: AppColors.styrianForest,
                      ),
                    ],
                  ),
                ),
              );
            } else if (provider.isOnboardingCompleted) {
              homeWidget = const MainScreen();
            } else {
              homeWidget = const OnboardingFlow();
            }

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Kalorat',
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown,
                },
              ),
              theme: AppTheme.lightTheme,
              themeMode: ThemeMode.light, // Force light mode
              locale: Locale(provider.language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: homeWidget,
              builder: (context, child) {
                // Ensure text scale factor is capped for consistency
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.noScaling),
                  child: child!,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
