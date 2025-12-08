import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../../../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      drawer: const AppDrawer(currentRoute: '/settings'),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Karanlık Mod'),
            value: isDark,
            onChanged: (v) => themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Sürüm'),
            subtitle: Text('SA HOCAM'),
          )
        ],
      ),
    );
  }
}
