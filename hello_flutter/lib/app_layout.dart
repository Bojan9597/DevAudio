import 'package:flutter/material.dart';
import 'widgets/side_menu.dart';
import 'widgets/content_area.dart';
import 'states/layout_state.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => globalLayoutState.toggleMenu(),
                child: const Text(
                  'Categories',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => globalLayoutState.setCategoryId('library'),
                icon: const Icon(Icons.library_books, color: Colors.white),
                label: const Text(
                  'Library',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => globalLayoutState.setCategoryId('profile'),
                icon: const Icon(Icons.person, color: Colors.white),
                label: const Text(
                  'Profile',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListenableBuilder(
        listenable: globalLayoutState,
        builder: (context, child) {
          return Stack(
            children: [
              // 1. Content Area (Background)
              const Positioned.fill(child: ContentArea()),

              // 2. Scrim (Click to close)
              if (!globalLayoutState.isCollapsed)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => globalLayoutState.toggleMenu(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.black.withOpacity(0.5)),
                  ),
                ),

              // 3. Side Menu (Foreground Overlay)
              const Positioned(left: 0, top: 0, bottom: 0, child: SideMenu()),
            ],
          );
        },
      ),
    );
  }
}
