import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shows warnings/errors via snackbar. Returns true when the future succeeded.
Future<bool> showBusy(
  BuildContext context, {
  required Future<void> Function() action,
  String? successMessage,
  String? busyLabel,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.of(context);
  final colorScheme = Theme.of(context).colorScheme;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
                color: colorScheme.primary, strokeWidth: 2.5),
            const SizedBox(width: 20),
            Expanded(child: Text(busyLabel ?? 'Working…')),
          ],
        ),
      ),
    ),
  );

  String? error;
  try {
    await action();
  } catch (e) {
    error = e.toString();
  }
  if (navigator.mounted) navigator.pop();

  if (error != null) {
    messenger.showSnackBar(SnackBar(content: Text(error)));
    return false;
  }
  if (successMessage != null) {
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
  }
  return true;
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? scheme.error : scheme.primary,
            foregroundColor: destructive ? scheme.onError : scheme.onPrimary,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
}