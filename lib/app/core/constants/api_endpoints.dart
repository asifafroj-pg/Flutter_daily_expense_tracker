/// Backend endpoint registry. All paths are relative to `AppConfig.apiBaseUrl`.
abstract final class ApiEndpoints {
  /// Authentication: obtain a token.
  static const String login = 'auth/login';

  /// Authentication: validate the current token (session restore).
  static const String me = 'auth/me';

  /// Authentication: invalidate the current token.
  static const String logout = 'auth/logout';

  /// Items collection (list + create).
  static const String items = 'items';

  /// Single item by [id].
  static String item(String id) => 'items/$id';
}
