import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/core/router/app_pages.dart';
import '../../../../app/core/theme/design_system.dart';
import '../../../../app/shared/widgets/async_view.dart';
import '../bloc/item_detail_bloc.dart';

/// Detail screen for one item. Reads the id from GoRouter path parameters and
/// renders through [AsyncView] (loading / error / data).
class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item')),
      body: BlocBuilder<ItemDetailBloc, ItemDetailState>(
        builder: (context, state) => AsyncView<String>(
          data: state.item?.title,
          isLoading: state.isLoading,
          errorMessage: state.errorMessage,
          onRetry: () => context
              .read<ItemDetailBloc>()
              .add(ItemDetailStarted(itemId)),
          builder: (context, _) => _DetailBody(item: state.item!),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.item});

  final dynamic item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      children: [
        Row(
          children: [
            Icon(
              item.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: item.done ? AppColors.success : theme.hintColor,
              size: 26.r,
            ),
            SizedBox(width: AppSpacing.sm.w),
            Expanded(
              child: Text(
                item.title as String,
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg.h),
        Text(item.description as String? ?? '', style: theme.textTheme.bodyLarge),
        SizedBox(height: AppSpacing.xl.h),
        Text(
          'Created ${_fmt(item.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        SizedBox(height: AppSpacing.xxl.h),
        TextButton(
          onPressed: () => Navigator.of(context).popNamed(),
          child: const Text('Back to list'),
        ),
      ],
    );
  }

  static String _fmt(dynamic dt) {
    if (dt == null) return '—';
    final d = DateTime.tryParse(dt.toString());
    return d?.toLocal().toString().split('.').first ?? '$dt';
  }
}

/// Route helper so screens never hard-code paths (navigation.md §2).
String itemDetailPath(String id) => AppPages.itemDetail(id);
