import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../core/app_theme.dart';
import '../core/auth_store.dart';
import '../models/app_user.dart';
import '../widgets/common.dart';
import 'vehicle_list_screen.dart';

/// Profile tab: who is signed in, shortcuts, and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to book a charger.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.full),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    // AuthGate listens to the store and swaps back to the login screen.
    if (confirmed == true) await AuthStore.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.instance.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _IdentityCard(user: user),
          const SizedBox(height: 22),

          const SectionHeader(title: 'Account'),
          Card(
            child: Column(
              children: [
                _Tile(
                  icon: Icons.electric_car_rounded,
                  title: 'My vehicles',
                  subtitle: 'Add, edit or remove an EV',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VehicleListScreen()),
                  ),
                ),
                const Divider(height: 1),
                _Tile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  subtitle: user?.email ?? '-',
                ),
                const Divider(height: 1),
                _Tile(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  subtitle: user?.phone ?? 'Not added',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const SectionHeader(title: 'About'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                children: [
                  const InfoRow(label: 'App', value: 'FleetX prototype'),
                  const InfoRow(label: 'Version', value: '0.1.0 (demo)'),
                  InfoRow(
                    label: 'Data source',
                    value: ApiConfig.useMockData
                        ? 'Local demo data'
                        : ApiConfig.baseUrl,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.full,
              minimumSize: const Size(0, 52),
              side: const BorderSide(color: AppTheme.full),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user?.initial ?? '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'Guest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role ?? 'DRIVER',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.neutral),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12.5, color: AppTheme.neutral),
      ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppTheme.neutral),
    );
  }
}
