import 'package:intl/intl.dart';

final _two = NumberFormat('00');
final _clock = NumberFormat('00');

String formatDateTime(DateTime? dt, {bool withSeconds = false}) {
  if (dt == null) return '—';
  final date = DateFormat('yyyy-MM-dd').format(dt);
  final time = withSeconds
      ? '${_two.format(dt.hour)}:${_clock.format(dt.minute)}:${_clock.format(dt.second)}'
      : '${_two.format(dt.hour)}:${_clock.format(dt.minute)}';
  return '$date $time';
}

String timeAgo(DateTime? dt) {
  if (dt == null) return '—';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.isNegative) {
    final f = diff.abs();
    return 'in ${_short(f)}';
  }
  return '${_short(diff)} ago';
}

String _short(Duration d) {
  if (d.inSeconds < 60) return '${d.inSeconds}s';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 30) return '${d.inDays}d';
  if (d.inDays < 365) return '${d.inDays ~/ 30}mo';
  return '${d.inDays ~/ 365}y';
}

String truncateMiddle(String s, int max) {
  if (s.length <= max) return s;
  final half = max ~/ 2;
  return '${s.substring(0, half)}…${s.substring(s.length - (max - half))}';
}