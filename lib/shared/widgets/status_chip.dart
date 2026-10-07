import 'package:flutter/material.dart';

import '../../core/utils/status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.compact = false});

  final ResourceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    if (compact) {
      return Tooltip(
        message: status.label,
        child: Icon(status.icon, size: 16, color: color),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}