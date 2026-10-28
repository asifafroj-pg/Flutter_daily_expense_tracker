import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/core/error/failures.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/get_item_detail_usecase.dart';

class ItemDetailState extends Equatable {
  const ItemDetailState({
    this.item,
    this.isLoading = false,
    this.errorMessage,
  });

  final ItemEntity? item;
  final bool isLoading;
  final String? errorMessage;

  ItemDetailState copyWith({
    ItemEntity? item,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      ItemDetailState(
        item: item ?? this.item,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [item, isLoading, errorMessage];
}

sealed class ItemDetailEvent {}

class ItemDetailStarted extends ItemDetailEvent {
  ItemDetailStarted(this.id);

  final String id;
}

class ItemDetailBloc extends Bloc<ItemDetailEvent, ItemDetailState> {
  ItemDetailBloc({required GetItemDetailUseCase getItemDetail})
      : _getItemDetail = getItemDetail,
        super(const ItemDetailState()) {
    on<ItemDetailStarted>(_onLoad);
  }

  final GetItemDetailUseCase _getItemDetail;

  Future<void> _onLoad(ItemDetailStarted e, Emitter<ItemDetailState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await _getItemDetail(e.id);
    emit(result.fold(
      (failure) => state.copyWith(isLoading: false, errorMessage: failure.message),
      (item) => state.copyWith(item: item, isLoading: false, clearError: true),
    ));
  }
}
