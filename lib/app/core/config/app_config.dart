/// Where data comes from. The app ships **offline-first** ([memory]);
/// REST / Supabase / Firebase are future options — implement the
/// `DataSource<T>` contract and switch this value in `service_locator`.
enum DataBackend {
  /// On-device store (in-memory + persisted JSON). The default.
  memory,

  /// HTTP backend via the Dio client (`api-integration.md`).
  rest,

  /// Reserved: Supabase implementation of `DataSource<T>`.
  supabase,

  /// Reserved: Firebase (Firestore) implementation of `DataSource<T>`.
  firebase,
}

/// Single abstraction over `--dart-define-from-file` environment values.
///
/// Only non-secret configuration is read here (see security.md §1).
class AppConfig {
  /// Creates the config from explicit values (testable entry point).
  const AppConfig({
    required this.env,
    required this.apiBaseUrl,
    required this.realtimePollSeconds,
    this.backend = DataBackend.memory,
  });

  /// Reads values injected with `--dart-define-from-file=config/<env>.json`.
  factory AppConfig.fromEnvironment() => const AppConfig(
        env: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
        apiBaseUrl: String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://dev.api.example.com/',
        ),
        realtimePollSeconds: int.fromEnvironment(
          'REALTIME_POLL_SECONDS',
          defaultValue: 15,
        ),
        backend: DataBackend.values.firstWhere(
          (b) => b.name == const String.fromEnvironment('DATA_BACKEND'),
          orElse: () => DataBackend.memory,
        ),
      );

  /// Environment name: `dev`, `staging` or `prod`.
  final String env;

  /// Backend base URL. Must end with a trailing slash. Unused when
  /// [backend] is [DataBackend.memory].
  final String apiBaseUrl;

  /// Default polling interval for live/near-live screens.
  final int realtimePollSeconds;

  /// Active data source strategy (offline-first by default).
  final DataBackend backend;

  /// Whether the app runs in debug mode against a non-prod environment.
  bool get isDebug => env != 'prod';

  /// Poll interval derived from [realtimePollSeconds].
  Duration get realtimePollInterval => Duration(seconds: realtimePollSeconds);
}
