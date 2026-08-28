import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'core/auth_store.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const FleetXApp());
}

class FleetXApp extends StatelessWidget {
  const FleetXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FleetX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}

/// Swaps between the app and the login screen whenever the session changes.
///
/// Also unwinds any pushed routes on logout, so a 401 deep inside the booking
/// flow still lands the user cleanly back on the login screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthStore _store = AuthStore.instance;
  late bool _wasLoggedIn = _store.isLoggedIn;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final isLoggedIn = _store.isLoggedIn;
    if (_wasLoggedIn && !isLoggedIn && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    _wasLoggedIn = isLoggedIn;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _store.isLoggedIn ? const HomeShell() : const LoginScreen();
  }
}
