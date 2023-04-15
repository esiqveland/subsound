import 'package:flutter/material.dart';

class NavItems {
  final BottomNavigationBarItem item;
  final Function(BuildContext) handler;

  NavItems(this.item, this.handler);
}

class BottomNavigationBarWidget extends StatefulWidget {
  final List<NavItems> navItems;
  final Color? backgroundColor;

  BottomNavigationBarWidget({
    Key? key,
    required this.navItems,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<BottomNavigationBarWidget> createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int currentIndex;

  _BottomNavigationBarWidgetState({
    this.currentIndex = 0,
  }) : super();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: widget.backgroundColor,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (idx) {
        setState(() {
          currentIndex = idx;
        });
        widget.navItems[idx].handler(context);
      },
      items: widget.navItems.map((item) => item.item).toList(),
    );
  }
}
