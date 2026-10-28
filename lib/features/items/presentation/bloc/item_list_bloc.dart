import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/core/error/failures.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/create_item_usecase.dart';
import '../../domain/usecases/delete_item_usecase.dart';
import '../../domain/usecases/get_items_usecase.dart';
import '../../domain/usecases/toggle_item_usecase.dart';

/// Screen-scoped list state — Loading/Loaded/Empty/Error (bloc-conventions.md
/// §2). Mutations act on the in-memory list because the default backend is
/// offline and instant.
class ItemListState extends Equatable {
  const ItemListState({
    this.items = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
  });

  final List<ItemEntity> items;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;

  bool get isEmpty => !isLoading && errorMessage == null && items.isEmpty;

  int get remainingCount => items.where((i) => !i.done).length;

  ItemListState copyWith({
    List<ItemEntity>? items,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ItemListState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [items, isLoading, isRefreshing, errorMessage];
}

sealed class ItemListEvent {}

/// First load after the screen mounts.
class ItemListStarted extends ItemListEvent {}

/// Pull-to-refresh re-read (realtime.md: explicit user-triggered refresh).
class ItemListRefreshed extends ItemListEvent {}

class ItemAddRequested extends ItemListEvent {
  ItemAddRequested(this.title, this.description);

  final String title;
  final String description;
}

class ItemToggleRequested extends ItemListEvent {
  ItemToggleRequested(this.id);

  final String id;
}

class ItemDeleteRequested extends ItemListEvent {
  ItemDeleteRequested(this.id);

  final String id;
}

/// Reference feature bloc: one `Started` event, fold every `Either` onto a
/// typed state, never let a failure escape as an exception.
class ItemListBloc extends Bloc<ItemListEvent, ItemListState> {
  ItemListBloc({
    required GetItemsUseCase getItems,
    required CreateItemUseCase createItem,
    required ToggleItemUseCase toggleItem,
    required DeleteItemUseCase deleteItem,
  })  : _getItems = getItems,
        _createItem = createItem,
        _toggleItem = toggleItem,
        _deleteItem = deleteItem,
        super(const ItemListState()) {
    on<ItemListStarted>(_onLoad);
    on<ItemListRefreshed>(_onRefresh);
    on<ItemAddRequested>(_onAdd);
    on<ItemToggleRequested>(_onToggle);
    on<ItemDeleteRequested>(_onDelete);
  }

  final GetItemsUseCase _getItems;
  final CreateItemUseCase _createItem;
  final ToggleItemUseCase _toggleItem;
  final DeleteItemUseCase _deleteItem;

  Future<void> _onLoad(ItemListStarted e, Emitter<ItemListState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getItems();
    emit(result.fold(
      (failure) => state.copyWith(isLoading: false, errorMessage: failure.message),
      (items) => state.copyWith(items: items, isLoading: false, clearError: true),
    ));
  }

  Future<void> _onRefresh(
      ItemListRefreshed e, Emitter<ItemListState> emit) async {
    emit(state.copyWith(isRefreshing: true, clearError: true));
    final result = await _getItems();
    emit(result.fold(
      (failure) => state.copyWith(isRefreshing: false, errorMessage: failure.message),
      (items) => state.copyWith(items: items, isRefreshing: false, clearError: true),
    ));
  }

  Future<void> _onAdd(ItemAddRequested e, Emitter<ItemListState> emit) async {
    final result = await _createItem(
      CreateItemParams(title: e.title, description: e.description),
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (item) => emit(state.copyWith(items: [...state.items, item], clearError: true)),
    );
  }

  Future<void> _onToggle(ItemToggleRequested e, Emitter<ItemListState> emit) async {
    final result = await _toggleItem(e.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (item) => emit(state.copyWith(
        items: [
          for (final i in state.items) i.id == item.id ? item : i,
        ],
        clearError: true,
      )),
    );
  }

  Future<void> _onDelete(ItemDeleteRequested e, Emitter<ItemListState> emit) async {
    final result = await _deleteItem(e.id);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        items: state.items.where((i) => i.id != e.id).toList(),
        clearError: true,
      )),
    );
  }
}
