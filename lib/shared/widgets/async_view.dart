import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';

class AsyncView<T> extends ConsumerWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.builder,
    this.onRefresh,
    this.errorView,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext, T) builder;
  final Future<void> Function()? onRefresh;
  final Widget? errorView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (value) {
      AsyncData(:final value) => builder(context, value),
      AsyncError(:final error) =>
        errorView ??
        _Status(
            icon: Icons.cloud_off,
            title: error is ApiException ? error.message : 'Something went wrong',
            subtitle: error is ApiException ? ApiErrorKindTip.of(error.kind) : '$error',
            action: onRefresh == null
                ? null
                : () async {
                    await onRefresh!();
                  }),
      _ => onRefresh == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: onRefresh!,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
    };
  }
}

class ApiErrorKindTip {
  static String of(ApiErrorKind k) => switch (k) {
        ApiErrorKind.forbidden => 'Scope: token missing permissions'
            ' or API access disabled (self-hosted).',
        ApiErrorKind.unauthenticated => 'Check the token on your instance.',
        ApiErrorKind.rateLimited => 'Coolify rate limit hit — retry shortly.',
        _ => 'Pull to retry.',
      };
}

class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function()? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: action ?? () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 120, horizontal: 32),
            child: Column(
              children: [
                Icon(icon, size: 56, color: scheme.error),
                const SizedBox(height: 16),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}