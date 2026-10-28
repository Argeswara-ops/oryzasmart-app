import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/oryza_vision/presentation/screens/vision_screen.dart';
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
  bool _isGuest = false;
  bool _hasSeenOnboarding = false;
  bool _isRestoringSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final user = await ref.read(nurseryRepositoryProvider).restoreSession();
    if (!mounted) return;
    setState(() {
      _user = user;
      _hasSeenOnboarding = user != null;
      _isRestoringSession = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
    if (_isGuest) {
      return GuestVisionShell(
        onExitGuest: () => setState(() => _isGuest = false),
      );
    }
    if (!_hasSeenOnboarding) {
      return OnboardingScreen(
        onFinished: () => setState(() => _hasSeenOnboarding = true),
      );
    }
    return LoginScreen(
      onContinueAsGuest: () => setState(() => _isGuest = true),
      onLogin: (email, password) async {
        final user = await ref
            .read(nurseryRepositoryProvider)
            .login(email: email, password: password);
        if (mounted) setState(() => _user = user);
      },
    );
  }
}

class GuestVisionShell extends StatelessWidget {
  const GuestVisionShell({super.key, required this.onExitGuest});

  final VoidCallback onExitGuest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vision'),
            Text(
              'Mode tamu',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: onExitGuest,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Masuk'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const SafeArea(child: VisionScreen()),
    );
  }
}
