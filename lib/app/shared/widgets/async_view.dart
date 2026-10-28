import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/design_system.dart';

/// The four canonical UI states every screen renders through
/// (ui-design.md §5): loading → empty → error → data. Screens pass their
/// bloc state into this widget instead of hand-rolling branches.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.data,
    required this.isLoading,
    this.isRefreshing = false,
    this.errorMessage,
    required this.builder,
    this.onRetry,
    this.emptyBuilder,
    this.isEmpty = false,
  });

  final T? data;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final bool isEmpty;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context) {
    if (isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null && data == null) {
      return ErrorView(message: errorMessage!, onRetry: onRetry);
    }
    if (isEmpty || data == null) {
      return emptyBuilder?.call(context) ??
          const EmptyState(
            message: 'Nothing here yet',
          );
    }
    final content = builder(context, data as T);
    if (onRetry == null && !isRefreshing) return content;
    return RefreshIndicator(
      onRefresh: onRetry ?? () async {},
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Friendly empty placeholder with an optional call-to-action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56.r, color: theme.hintColor),
            SizedBox(height: AppSpacing.md.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            if (action != null) ...[
              SizedBox(height: AppSpacing.lg.h),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Full-area error card with retry (realtime.md §7: typed message + explicit
/// retry, never a silent spinner forever).
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56.r, color: theme.colorScheme.error),
            SizedBox(height: AppSpacing.md.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              SizedBox(height: AppSpacing.lg.h),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
