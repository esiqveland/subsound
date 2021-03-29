import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NavItems {
  final BottomNavigationBarItem item;
  final Function(BuildContext) handler;

  NavItems(this.item, this.handler);
}

class BottomNavigationBarWidget extends StatefulWidget {
  final List<NavItems> navItems;
  final Color backgroundColor;

  const BottomNavigationBarWidget({
    Key? key,
    required this.navItems,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  _BottomNavigationBarWidgetState createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int currentIndex;

  _BottomNavigationBarWidgetState({
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: widget.backgroundColor,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (idx) {
        setState(() {
          this.currentIndex = idx;
        });
        widget.navItems[idx].handler(context);
      },
      items: widget.navItems.map((item) => item.item).toList(),
    );
  }
}
