/// Input validators shared across forms. Keep user-facing strings here in the
/// UI layer (development.md §9); domain stays free of display text.
class Validators {
  const Validators._();

  /// Returns an error message when [value] is empty, otherwise `null`.
  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  /// Validates an email address shape.
  static String? email(String? value) {
    final missing = required(value, label: 'Email');
    if (missing != null) return missing;
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(value!.trim())) return 'Enter a valid email';
    return null;
  }

  /// Validates a password of at least [minLength] characters.
  static String? password(String? value, {int minLength = 6}) {
    final missing = required(value, label: 'Password');
    if (missing != null) return missing;
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validates that [value] parses to a number between [min] and [max].
  static String? numberRange(
    String? value, {
    required double min,
    required double max,
    String label = 'Value',
  }) {
    final missing = required(value, label: label);
    if (missing != null) return missing;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return '$label must be a number';
    if (parsed < min || parsed > max) {
      return '$label must be between ${_fmt(min)} and ${_fmt(max)}';
    }
    return null;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
