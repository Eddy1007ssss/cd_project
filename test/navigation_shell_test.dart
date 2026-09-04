import 'package:cd_project/widgets/navigation/persistent_navigation_shell.dart';
import 'package:cd_project/widgets/navigation/staff_bottom_navigation_bar.dart';
import 'package:cd_project/widgets/navigation/user_bottom_navigation_bar.dart';
import 'package:cd_project/widgets/navigation/user_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tabs initialize lazily and preserve their state', (
    tester,
  ) async {
    final initializedTabs = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: _testShell(
          initializedTabs: initializedTabs,
          tabBuilders: List.generate(
            userNavigationItems.length,
            (index) =>
                (_) => _CounterTab(index: index),
          ),
        ),
      ),
    );

    expect(initializedTabs, [0]);
    await tester.tap(find.byKey(const Key('increment-0')));
    await tester.pump();
    expect(find.text('Count 1'), findsOneWidget);

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();
    expect(initializedTabs, [0, 1]);
    expect(find.byKey(const Key('tab-1')), findsOneWidget);
    expect(find.byType(UserBottomNavigationBar), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(initializedTabs, [0, 1]);
    expect(find.text('Count 1'), findsOneWidget);
  });

  testWidgets('top-level sidebar items switch the existing shell', (
    tester,
  ) async {
    final initializedTabs = <int>[];
    final builders = List<TourFlowTabBuilder>.generate(
      userNavigationItems.length,
      (index) =>
          (_) => _CounterTab(index: index),
    );
    builders[0] = (_) => const _DrawerTab();

    await tester.pumpWidget(
      MaterialApp(
        home: _testShell(
          initializedTabs: initializedTabs,
          tabBuilders: builders,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discover Attractions'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tab-1')), findsOneWidget);
    expect(find.byType(TourFlowPersistentNavigationShell), findsOneWidget);
  });

  testWidgets('an initial index opens the matching legacy destination', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _testShell(
          initialIndex: 3,
          tabBuilders: List.generate(
            userNavigationItems.length,
            (index) =>
                (_) => _CounterTab(index: index),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('tab-3')), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
  });

  testWidgets('detail routes return to the preserved shell tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _testShell(
          tabBuilders: List.generate(
            userNavigationItems.length,
            (index) =>
                (_) => _CounterTab(index: index),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('increment-0')));
    await tester.tap(find.byKey(const Key('detail-0')));
    await tester.pumpAndSettle();
    expect(find.text('Detail page'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('Count 1'), findsOneWidget);
    expect(find.byType(UserBottomNavigationBar), findsOneWidget);
  });

  testWidgets('staff navigation also switches inside one shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TourFlowPersistentNavigationShell(
          items: operatorNavigationItems,
          tabBuilders: List.generate(
            operatorNavigationItems.length,
            (index) =>
                (_) => _CounterTab(index: index),
          ),
          bottomBarBuilder: (_, selectedIndex, onItemSelected) =>
              OperatorBottomNavigationBar(
                selectedIndex: selectedIndex,
                onItemSelected: onItemSelected,
              ),
        ),
      ),
    );

    await tester.tap(find.text('Slots'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tab-2')), findsOneWidget);
    expect(find.byType(OperatorBottomNavigationBar), findsOneWidget);
  });
}

Widget _testShell({
  int initialIndex = 0,
  List<int>? initializedTabs,
  required List<TourFlowTabBuilder> tabBuilders,
}) {
  return TourFlowPersistentNavigationShell(
    items: userNavigationItems,
    initialIndex: initialIndex,
    tabBuilders: List.generate(tabBuilders.length, (index) {
      return (context) {
        initializedTabs?.add(index);
        return tabBuilders[index](context);
      };
    }),
    bottomBarBuilder: (_, selectedIndex, onItemSelected) =>
        UserBottomNavigationBar(
          selectedIndex: selectedIndex,
          onItemSelected: onItemSelected,
        ),
  );
}

class _CounterTab extends StatefulWidget {
  const _CounterTab({required this.index});

  final int index;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('tab-${widget.index}'),
      body: Column(
        children: [
          Text('Tab ${widget.index}'),
          Text('Count $count'),
          FilledButton(
            key: Key('increment-${widget.index}'),
            onPressed: () => setState(() => count++),
            child: const Text('Increment'),
          ),
          OutlinedButton(
            key: Key('detail-${widget.index}'),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Detail page')),
              ),
            ),
            child: const Text('Open detail'),
          ),
        ],
      ),
    );
  }
}

class _DrawerTab extends StatelessWidget {
  const _DrawerTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: UserSidebar(
        displayName: 'Test Tourist',
        email: 'tourist@example.com',
        selectedIndex: 0,
        onLogout: () {},
      ),
      body: const Text('Drawer tab'),
    );
  }
}
