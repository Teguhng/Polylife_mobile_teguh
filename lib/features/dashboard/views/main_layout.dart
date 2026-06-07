import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_ver/core/theme/app_theme_tokens.dart';
import 'package:mobile_ver/features/pengumuman/providers/pengumuman_provider.dart';
import 'package:mobile_ver/features/reminder/providers/upcoming_reminder_provider.dart';
import 'package:mobile_ver/features/todo/providers/todo_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKegiatanSilently(force: true);
      _refreshReminderSilently(force: true);
      _refreshTodoSilently();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshKegiatanSilently(force: true);
      _refreshReminderSilently(force: true);
      _refreshTodoSilently();
    }
  }

  Future<void> _refreshKegiatanSilently({bool force = false}) {
    return ref
        .read(pengumumanProvider.notifier)
        .fetchPengumuman(showLoader: false, force: force);
  }

  Future<void> _refreshReminderSilently({bool force = false}) {
    return ref
        .read(upcomingReminderProvider.notifier)
        .fetchReminder(showLoader: false, force: force);
  }

  Future<void> _refreshTodoSilently() {
    return ref.read(todoProvider.notifier).load();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/keuangan')) return 1;
    if (location.startsWith('/jadwal')) return 2;
    if (location.startsWith('/pengumuman')) return 3;
    if (location.startsWith('/todo')) return 4;
    if (location.startsWith('/catatan')) return 5;
    if (location.startsWith('/profile')) return -1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/keuangan');
        break;
      case 2:
        context.go('/jadwal');
        break;
      case 3:
        context.go('/pengumuman');
        break;
      case 4:
        context.go('/todo');
        break;
      case 5:
        context.go('/catatan');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final activeNavColor = context.appPrimary;
    final inactiveNavColor = context.appFaint;
    const items = <_BottomNavItem>[
      _BottomNavItem(
        label: 'Beranda',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _BottomNavItem(
        label: 'Keuangan',
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
      ),
      _BottomNavItem(
        label: 'Jadwal',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today_rounded,
      ),
      _BottomNavItem(
        label: 'Kegiatan',
        icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment_rounded,
      ),
      _BottomNavItem(
        label: 'To-Do',
        icon: Icons.checklist_rtl_outlined,
        activeIcon: Icons.checklist_rtl_rounded,
      ),
      _BottomNavItem(
        label: 'Catatan',
        icon: Icons.menu_rounded,
        activeIcon: Icons.menu,
      ),
    ];

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border(top: BorderSide(color: context.appBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 74,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _BottomNavButton(
                      item: items[i],
                      isSelected: selectedIndex == i,
                      activeColor: activeNavColor,
                      inactiveColor: inactiveNavColor,
                      onTap: () => _onItemTapped(i, context),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _BottomNavButton extends StatelessWidget {
  final _BottomNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
