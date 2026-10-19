import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'package:flutter/material.dart';
import '../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'today_screen.dart';
import '../widgets/floating_tab_bar.dart';
import '../utils/haptics.dart';
import '../widgets/app_toast.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  bool _updateToastShown = false;
  // True while a tab tap drives the page animation, so the haptic for a swipe
  // is not repeated and the tab bar does not flicker through the pages in between.
  bool _navigating = false;
  // Set by the camera while two fingers pinch, so a pinch never pages.
  final ValueNotifier<bool> _pagingLocked = ValueNotifier(false);

  int _currentIndex = 1; // Opens on the camera, in the middle
  late final PageController _pageController;
  late final ValueNotifier<bool> _cameraTabActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);
    _cameraTabActive = ValueNotifier(_currentIndex == 1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _cameraTabActive.dispose();
    _pagingLocked.dispose();
    _dayRequest.dispose();
    _todayTabActive.dispose();
    _todayReselected.dispose();
    _progressReselected.dispose();
    super.dispose();
  }

  /// A day the Progress tab asked the Today tab to show.
  final ValueNotifier<DateTime?> _dayRequest = ValueNotifier(null);
  late final ValueNotifier<bool> _todayTabActive = ValueNotifier(
    _currentIndex == 0,
  );

  // Bumped when the shown tab is tapped again: it scrolls back to its top.
  final ValueNotifier<int> _todayReselected = ValueNotifier(0);
  final ValueNotifier<int> _progressReselected = ValueNotifier(0);

  late final List<Widget> _screens = [
    TodayScreen(
      key: const ValueKey('today'),
      activeListenable: _todayTabActive,
      dayRequest: _dayRequest,
      reselected: _todayReselected,
      onOpenCamera: () => _goTo(1),
    ),
    HomeScreen(
      key: const ValueKey('home'),
      activeListenable: _cameraTabActive,
      pagingLock: _pagingLocked,
    ),
    ProgressScreen(
      key: const ValueKey('progress'),
      reselected: _progressReselected,
      onOpenDay: (day) {
        _dayRequest.value = day;
        _goTo(0);
      },
    ),
  ];

  void _setActive(int index) {
    _cameraTabActive.value = index == 1;
    _todayTabActive.value = index == 0;
  }

  void _goTo(int index) {
    final from = _currentIndex;
    // The camera starts only once its page has settled: starting it during
    // the slide costs frames. Leaving it stops it at once.
    if (index == 1) {
      _todayTabActive.value = false;
    } else {
      _setActive(index);
    }
    setState(() => _currentIndex = index);
    // Today and Progress sit either side of the camera; sliding between them
    // would drag the live camera through the screen, so that tap switches
    // in place, like a tab bar does.
    if ((index - from).abs() > 1) {
      _navigating = true;
      _pageController.jumpToPage(index);
      _navigating = false;
      return;
    }
    _navigating = true;
    _pageController
        .animateToPage(
          index,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          _navigating = false;
          if (mounted && _currentIndex == index) _setActive(index);
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppProvider>().refreshReminderTimezone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Back on Today or Progress returns to the camera, where the app opens,
    // as Android apps do with their tabs; back on the camera leaves the app.
    // It never goes back to the onboarding.
    return PopScope(
      canPop: _currentIndex == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(1);
      },
      child: _buildBody(l10n),
    );
  }

  Widget _buildBody(dynamic l10n) {
    final provider = context.watch<AppProvider>();
    final hideNavigation = provider.isMealAnalysisActive;

    // Offer the update once, as a toast that moves nothing; Settings keeps a
    // permanent Reload row until the app is updated.
    if (provider.updateAvailable && !_updateToastShown) {
      _updateToastShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppToast.show(
          context,
          l10n.updateReady,
          actionLabel: l10n.reloadButton,
          onAction: provider.performUpdate,
          duration: const Duration(seconds: 10),
        );
      });
    }

    final media = MediaQuery.of(context);
    // The tab bar floats over the pages; the pages keep their content clear
    // of it through the bottom padding.
    final barSpace = hideNavigation ? 0.0 : FloatingTabBar.height + 12;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery(
              data: media.copyWith(
                padding: media.padding.copyWith(
                  bottom: media.padding.bottom + barSpace,
                ),
              ),
              // The page follows the finger, rubber-bands at the ends and
              // settles with the platform's scroll physics.
              child: ValueListenableBuilder<bool>(
                valueListenable: _pagingLocked,
                builder: (context, locked, _) => PageView(
                  controller: _pageController,
                  physics: locked ? const NeverScrollableScrollPhysics() : null,
                  onPageChanged: (index) {
                    // A tab tap already set the target page.
                    if (_navigating) return;
                    _setActive(index);
                    Haptics.selection();
                    setState(() => _currentIndex = index);
                  },
                  children: _screens,
                ),
              ),
            ),
          ),
          if (!hideNavigation)
            Positioned(
              left: 16,
              right: 16,
              bottom: media.padding.bottom + 8,
              child: FloatingTabBar(
                currentIndex: _currentIndex,
                onCamera: _currentIndex == 1,
                labels: [l10n.today, l10n.tabCamera, l10n.tabProgress],
                onTap: (index) {
                  Haptics.tick();
                  if (index != _currentIndex) {
                    _goTo(index);
                  } else if (index == 0) {
                    _todayReselected.value++;
                  } else if (index == 2) {
                    _progressReselected.value++;
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
