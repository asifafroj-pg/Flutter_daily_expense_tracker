import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/core/router/app_pages.dart';
import '../../../../app/core/theme/design_system.dart';
import '../../../../app/core/utils/validators.dart';
import '../../../../app/shared/widgets/app_button.dart';
import '../../../../app/shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';

/// Login screen. The form is plain `TextFormField`s validated locally; the
/// submit button is disabled while a request is in flight so a double tap can
/// never fire two logins (performance-login.md §2). Static borders only — no
/// layout shift on error (§1).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl.w),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.bolt_rounded, size: 56.r, color: theme.colorScheme.primary),
                    SizedBox(height: AppSpacing.lg.h),
                    Text('Welcome back', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                    SizedBox(height: AppSpacing.xs.h),
                    Text(
                      'Sign in to continue — works fully offline.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xxl.h),
                    BlocConsumer<AuthBloc, AuthState>(
                      listenWhen: (previous, current) =>
                          previous.errorMessage != current.errorMessage,
                      listener: (context, state) {
                        if (state.status == AuthStatus.authenticated) {
                          context.go(AppPages.items);
                        }
                      },
                      builder: (context, state) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _emailController,
                              label: 'Email',
                              hint: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              validator: (v) => Validators.email(v),
                            ),
                            SizedBox(height: AppSpacing.lg.h),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Password',
                              obscure: true,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              validator: (v) => Validators.password(v),
                              onSubmitted: (_) => _submit(),
                            ),
                            if (state.errorMessage != null) ...[
                              SizedBox(height: AppSpacing.md.h),
                              _ErrorBanner(message: state.errorMessage!),
                            ],
                            SizedBox(height: AppSpacing.xl.h),
                            AppButton(
                              label: 'Sign in',
                              expand: true,
                              isLoading: state.isSubmitting,
                              onPressed: state.canSubmitForm ? _submit : null,
                            ),
                            SizedBox(height: AppSpacing.md.h),
                            Text(
                              'Demo: any valid email + password ≥6 chars.\nUse password "wrongpass" to see the error path.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm.r),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20.r, color: theme.colorScheme.error),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
