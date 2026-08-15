/// Date / time formatting helpers for picker fields.
class DateTimeUtils {
  DateTimeUtils._();

  /// Parses ISO-8601 / common date strings into [DateTime].
  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  /// Parses a time string (`HH:mm` or ISO) into a [TimeOfDay]-like map, or
  /// returns hours/minutes from a DateTime.
  static TimeParts? tryParseTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return TimeParts(hour: value.hour, minute: value.minute);
    }
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) {
      return TimeParts(hour: iso.hour, minute: iso.minute);
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
    if (match != null) {
      return TimeParts(
        hour: int.parse(match.group(1)!),
        minute: int.parse(match.group(2)!),
      );
    }
    return null;
  }

  /// Formats a date as `yyyy-MM-dd`.
  static String formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formats time as `HH:mm`.
  static String formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formats a full date-time as ISO-8601 local without timezone.
  static String formatDateTime(DateTime value) {
    final date = formatDate(value);
    final time = formatTime(value.hour, value.minute);
    return '${date}T$time:00';
  }

  /// Human display respecting a simple format hint.
  static String display(dynamic value, {String? format, bool timeOnly = false}) {
    if (value == null) return '';
    if (timeOnly) {
      final t = tryParseTime(value);
      if (t == null) return value.toString();
      return formatTime(t.hour, t.minute);
    }
    final dt = tryParse(value);
    if (dt == null) return value.toString();
    if (format == null || format.isEmpty) {
      return formatDateTime(dt);
    }
    return format
        .replaceAll('yyyy', dt.year.toString().padLeft(4, '0'))
        .replaceAll('MM', dt.month.toString().padLeft(2, '0'))
        .replaceAll('dd', dt.day.toString().padLeft(2, '0'))
        .replaceAll('HH', dt.hour.toString().padLeft(2, '0'))
        .replaceAll('mm', dt.minute.toString().padLeft(2, '0'));
  }
}

/// Hour / minute pair.
class TimeParts {
  /// Creates [TimeParts].
  const TimeParts({required this.hour, required this.minute});

  /// Hour 0-23.
  final int hour;

  /// Minute 0-59.
  final int minute;
}
