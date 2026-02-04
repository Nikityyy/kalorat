import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
              backgroundColor: const Color(0xFFFFF2F4), // lavenderBlush
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.energy_savings_leaf,
                      size: 80,
                      color: AppColors.shamrock,
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(color: AppColors.shamrock),
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
              home: homeWidget,
            );
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Kalorat',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: homeWidget,
          );
        },
      ),
    );
  }
}
