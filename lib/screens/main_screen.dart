import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
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

  final List<Widget> _screens = const [
    MeScreen(),
    HomeScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.language;

    if (Platform.isIOS) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          activeColor: AppColors.shamrock,
          inactiveColor: AppColors.carbonBlack.withValues(alpha: 0.5),
          backgroundColor: AppColors.lavenderBlush.withValues(
            alpha: 0.8,
          ), // Translucent
          items: [
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.person_fill),
              label: lang == 'de' ? 'Ich' : 'Me',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _currentIndex == 1
                      ? AppColors.shamrock.withValues(alpha: 0.1)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.camera_fill, size: 28),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(CupertinoIcons.clock_fill),
              label: lang == 'de' ? 'Historie' : 'History',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          return CupertinoTabView(builder: (context) => _screens[index]);
        },
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.carbonBlack,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: AppColors.lavenderBlush,
          indicatorColor: AppColors.shamrock, // Shamrock for active indicator
          surfaceTintColor: Colors.transparent,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(
                Icons.person,
                color: Colors.white,
              ), // White icon on Shamrock
              label: lang == 'de' ? 'Ich' : 'Me',
            ),
            NavigationDestination(
              icon: const Icon(Icons.camera_alt_outlined),
              selectedIcon: const Icon(Icons.camera_alt, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history, color: Colors.white),
              label: lang == 'de' ? 'Historie' : 'History',
            ),
          ],
        ),
      ),
    );
  }
}
