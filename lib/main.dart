import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaloratApp());
}

class KaloratApp extends StatelessWidget {
  const KaloratApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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
                      'assets/kalorat-favicon-ios.png',
                      width: 80,
                      height: 80,
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

          if (Platform.isIOS) {
            return CupertinoApp(
              debugShowCheckedModeBanner: false,
              title: 'Kalorat',
              theme: AppTheme.iosTheme,
              locale: Locale(provider.language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: homeWidget,
            );
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Kalorat',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: Locale(provider.language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: homeWidget,
          );
        },
      ),
    );
  }
}
