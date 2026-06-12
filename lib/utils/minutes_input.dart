/// Parses a duration string into whole minutes.
///
/// Accepts plain minutes ("44") or mm:ss ("43:59", rounded to the nearest
/// minute). Returns null if the input is invalid or not positive.
int? parseMinutes(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;

  if (text.contains(':')) {
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final mins = int.tryParse(parts[0]);
    final secs = int.tryParse(parts[1]);
    if (mins == null || secs == null || mins < 0 || secs < 0 || secs >= 60) {
      return null;
    }
    final total = ((mins * 60 + secs) / 60).round();
    return total > 0 ? total : null;
  }

  final mins = int.tryParse(text);
  return (mins != null && mins > 0) ? mins : null;
}
