import 'package:intl/intl.dart';

/// Centralised date/number/currency formatting (ui-design.md §8).
/// Heavy formatting must not happen ad-hoc inside `build()` — call these.
class FormatterService {
  /// Creates with an optional locale (defaults to the system locale).
  const FormatterService({this.locale});

  /// Locale tag, e.g. `en_US`.
  final String? locale;

  static final DateFormat _dateTime =
      DateFormat('d MMM y • HH:mm', Intl.defaultLocale);
  static final DateFormat _date = DateFormat('d MMM y', Intl.defaultLocale);
  static final NumberFormat _compact =
      NumberFormat.compact(locale: Intl.defaultLocale);

  /// Formats [value] as `d MMM y • HH:mm`; returns `--` for null.
  String formatDateTime(DateTime? value) =>
      value == null ? '--' : _dateTime.format(value);

  /// Formats [value] as `d MMM y`; returns `--` for null.
  String formatDate(DateTime? value) =>
      value == null ? '--' : _date.format(value);

  /// Relative freshness label for "last updated" text (realtime.md §8).
  String relativeAge(Duration age) {
    if (age.inSeconds < 10) return 'just now';
    if (age.inMinutes < 1) return '${age.inSeconds}s ago';
    if (age.inHours < 1) return '${age.inMinutes}m ago';
    if (age.inDays < 1) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  /// Currency without a fixed symbol; product layer supplies the prefix.
  String formatMoney(double amount) =>
      amount.toStringAsFixed(2);

  /// Compact number for counters, e.g. `1.2k`.
  String formatCompact(int value) => _compact.format(value);
}
