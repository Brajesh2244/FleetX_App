import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/app_theme.dart';

/// Loads a future and renders exactly one of: spinner, error, or content.
///
/// Every data screen in the app goes through this so the loading / error /
/// empty states look and behave the same everywhere.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.pullToRefresh = true,
  });

  final Future<T> Function() load;

  /// Called with the loaded data and a callback that re-runs [load].
  final Widget Function(BuildContext context, T data, Future<void> Function() reload)
      builder;

  final bool pullToRefresh;

  @override
  State<AsyncView<T>> createState() => AsyncViewState<T>();
}

class AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  Future<void> reload() async {
    final next = widget.load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The FutureBuilder below renders the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(error: snapshot.error, onRetry: reload);
        }
        final content = widget.builder(context, snapshot.data as T, reload);
        if (!widget.pullToRefresh) return content;
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: reload,
          child: content,
        );
      },
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primary),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: const TextStyle(color: AppTheme.neutral)),
          ],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final Object? error;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final api = error is ApiException ? error as ApiException : null;
    final isNetwork = api?.isNetwork ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Icon(
          isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
          size: 56,
          color: AppTheme.full,
        ),
        const SizedBox(height: 16),
        Text(
          isNetwork ? 'Backend unreachable' : 'Something went wrong',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          api?.message ?? '$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.neutral, height: 1.4),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 46),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppTheme.neutral),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.neutral, height: 1.4),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(minimumSize: const Size(200, 46)),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small coloured pill used for availability, booking and payment statuses.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.color, this.icon});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppTheme.statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: tint),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              height: 7,
              width: 7,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: tint,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Label / value row used on detail and summary cards.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppTheme.neutral),
            const SizedBox(width: 8),
          ],
          Text(label, style: const TextStyle(color: AppTheme.neutral)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact metric tile for the dashboard and admin stats grid.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppTheme.primary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, color: AppTheme.neutral),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- feedback

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.full : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: error ? 4 : 2),
      ),
    );
}

/// Runs [action], showing any [ApiException] message in a snackbar.
/// Returns null when the call failed.
Future<T?> guard<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
    return null;
  } catch (e) {
    if (context.mounted) showSnack(context, '$e', error: true);
    return null;
  }
}

/// Same as [guard] for calls that return nothing. Returns true on success.
Future<bool> guardVoid(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on ApiException catch (e) {
    if (context.mounted) showSnack(context, e.message, error: true);
    return false;
  } catch (e) {
    if (context.mounted) showSnack(context, '$e', error: true);
    return false;
  }
}
