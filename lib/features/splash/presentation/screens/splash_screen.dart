import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/core/router/app_pages.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Cold-start screen: asks [AuthBloc] to restore a persisted session, then
/// redirects based on the resolved status (navigation.md §4). Shows a minimal
/// branded loader — no business logic here.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(AuthSessionRestoreRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          switch (state.status) {
            case AuthStatus.authenticated:
              context.go(AppPages.items);
            case AuthStatus.unauthenticated:
              context.go(AppPages.login);
            case AuthStatus.unknown:
              break;
          }
        },
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
