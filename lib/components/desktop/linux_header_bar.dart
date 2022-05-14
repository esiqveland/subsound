import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaita/libadwaita.dart';
import 'package:libadwaita_core/libadwaita_core.dart';

class ViewSwitcherEntry {
  final ViewSwitcherData data;
  final WidgetBuilder builder;
  final Function(BuildContext) goto;

  ViewSwitcherEntry({
    required this.data,
    required this.builder,
    required this.goto,
  });
}

class LinuxHeaderBar extends StatelessWidget {
  final List<ViewSwitcherEntry> tabs;
  final int currentIndex;
  final Function(int) onSwitchedTab;

  const LinuxHeaderBar({
    Key? key,
    required this.tabs,
    required this.currentIndex,
    required this.onSwitchedTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdwHeaderBar(
      actions: AdwActions(),
      start: [AdwHeaderButton(
        icon: const Icon(Icons.view_sidebar, size: 15),
        isActive: false,
        onPressed: () {
          //_flapController.toggle();
        },
      )],
      title: AdwViewSwitcher(
        currentIndex: currentIndex,
        onViewChanged: onSwitchedTab,
        tabs: tabs.map((e) => e.data).toList(growable: false),
      ),
      end: [GtkPopupMenu(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () {},
              title: const Text(
                'Force reload',
                style: TextStyle(fontSize: 13),
              ),
            ),
            ListTile(
              onTap: () {},
              title: const Text(
                'Settings',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),],
    );
  }
}
