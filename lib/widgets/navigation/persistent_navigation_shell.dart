import 'package:flutter/material.dart';

import 'navigation_scope.dart';
import 'user_bottom_navigation_bar.dart';

typedef TourFlowTabBuilder = Widget Function(BuildContext context);
typedef TourFlowBottomBarBuilder =
    Widget Function(
      BuildContext context,
      int selectedIndex,
      ValueChanged<int> onItemSelected,
    );

class TourFlowPersistentNavigationShell extends StatefulWidget {
  const TourFlowPersistentNavigationShell({
    required this.items,
    required this.tabBuilders,
    required this.bottomBarBuilder,
    this.initialIndex = 0,
    super.key,
  }) : assert(items.length == tabBuilders.length),
       assert(initialIndex >= 0 && initialIndex < items.length);

  final List<TourFlowNavigationItem> items;
  final List<TourFlowTabBuilder> tabBuilders;
  final TourFlowBottomBarBuilder bottomBarBuilder;
  final int initialIndex;

  @override
  State<TourFlowPersistentNavigationShell> createState() =>
      _TourFlowPersistentNavigationShellState();
}

class _TourFlowPersistentNavigationShellState
    extends State<TourFlowPersistentNavigationShell> {
  late int _selectedIndex;
  late final List<Widget?> _tabs;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabs = List<Widget?>.filled(widget.tabBuilders.length, null);
  }

  void _selectTab(int index) {
    if (index < 0 || index >= _tabs.length || index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    _tabs[_selectedIndex] ??= widget.tabBuilders[_selectedIndex](context);

    return Scaffold(
      body: TourFlowNavigationScope(
        selectedIndex: _selectedIndex,
        itemCount: _tabs.length,
        onItemSelected: _selectTab,
        child: IndexedStack(
          index: _selectedIndex,
          children: List.generate(
            _tabs.length,
            (index) => _tabs[index] ?? const SizedBox.shrink(),
          ),
        ),
      ),
      bottomNavigationBar: widget.bottomBarBuilder(
        context,
        _selectedIndex,
        _selectTab,
      ),
    );
  }
}
