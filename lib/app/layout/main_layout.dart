import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String location;

  const MainLayout({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int get _currentIndex {
    if (widget.location.startsWith('/dashboard')) return 0;
    if (widget.location.startsWith('/evolution')) return 1;
    if (widget.location.startsWith('/history')) return 2;
    if (widget.location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/evolution');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.bomb),
              activeIcon: Icon(LucideIcons.bomb),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.trendingUp),
              activeIcon: Icon(LucideIcons.trendingUp),
              label: 'Evolution',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.scan),
              activeIcon: Icon(LucideIcons.scan),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              activeIcon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
