/// Lightweight date/time formatting for activity screens (no intl dep).
/// Displays in the device local time. Example: "22 May 2026, 14:30".
String formatActivityDateTime(DateTime dtUtc) {
  final dt = dtUtc.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hh:$mm';
}
