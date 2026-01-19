import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              );
            }
            return const TextStyle(color: Colors.grey);
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(index),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          backgroundColor: const Color(
            0xFFFDF5E6,
          ), // Cream background to match dialogs
          elevation: 3,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite, color: Color(0xFFC2185B)),
              label: 'Favoris',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view, color: Color(0xFF1B5E20)),
              label: 'Autre',
            ),
            NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style, color: Color(0xFF1B5E20)),
              label: 'Classic',
            ),
            NavigationDestination(
              icon: Icon(Icons.casino_outlined),
              selectedIcon: Icon(Icons.casino, color: Color(0xFF1B5E20)),
              label: 'Ludo',
            ),
            NavigationDestination(
              icon: Icon(Icons.blur_on),
              selectedIcon: Icon(Icons.blur_on, color: Color(0xFF1B5E20)),
              label: 'Awalé',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: Color(0xFF1B5E20)),
              label: 'Réglages',
            ),
          ],
        ),
      ),
    );
  }
}
