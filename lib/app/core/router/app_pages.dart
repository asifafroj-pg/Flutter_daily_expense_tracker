/// The only place route paths are written (navigation.md §2). Screens and
/// redirects reference these getters — never string literals.
class AppPages {
  AppPages._();

  /// Cold-start splash / session restore screen.
  static const String splash = '/';

  /// Login form.
  static const String login = '/login';

  /// Authenticated item list (the app's home after login).
  static const String items = '/items';

  /// Route template for the detail screen.
  static const String _itemDetail = '/items/:id';

  /// Builds the concrete detail route for [id].
  static String itemDetail(String id) =>
      _itemDetail.replaceFirst(':id', Uri.encodeComponent(id));

  /// Path pattern for the detail route registration.
  static const String itemDetailPattern = _itemDetail;
}
