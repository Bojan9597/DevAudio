import 'package:flutter/material.dart';
import 'widgets/content_area.dart';
import 'widgets/mini_player.dart';
import 'widgets/side_menu.dart';
import 'states/layout_state.dart';
import 'l10n/generated/app_localizations.dart';

import 'dart:async';
import 'services/connectivity_service.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _connectivitySub = ConnectivityService().onOfflineChanged.listen((
      isOffline,
    ) {
      if (!mounted) return;

      final message = isOffline
          ? AppLocalizations.of(context)!.enteringOfflineMode
          : AppLocalizations.of(context)!.backOnline;
      final color = isOffline ? Colors.redAccent : Colors.green;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globalLayoutState,
      builder: (context, child) {
        // Map category ID to index for BottomNavigationBar
        int _selectedIndex = 0;
        final catId = globalLayoutState.selectedCategoryId;
        final isOnDiscover =
            catId == 'categories' ||
            (catId != 'home' && catId != 'library' && catId != 'profile');

        if (catId == 'categories')
          _selectedIndex = 0;
        else if (catId == 'home')
          _selectedIndex = 1;
        else if (catId == 'library')
          _selectedIndex = 2;
        else if (catId == 'profile')
          _selectedIndex = 3;
        else
          _selectedIndex = 0; // Any category selection goes to Discover tab
        // Index 0 is "Discover" (categories)

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            leading: isOnDiscover
                ? IconButton(
                    icon: Icon(
                      globalLayoutState.isCollapsed ? Icons.menu : Icons.close,
                      color: Theme.of(context).appBarTheme.foregroundColor,
                    ),
                    onPressed: () => globalLayoutState.toggleMenu(),
                    tooltip: AppLocalizations.of(context)!.categories,
                  )
                : null,
            title: Text(
              'DevAudio',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Stack(
            children: [
              // 1. Content Area (Background)
              const Positioned.fill(child: ContentArea()),

              // 2. Scrim (only when menu is open)
              if (!globalLayoutState.isCollapsed)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => globalLayoutState.toggleMenu(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.black.withOpacity(0.5)),
                  ),
                ),

              // 3. Side Menu
              const Positioned(left: 0, top: 0, bottom: 0, child: SideMenu()),
            ],
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini Player (above navigation bar)
              const MiniPlayer(),

              // Bottom Navigation Bar
              BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      globalLayoutState.setCategoryId('categories');
                      break;
                    case 1:
                      globalLayoutState.setCategoryId('home');
                      break;
                    case 2:
                      globalLayoutState.setCategoryId('library');
                      break;
                    case 3:
                      globalLayoutState.setCategoryId('profile');
                      break;
                  }
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.explore),
                    label: AppLocalizations.of(context)!.discover,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: AppLocalizations.of(context)!.home,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.library_books),
                    label: AppLocalizations.of(context)!.library,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.person),
                    label: AppLocalizations.of(context)!.profile,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
