import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'calendar_screen.dart';
import 'event_bank_screen.dart';
import 'converter_screen.dart';
import 'settings_screen.dart';
import 'add_event_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final pages = const [
      CalendarScreen(),
      EventBankScreen(),
      ConverterScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddEventScreen())),
              backgroundColor: AppColors.green,
              icon: const Text('✦', style: TextStyle(color: Colors.white, fontSize: 18)),
              label: Text(p.label('new_event'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: p.label('tab_calendar')),
          NavigationDestination(icon: const Icon(Icons.mosque_outlined),
              selectedIcon: const Icon(Icons.mosque),
              label: p.label('tab_bank')),
          NavigationDestination(icon: const Icon(Icons.swap_horiz_outlined),
              selectedIcon: const Icon(Icons.swap_horiz),
              label: p.label('tab_converter')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: p.label('tab_settings')),
        ],
      ),
    );
  }
}
