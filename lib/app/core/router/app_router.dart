import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/items/presentation/bloc/item_detail_bloc.dart';
import '../../../features/items/presentation/bloc/item_list_bloc.dart';
import '../../../features/items/presentation/screens/item_detail_screen.dart';
import '../../../features/items/presentation/screens/items_screen.dart';
import '../../../features/splash/presentation/screens/splash_screen.dart';
import '../../di/service_locator.dart';
import 'app_pages.dart';
import 'navigation_service.dart';

/// Router factory (navigation.md §4): auth state drives redirects through a
/// `refreshListenable` so route changes happen from state, not imperative
/// calls scattered through screens. Screen-scoped blocs are provided here —
/// one fresh instance per route entry (bloc-conventions.md §3).
GoRouter buildAppRouter(AuthBloc authBloc) {
  final navigatorKey = GlobalKey<NavigatorState>();
  NavigationService.instance.rootNavigatorKey = navigatorKey;
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppPages.splash,
    refreshListenable: _AuthRefresh(authBloc),
    redirect: (context, state) {
      final status = authBloc.state.status;
      final onSplash = state.matchedLocation == AppPages.splash;
      final onLogin = state.matchedLocation == AppPages.login;
      switch (status) {
        case AuthStatus.unknown:
          return onSplash ? null : AppPages.splash;
        case AuthStatus.authenticated:
          if (onSplash || onLogin) return AppPages.items;
          return null;
        case AuthStatus.unauthenticated:
          return onLogin ? null : AppPages.login;
      }
    },
    routes: [
      GoRoute(
        path: AppPages.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppPages.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppPages.items,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<ItemListBloc>()..add(ItemListStarted()),
          child: const ItemsScreen(),
        ),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => BlocProvider(
              create: (_) => getIt<ItemDetailBloc>()
                ..add(ItemDetailStarted(state.pathParameters['id'] ?? '')),
              child: ItemDetailScreen(
                itemId: Uri.decodeComponent(state.pathParameters['id'] ?? ''),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._bloc) {
    _sub = _bloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _bloc;
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
