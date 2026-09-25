import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/app_shell.dart';
import 'shared/repositories/nursery_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(isOptional: true);
  runApp(const ProviderScope(child: SmartRiceNurseryApp()));
}

class SmartRiceNurseryApp extends StatelessWidget {
  const SmartRiceNurseryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ORYZA SMART',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppEntry(),
    );
  }
}

class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  AuthUser? _user;

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user != null) {
      return AppShell(
        user: user,
        onLogout: () async {
          await ref.read(nurseryRepositoryProvider).logout();
          if (mounted) setState(() => _user = null);
        },
      );
    }
    return LoginScreen(
      onLogin: (email, password) async {
        final user = await ref
            .read(nurseryRepositoryProvider)
            .login(email: email, password: password);
        if (mounted) setState(() => _user = user);
      },
    );
  }
}
