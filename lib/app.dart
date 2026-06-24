import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/help_screen.dart';
import 'screens/journal_screen.dart';
import 'screens/proof_screen.dart';
import 'screens/report_screen.dart';
import 'screens/timer_screen.dart';

class RecruitProofApp extends StatefulWidget {
  const RecruitProofApp({super.key});

  @override
  State<RecruitProofApp> createState() => _RecruitProofAppState();
}

class _RecruitProofAppState extends State<RecruitProofApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF175CD3);
    return MaterialApp(
      title: 'RecruitProof',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _theme(Brightness.light, seed),
      darkTheme: _theme(Brightness.dark, seed),
      home: AppShell(
        themeMode: _themeMode,
        onThemeChanged: (value) => setState(() => _themeMode = value),
      ),
    );
  }

  ThemeData _theme(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: brightness == Brightness.light
          ? const Color(0xFFFAF9F6)
          : const Color(0xFF111318),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    required this.themeMode,
    required this.onThemeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    JournalScreen(),
    TimerScreen(),
    ProofScreen(),
    ReportScreen(),
  ];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book),
      label: 'Journal',
    ),
    NavigationDestination(
      icon: Icon(Icons.timer_outlined),
      selectedIcon: Icon(Icons.timer),
      label: 'Chrono',
    ),
    NavigationDestination(
      icon: Icon(Icons.attachment_outlined),
      selectedIcon: Icon(Icons.attachment),
      label: 'Preuves',
    ),
    NavigationDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: 'Rapport',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final content = IndexedStack(index: _index, children: _screens);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text('RecruitProof'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mode d’emploi',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: widget.themeMode == ThemeMode.dark
                ? 'Mode clair'
                : 'Mode sombre',
            onPressed: () => widget.onThemeChanged(
              widget.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: _destinations,
            ),
    );
  }
}
