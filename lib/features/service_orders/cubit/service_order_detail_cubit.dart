import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/service_order_repository.dart';
import '../models/service_order.dart';

part 'service_order_detail_state.dart';

class ServiceOrderDetailCubit extends Cubit<ServiceOrderDetailState> {
  ServiceOrderDetailCubit({required ServiceOrderRepository repository})
    : _repository = repository,
      super(const ServiceOrderDetailState());

  final ServiceOrderRepository _repository;
  String? _token;
  int? _orderId;

  Future<void> load({
    required String token,
    required int orderId,
    ServiceOrder? initialOrder,
  }) async {
    _token = token;
    _orderId = orderId;

    if (initialOrder != null) {
      emit(
        state.copyWith(
          status: ServiceOrderDetailStatus.success,
          order: initialOrder,
          errorMessage: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: ServiceOrderDetailStatus.loading,
          errorMessage: null,
        ),
      );
    }

    try {
      final order = await _repository.fetchOrder(
        token: token,
        serviceOrderId: orderId,
      );

      emit(
        state.copyWith(
          status: ServiceOrderDetailStatus.success,
          order: order,
          errorMessage: null,
        ),
      );
    } on ServiceOrderException catch (error) {
      emit(
        state.copyWith(
          status: ServiceOrderDetailStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ServiceOrderDetailStatus.failure,
          errorMessage: 'No se pudo cargar la orden: $error',
        ),
      );
    }
  }

  Future<ServiceOrder?> advanceState() async {
    final token = _token;
    final orderId = _orderId;

    if (token == null || orderId == null) {
      return null;
    }

    emit(
      state.copyWith(
        status: ServiceOrderDetailStatus.advancing,
        errorMessage: null,
      ),
    );

    try {
      final order = await _repository.advanceState(
        token: token,
        serviceOrderId: orderId,
      );

      emit(
        state.copyWith(
          status: ServiceOrderDetailStatus.success,
          order: order,
          errorMessage: null,
        ),
      );

      return order;
    } on ServiceOrderException catch (error) {
      emit(
        state.copyWith(
          status: ServiceOrderDetailStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ServiceOrderDetailStatus.failure,
          errorMessage: 'No se pudo avanzar el estado: $error',
        ),
      );
    }

    return null;
  }
}
