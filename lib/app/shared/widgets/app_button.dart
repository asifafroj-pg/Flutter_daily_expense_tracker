import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/theme/design_system.dart';

/// Primary action button. Always disabled while a request is in flight so a
/// double tap can never fire two operations (performance-login.md §2).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.expand = false,
    this.isSecondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool expand;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !isLoading;
    final child = isLoading
        ? SizedBox(
            height: 20.h,
            width: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: isSecondary ? theme.colorScheme.primary : Colors.white,
            ),
          )
        : Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: isSecondary ? theme.colorScheme.primary : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          );
    return SizedBox(
      width: expand ? double.infinity : null,
      height: AppSpacing.xl.h + 12, // ≥44dp tap target (ui-design.md §7)
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: isSecondary ? Colors.transparent : theme.colorScheme.primary,
          disabledBackgroundColor:
              (isSecondary ? theme.dividerColor : theme.colorScheme.primary)
                  .withOpacity(0.38),
          foregroundColor: theme.colorScheme.onPrimary,
          side: isSecondary ? BorderSide(color: theme.colorScheme.primary) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md.r),
          ),
        ),
        child: child,
      ),
    );
  }
}
