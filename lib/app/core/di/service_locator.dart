import 'package:get_it/get_it.dart';

import '../../../features/auth/data/datasources/auth_local_data_source_impl.dart';
import '../../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../../features/auth/domain/repositories/auth_repository.dart';
import '../../../features/auth/domain/usecases/login_usecase.dart';
import '../../../features/auth/domain/usecases/logout_usecase.dart';
import '../../../features/auth/domain/usecases/restore_session_usecase.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/items/data/datasources/item_memory_data_source.dart';
import '../../../features/items/data/models/item_model.dart';
import '../../../features/items/data/repositories/item_repository_impl.dart';
import '../../../features/items/domain/repositories/item_repository.dart';
import '../../../features/items/domain/usecases/create_item_usecase.dart';
import '../../../features/items/domain/usecases/delete_item_usecase.dart';
import '../../../features/items/domain/usecases/get_item_detail_usecase.dart';
import '../../../features/items/domain/usecases/get_items_usecase.dart';
import '../../../features/items/domain/usecases/toggle_item_usecase.dart';
import '../../../features/items/presentation/bloc/item_detail_bloc.dart';
import '../../../features/items/presentation/bloc/item_list_bloc.dart';
import '../../config/app_config.dart';
import '../../data/data_source.dart';
import '../../services/connectivity/connectivity_service.dart';
import '../../services/storage/local_key_value_store.dart';
import '../../services/storage/secure_storage.dart';

/// Service locator instance (get_it).
final GetIt getIt = GetIt.instance;

/// Registers every dependency exactly once (development.md §4):
/// - services/repos/use cases: lazy singletons
/// - app-scoped `AuthBloc`: singleton
/// - screen-scoped blocs: factories (one per route entry)
///
/// **Backend switch**: change [AppConfig.backend] (or the registration below)
/// to plug in REST / Supabase / Firebase — only the `DataSource` factory
/// changes; domain and presentation are untouched (offline-optional.md).
void configureDependencies({AppConfig? config}) {
  final appConfig = config ?? AppConfig.fromEnvironment();

  // ── Core ──────────────────────────────────────────────────────────────
  getIt.registerSingleton<AppConfig>(appConfig);

  // ── Services (lazy singletons) ────────────────────────────────────────
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorageImpl());
  getIt.registerLazySingleton<LocalKeyValueStore>(() => MemoryKeyValueStore());
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityServiceImpl(),
  );

  // ── Data sources (the offline-first seam) ─────────────────────────────
  getIt.registerLazySingleton<DataSource<ItemModel>>(
    () => ItemMemoryDataSource(store: getIt()),
  );
  getIt.registerLazySingleton<AuthProvider>(() => const LocalAuthProvider());
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt()),
  );

  // ── Repositories ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<ItemRepository>(
    () => ItemRepositoryImpl(source: getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(provider: getIt(), local: getIt()),
  );

  // ── Use cases ─────────────────────────────────────────────────────────
  getIt.registerLazySingleton<GetItemsUseCase>(() => GetItemsUseCase(getIt()));
  getIt.registerLazySingleton<GetItemDetailUseCase>(
    () => GetItemDetailUseCase(getIt()),
  );
  getIt.registerLazySingleton<CreateItemUseCase>(
    () => CreateItemUseCase(getIt()),
  );
  getIt.registerLazySingleton<ToggleItemUseCase>(
    () => ToggleItemUseCase(getIt()),
  );
  getIt.registerLazySingleton<DeleteItemUseCase>(
    () => DeleteItemUseCase(getIt()),
  );
  getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton<RestoreSessionUseCase>(
    () => RestoreSessionUseCase(getIt()),
  );
  getIt.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(getIt()));

  // ── Blocs ─────────────────────────────────────────────────────────────
  // App-scoped session bloc: one instance for the whole lifetime.
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      restoreSession: getIt(),
      login: getIt(),
      logout: getIt(),
    ),
  );
  // Screen-scoped blocs: fresh instance per route entry.
  getIt.registerFactory<ItemListBloc>(
    () => ItemListBloc(
      getItems: getIt(),
      createItem: getIt(),
      toggleItem: getIt(),
      deleteItem: getIt(),
    ),
  );
  getIt.registerFactory<ItemDetailBloc>(
    () => ItemDetailBloc(getItemDetail: getIt()),
  );
}
