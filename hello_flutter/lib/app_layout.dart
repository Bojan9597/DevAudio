import 'package:flutter/material.dart';
import 'widgets/side_menu.dart';
import 'widgets/content_area.dart';
import 'states/layout_state.dart';
import 'l10n/generated/app_localizations.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => globalLayoutState.toggleMenu(),
                child: Text(
                  AppLocalizations.of(context)!.categories,
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => globalLayoutState.setCategoryId('library'),
                icon: Icon(
                  Icons.library_books,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                label: Text(
                  AppLocalizations.of(context)!.library,
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => globalLayoutState.setCategoryId('profile'),
                icon: Icon(
                  Icons.person,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
                label: Text(
                  AppLocalizations.of(context)!.profile,
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
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
