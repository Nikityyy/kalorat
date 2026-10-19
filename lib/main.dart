import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'services/widget_service.dart';
import 'utils/haptics.dart';
import 'utils/rebuild_all.dart';
import 'widgets/common/browser_safe_area.dart';
import 'utils/splash_stub.dart'
    if (dart.library.js_interop) 'utils/splash_web.dart'
    as splash;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // The app is a single screen stack of its own. Without browser history, the
  // system edge-swipe cannot step "back" into an earlier page state (the
  // loading screen) on an iPhone home-screen app; in-app swipe-back and the
  // back arrows still work. Android keeps the history: its back button goes
  // through it, and without it back leaves the app from any screen.
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    setUrlStrategy(null);
  }
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetService.initialize();

  // Lock to portrait mode only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
  WidgetsBinding.instance.addPostFrameCallback((_) => Haptics.init());
}

/// Largest text size the layouts support.
const double maxTextScale = 1.5;

bool _splashHidden = false;

/// Fades the web splash out once the first real screen has been painted.
void _hideSplashOnce() {
  if (_splashHidden) return;
  _splashHidden = true;
  WidgetsBinding.instance.addPostFrameCallback((_) => splash.hideSplash());
}

class KaloratApp extends StatefulWidget {
  const KaloratApp({super.key});

  @override
  State<KaloratApp> createState() => _KaloratAppState();
}

class _KaloratAppState extends State<KaloratApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The system switched between light and dark.
  @override
  void didChangePlatformBrightness() => setState(() {});

  bool _isDark(ThemeMode mode) =>
      mode == ThemeMode.dark ||
      (mode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  /// Points the role colors at the theme in use. Widgets read them where they
  /// build, so everything already on screen is rebuilt when it changes.
  void _syncPalette(ThemeMode mode) {
    final dark = _isDark(mode);
    if (AppColors.isDark == dark) return;
    AppColors.setDark(dark);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) rebuildAll(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityProvider(
      child: ChangeNotifierProvider(
        create: (_) => AppProvider()..init(),
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            _syncPalette(provider.themeMode);
            Widget homeWidget;
            if (!provider.isInitialized) {
              // On the web the splash in index.html is the loading screen. A
              // second indicator here would show two during the hand-off.
              homeWidget = kIsWeb
                  ? Scaffold(backgroundColor: AppColors.canvas)
                  : Scaffold(
                      backgroundColor: AppColors.canvas,
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
                            CircularProgressIndicator(color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
            } else if (provider.isOnboardingCompleted) {
              homeWidget = const MainScreen();
            } else {
              homeWidget = const OnboardingFlow();
            }
            if (provider.isInitialized) _hideSplashOnce();

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Kalorat',
              // A drag on a list puts the keyboard away, as on both platforms.
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.unknown,
                },
              ),
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: provider.themeMode,
              locale: Locale(provider.language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: homeWidget,
              builder: (context, child) {
                // Follow the system text size, within limits the layouts are
                // built and checked for (see test/widgets/text_scale_test.dart).
                final media = MediaQuery.of(context);
                final icons = AppColors.isDark
                    ? Brightness.light
                    : Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                    statusBarIconBrightness: icons,
                    systemNavigationBarIconBrightness: icons,
                    statusBarBrightness: AppColors.isDark
                        ? Brightness.dark
                        : Brightness.light,
                  ),
                  child: MediaQuery(
                    data: media.copyWith(
                      textScaler: media.textScaler.clamp(
                        minScaleFactor: 1.0,
                        maxScaleFactor: maxTextScale,
                      ),
                    ),
                    child: BrowserSafeArea(child: child!),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
