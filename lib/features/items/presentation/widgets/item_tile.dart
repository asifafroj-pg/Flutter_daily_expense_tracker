import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/core/theme/design_system.dart';
import '../../domain/entities/item_entity.dart';

/// Single list row. `const`-friendly and stateless (performance.md: cheap
/// rebuilds inside long lists). Swipe left-to-right to delete; tap the check
/// box to toggle done.
class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  final ItemEntity item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.lg.w),
        child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: item.done,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            decoration: item.done ? TextDecoration.lineThrough : null,
            color: item.done ? theme.hintColor : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 22.r),
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
      ),
    );
  }
}
