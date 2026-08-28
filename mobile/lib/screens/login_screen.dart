import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_theme.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.login(_email.text, _password.text);
      // AuthGate swaps to the app as soon as the store notifies.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _useDemo(String email, String password) {
    _email.text = email;
    _password.text = password;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Brand(),
                    const SizedBox(height: 32),
                    const Text(
                      'Welcome back',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sign in to book chargers and parking.',
                      style: TextStyle(color: AppTheme.neutral),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Email is required'
                          : (!v.contains('@') ? 'Enter a valid email' : null),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      _ErrorBanner(message: _error!),
                      const SizedBox(height: 12),
                    ] else
                      const SizedBox(height: 6),
                    FilledButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: AppTheme.neutral),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DemoCredentials(onPick: _useDemo),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.ev_station_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FleetX',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              'Smart Mobility & EV Charging',
              style: TextStyle(fontSize: 12, color: AppTheme.neutral),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.full.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.full.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: AppTheme.full),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.full,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seeded logins, so the demo can be opened without typing anything.
class _DemoCredentials extends StatelessWidget {
  const _DemoCredentials({required this.onPick});

  final void Function(String email, String password) onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science_outlined, size: 16, color: AppTheme.neutral),
                SizedBox(width: 6),
                Text(
                  'Demo accounts',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DemoChip(
                  label: 'Driver · ravi@fleetx.com',
                  onTap: () => onPick('ravi@fleetx.com', 'driver123'),
                ),
                _DemoChip(
                  label: 'Driver · priya@fleetx.com',
                  onTap: () => onPick('priya@fleetx.com', 'driver123'),
                ),
                _DemoChip(
                  label: 'Admin · admin@fleetx.com',
                  onTap: () => onPick('admin@fleetx.com', 'admin123'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: AppTheme.surfaceMuted,
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
