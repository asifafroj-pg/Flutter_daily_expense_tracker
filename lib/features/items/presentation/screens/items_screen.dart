import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/core/router/app_pages.dart';
import '../../../../app/shared/widgets/app_button.dart';
import '../../../../app/shared/widgets/async_view.dart';
import '../../../../app/shared/widgets/app_text_field.dart';
import '../../../../app/core/theme/design_system.dart';
import '../../../../app/core/utils/validators.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/item_list_bloc.dart';
import '../widgets/item_tile.dart';

/// Home screen after login. Renders through [AsyncView] so all four UI
/// states exist (ui-design.md §5); stays under ~120 lines by delegating rows
/// and the add-sheet to widgets below.
class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddItemSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New'),
      ),
      body: BlocBuilder<ItemListBloc, ItemListState>(
        builder: (context, state) => AsyncView<List<dynamic>>(
          data: state.items.isEmpty ? null : state.items,
          isLoading: state.isLoading,
          isEmpty: state.isEmpty,
          errorMessage: state.errorMessage,
          onRetry: () => context.read<ItemListBloc>().add(ItemListRefreshed()),
          emptyBuilder: (_) => EmptyState(
            message: 'No items yet.\nTap "New" to create your first one.',
          ),
          builder: (context, _) => _ItemList(state: state),
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.state});

  final ItemListState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ItemListBloc>();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg.w, AppSpacing.sm.h, AppSpacing.lg.w, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${state.remainingCount} remaining · ${state.items.length} total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return ItemTile(
                item: item,
                onToggle: () => bloc.add(ItemToggleRequested(item.id)),
                onDelete: () => bloc.add(ItemDeleteRequested(item.id)),
                onTap: () => context.push(AppPages.itemDetail(item.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet form for creating an item (ui-design.md §3: modal form for
/// short inputs instead of a full route).
Future<void> showAddItemSheet(BuildContext context) {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg.w,
        0,
        AppSpacing.lg.w,
        MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg.h,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New item', style: Theme.of(sheetContext).textTheme.titleLarge),
            SizedBox(height: AppSpacing.lg.h),
            AppTextField(
              controller: titleController,
              label: 'Title',
              validator: (v) => Validators.required(v, label: 'Title'),
            ),
            SizedBox(height: AppSpacing.md.h),
            AppTextField(
              controller: descriptionController,
              label: 'Description',
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            SizedBox(height: AppSpacing.lg.h),
            AppButton(
              label: 'Create',
              expand: true,
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                sheetContext.read<ItemListBloc>().add(
                      ItemAddRequested(
                        titleController.text,
                        descriptionController.text,
                      ),
                    );
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
