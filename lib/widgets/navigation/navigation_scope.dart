import 'package:flutter/widgets.dart';

class TourFlowNavigationScope extends InheritedWidget {
  const TourFlowNavigationScope({
    required this.selectedIndex,
    required this.itemCount,
    required this.onItemSelected,
    required super.child,
    super.key,
  });

  final int selectedIndex;
  final int itemCount;
  final ValueChanged<int> onItemSelected;

  static TourFlowNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TourFlowNavigationScope>();
  }

  @override
  bool updateShouldNotify(TourFlowNavigationScope oldWidget) {
    return selectedIndex != oldWidget.selectedIndex;
  }
}

void selectNavigationTabOrPush(
  BuildContext context, {
  required int index,
  required String routeName,
}) {
  final scope = TourFlowNavigationScope.maybeOf(context);
  if (scope != null) {
    scope.onItemSelected(index);
    return;
  }
  Navigator.pushNamed(context, routeName);
}
