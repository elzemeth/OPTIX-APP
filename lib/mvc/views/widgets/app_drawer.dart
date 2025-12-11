import 'package:flutter/material.dart';
import '../../controllers/auth_service.dart';
import '../../models/user.dart';
import '../../../main.dart';

class AppDrawer extends StatefulWidget {
  final String currentRoute;
  const AppDrawer({super.key, required this.currentRoute});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await AuthService().loadUserFromStorage();
      setState(() {
        _user = AuthService.currentUser;
      });
    } catch (e) {
      // TR: Hatayı sessizce ele al | EN: Handle error silently | RU: Обработать ошибку без вывода
    }
  }

  void _go(BuildContext context, String route) {
    if (route == widget.currentRoute) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_user?.fullName ?? _user?.username ?? 'Misafir Kullanıcı'),
              accountEmail: Text(_user?.email ?? 'Email Bulunamadı'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: _user?.avatarUrl != null 
                    ? NetworkImage(_user!.avatarUrl!) 
                    : null,
                child: _user?.avatarUrl == null 
                    ? const Icon(Icons.person) 
                    : null,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.tertiaryContainer,
                ]),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Ana Sayfa'),
              selected: widget.currentRoute == '/home',
              onTap: () => _go(context, '/home'),
            ),
            ListTile(
              leading: const Icon(Icons.timeline_outlined),
              title: const Text('OCR Sonuçları'),
              selected: widget.currentRoute == '/ocr/results',
              onTap: () => _go(context, '/ocr/results'),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text('İşlenmemiş OCR'),
              selected: widget.currentRoute == '/ocr/raw',
              onTap: () => _go(context, '/ocr/raw'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil'),
              selected: widget.currentRoute == '/profile',
              onTap: () => _go(context, '/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Ayarlar'),
              selected: widget.currentRoute == '/settings',
              onTap: () => _go(context, '/settings'),
            ),
            const Divider(),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Karanlık Mod'),
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (v) {
                themeMode.value = v ? ThemeMode.dark : ThemeMode.light;
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                await AuthService().logout();
                // ignore: use_build_context_synchronously
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
