/// App-wide constants. Keep values here, never inline magic numbers.
class AppConstants {
  AppConstants._();

  /// Human-readable application name.
  static const String appName = 'App Base';

  /// Default page size for paginated list requests.
  static const int defaultPageSize = 20;

  /// Network request timeout.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Network connection timeout.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Minimum tap target per ui-design.md §7.
  static const double minTapTarget = 44;

  /// Design draft baseline width (flutter_screenutil).
  static const double designWidth = 375;

  /// Design draft baseline height (flutter_screenutil).
  static const double designHeight = 812;
}
