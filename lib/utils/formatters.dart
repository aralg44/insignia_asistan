String _two(int n) => n.toString().padLeft(2, '0');

/// "11.11.2026 17:40" biçiminde tarih-saat.
String formatDateTime(DateTime t) =>
    '${_two(t.day)}.${_two(t.month)}.${t.year} ${_two(t.hour)}:${_two(t.minute)}';

/// "17:40" biçiminde saat.
String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// Sürüş süresini okunur hale getirir: "1s 05dk", "12dk 30sn", "45sn".
String formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) return '0 dk';
  final hours = totalSeconds ~/ 3600;
  final mins = (totalSeconds % 3600) ~/ 60;
  final secs = totalSeconds % 60;
  if (hours > 0) return '${hours}s ${_two(mins)}dk';
  if (mins > 0) return '${mins}dk ${secs}sn';
  return '${secs}sn';
}
