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
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => globalLayoutState.toggleMenu(),
        ),
        title: const Text('My App'),
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
