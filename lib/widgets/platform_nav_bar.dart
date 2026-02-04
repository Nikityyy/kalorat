import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PlatformNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String leftLabel;
  final String centerLabel;
  final String rightLabel;

  const PlatformNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.leftLabel,
    required this.centerLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        activeColor: CupertinoColors.activeBlue,
        inactiveColor: CupertinoColors.inactiveGray,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.person_fill),
            label: leftLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.camera_fill),
            label: centerLabel,
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.clock_fill),
            label: rightLabel,
          ),
        ],
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: leftLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.camera_alt_outlined),
          selectedIcon: const Icon(Icons.camera_alt),
          label: centerLabel,
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: rightLabel,
        ),
      ],
    );
  }
}
