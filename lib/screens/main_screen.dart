import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/platform_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../extensions/l10n_extension.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'me_screen.dart';
import 'history_screen.dart';
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

  int _currentIndex = 1; // Start at Home (center)
  late final PageController _pageController;
  late final ValueNotifier<bool> _cameraTabActive;
  final Set<int> _swipePointers = {};
  Offset? _swipeStart;
  int? _swipePointer;
  bool _swipeCancelled = false;

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
    super.dispose();
  }

  List<Widget> get _screens => [
    const MeScreen(key: ValueKey('me')),
    HomeScreen(
      key: const ValueKey('home'),
      activeListenable: _cameraTabActive,
      pagingLock: _pagingLocked,
    ),
    const HistoryScreen(key: ValueKey('history')),
  ];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppProvider>().refreshReminderTimezone();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _swipePointers.add(event.pointer);
    if (_swipePointers.length == 1) {
      _swipeStart = event.position;
      _swipePointer = event.pointer;
      _swipeCancelled = false;
    } else {
      _swipeCancelled = true;
    }
  }

  void _handlePointerUp(PointerEvent event) {
    if (event.pointer == _swipePointer && !_swipeCancelled) {
      final delta = event.position - _swipeStart!;
      if (delta.dx.abs() >= 80 && delta.dx.abs() > delta.dy.abs() * 1.5) {
        final next = (_currentIndex + (delta.dx < 0 ? 1 : -1)).clamp(
          0,
          _screens.length - 1,
        );
        if (next != _currentIndex) {
          _cameraTabActive.value = next == 1;
          if (PlatformUtils.isIOS) {
            setState(() => _currentIndex = next);
          } else {
            _pageController.animateToPage(
              next,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      }
    }
    _swipePointers.remove(event.pointer);
    if (_swipePointers.isEmpty) {
      _swipeStart = null;
      _swipePointer = null;
      _swipeCancelled = false;
    }
  }

  Widget _withTabSwipe(Widget child) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _handlePointerDown,
    onPointerUp: _handlePointerUp,
    onPointerCancel: _handlePointerUp,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // PopScope prevents system back from navigating to onboarding
    return PopScope(canPop: false, child: _buildBody(l10n));
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

    if (PlatformUtils.isIOS) {
      return _withTabSwipe(
        CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            height: hideNavigation ? 0 : 50,
            currentIndex: _currentIndex,
            onTap: (index) {
              Haptics.tick();
              _cameraTabActive.value = index == 1;
              setState(() => _currentIndex = index);
            },
            activeColor: AppColors.styrianForest,
            inactiveColor: AppColors.slate.withValues(alpha: 0.5),
            backgroundColor: AppColors.limestone, // Strictly Matte
            items: [
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.person_fill),
                label: l10n.me,
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _currentIndex == 1
                        ? AppColors.styrianForest.withValues(alpha: 0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.camera_fill, size: 28),
                ),
                label: l10n.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.clock_fill),
                label: l10n.history,
              ),
            ],
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(builder: (context) => _screens[index]);
          },
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            // The page follows the finger, rubber-bands at the ends and settles
            // with the platform's scroll physics (iOS bounce on iPhone).
            child: ValueListenableBuilder<bool>(
              valueListenable: _pagingLocked,
              builder: (context, locked, _) => PageView(
                controller: _pageController,
                physics: locked ? const NeverScrollableScrollPhysics() : null,
                onPageChanged: (index) {
                  _cameraTabActive.value = index == 1;
                  if (!_navigating) Haptics.selection();
                  setState(() => _currentIndex = index);
                },
                children: _screens,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: hideNavigation
          ? null
          : NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.all(
                  TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate,
                  ),
                ),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return IconThemeData(color: AppColors.onPrimary);
                  }
                  return IconThemeData(color: AppColors.slate);
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  Haptics.tick();
                  _cameraTabActive.value = index == 1;
                  setState(() => _currentIndex = index);
                  _navigating = true;
                  _pageController
                      .animateToPage(
                        index,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      )
                      .whenComplete(() => _navigating = false);
                },
                backgroundColor: AppColors.limestone,
                indicatorColor: AppColors.styrianForest,
                surfaceTintColor: Colors.transparent,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.person_outline),
                    selectedIcon: Icon(
                      Icons.person,
                      color: AppColors.onPrimary,
                    ),
                    label: l10n.me,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.camera_alt_outlined),
                    selectedIcon: Icon(
                      Icons.camera_alt,
                      color: AppColors.onPrimary,
                    ),
                    label: l10n.home,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.history_outlined),
                    selectedIcon: Icon(
                      Icons.history,
                      color: AppColors.onPrimary,
                    ),
                    label: l10n.history,
                  ),
                ],
              ),
            ),
    );
  }
}
