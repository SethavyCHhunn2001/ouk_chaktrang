import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/lobby_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/rules_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const OukApp());
}

class OukApp extends StatelessWidget {
  const OukApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ouk Chaktrang',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      LobbyScreen(onLearn: () => setState(() => _i = 1)),
      const RulesScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _i, children: pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: C.surfaceLow,
          indicatorColor: C.primary.withValues(alpha: .18),
          labelTextStyle: WidgetStatePropertyAll(TextStyle(
              fontSize: 11, color: C.onVar, fontWeight: FontWeight.w600)),
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? C.primary : C.outline)),
        ),
        child: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.sports_esports_outlined), label: 'Lobby'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined), label: 'Learn'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
