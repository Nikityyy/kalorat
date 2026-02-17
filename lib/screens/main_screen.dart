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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Start at Home (center)
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = const [
    MeScreen(),
    HomeScreen(),
    HistoryScreen(),
  ];

  void _onSwipe(DragEndDetails details) {
    // Minimum velocity threshold to register a swipe
    const double minVelocity = 200.0;
    final velocity = details.primaryVelocity ?? 0;

    if (velocity > minVelocity) {
      // Swiped right → go to previous tab
      if (_currentIndex > 0) {
        setState(() => _currentIndex -= 1);
      }
    } else if (velocity < -minVelocity) {
      // Swiped left → go to next tab
      if (_currentIndex < _screens.length - 1) {
        setState(() => _currentIndex += 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // PopScope prevents system back from navigating to onboarding
    return PopScope(canPop: false, child: _buildBody(l10n));
  }

  Widget _buildBody(dynamic l10n) {
    if (PlatformUtils.isIOS) {
      return GestureDetector(
        onHorizontalDragEnd: _onSwipe,
        behavior: HitTestBehavior.translucent,
        child: CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
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
          Consumer<AppProvider>(
            builder: (context, provider, _) {
              if (provider.updateAvailable) {
                return MaterialBanner(
                  backgroundColor: AppColors.styrianForest,
                  content: Text(
                    l10n.updateReady,
                    style: const TextStyle(color: AppColors.pebble),
                  ),
                  leading: const Icon(
                    Icons.system_update,
                    color: AppColors.pebble,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => provider.performUpdate(),
                      child: Text(
                        l10n.reloadButton,
                        style: const TextStyle(
                          color: AppColors.pebble,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(), // Slide effect
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.slate,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.pebble);
            }
            return const IconThemeData(color: AppColors.slate);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          backgroundColor: AppColors.limestone,
          indicatorColor:
              AppColors.styrianForest, // Styrian Forest for active indicator
          surfaceTintColor: Colors.transparent,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(
                Icons.person,
                color: AppColors.pebble,
              ), // White icon on Shamrock
              label: l10n.me,
            ),
            NavigationDestination(
              icon: const Icon(Icons.camera_alt_outlined),
              selectedIcon: const Icon(
                Icons.camera_alt,
                color: AppColors.pebble,
              ),
              label: l10n.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history, color: AppColors.pebble),
              label: l10n.history,
            ),
          ],
        ),
      ),
    );
  }
}
