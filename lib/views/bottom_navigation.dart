import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavigation({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    final routes = ['/feed', '/profile', '/events', '/jobs'];

    Navigator.pushNamedAndRemoveUntil(context, routes[index], (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Logic for "No Selection" (Chat Mode)
    final bool isUnselectedMode = currentIndex == -1;
    final int effectiveIndex = isUnselectedMode ? 0 : currentIndex;

    final Color selectedColor = isUnselectedMode
        ? (theme.bottomNavigationBarTheme.unselectedItemColor ?? Colors.grey)
        : (theme.bottomNavigationBarTheme.selectedItemColor ??
              theme.primaryColor);

    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        // If unselected mode, keep outlined icon even if "active"
        activeIcon: isUnselectedMode
            ? const Icon(Icons.home_outlined)
            : const Icon(Icons.home),
        label: 'Feed',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today),
        label: 'Events',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.business_center_outlined),
        activeIcon: Icon(Icons.business_center),
        label: 'Jobs',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomNavigationBarTheme.backgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: effectiveIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: selectedColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        showUnselectedLabels: true,
        items: items,
      ),
    );
  }
}
