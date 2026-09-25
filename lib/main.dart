import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: SmartRiceNurseryApp()));
}

class SmartRiceNurseryApp extends StatelessWidget {
  const SmartRiceNurseryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Rice Nursery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return AppShell(onLogout: () => setState(() => _isLoggedIn = false));
    }
    return LoginScreen(onLogin: () => setState(() => _isLoggedIn = true));
  }
}
