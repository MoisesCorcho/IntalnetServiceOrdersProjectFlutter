import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/service_order_repository.dart';
import '../models/paginated_service_orders.dart';
import '../models/service_order.dart';

part 'service_orders_event.dart';
part 'service_orders_state.dart';

class ServiceOrdersBloc extends Bloc<ServiceOrdersEvent, ServiceOrdersState> {
  ServiceOrdersBloc({required ServiceOrderRepository repository})
      : _repository = repository,
        super(const ServiceOrdersState()) {
    on<ServiceOrdersRequested>(_onRequested);
    on<ServiceOrdersRefreshed>(_onRefreshed);
    on<ServiceOrderUpdated>(_onOrderUpdated);
    on<ServiceOrdersLoadMore>(_onLoadMore);
    // 1. REGISTRAR EL NUEVO EVENTO
    on<ServiceOrdersFilterChanged>(_onFilterChanged);
  }

  final ServiceOrderRepository _repository;
  String? _token;
  String? _statusFilter;

  Future<void> _onRequested(
    ServiceOrdersRequested event,
    Emitter<ServiceOrdersState> emit,
  ) async {
    _token = event.token;
    _statusFilter = event.status;
    final shouldReset = event.page <= 1;
    emit(
      state.copyWith(
        status: ServiceOrdersStatus.loading,
        errorMessage: null,
        isLoadingMore: false,
        statusFilter: event.status,
        token: event.token,
        orders: shouldReset ? <ServiceOrder>[] : state.orders,
        currentPage: shouldReset ? 1 : state.currentPage,
        lastPage: shouldReset ? 1 : state.lastPage,
        total: shouldReset ? 0 : state.total,
      ),
    );

    try {
      final PaginatedServiceOrders response = await _repository.fetchOrders(
        token: event.token,
        page: event.page,
        perPage: event.perPage,
        status: event.status,
      );

      emit(
        state.copyWith(
          status: ServiceOrdersStatus.success,
          orders: response.orders,
          currentPage: response.currentPage,
          lastPage: response.lastPage,
          total: response.total,
          perPage: response.perPage ?? event.perPage,
          errorMessage: null,
          isLoadingMore: false,
          statusFilter: event.status,
          token: event.token,
        ),
      );
    } on ServiceOrderException catch (error) {
      emit(
        state.copyWith(
          status: ServiceOrdersStatus.failure,
          errorMessage: error.message,
          isLoadingMore: false,
          statusFilter: event.status,
          token: event.token,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ServiceOrdersStatus.failure,
          errorMessage: 'No se pudieron cargar las órdenes: $error',
          isLoadingMore: false,
          statusFilter: event.status,
          token: event.token,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    ServiceOrdersRefreshed event,
    Emitter<ServiceOrdersState> emit,
  ) async {
    // 2. MODIFICADO: _onRefreshed ahora solo llama a _onFilterChanged
    // con el filtro que ya está guardado en el estado.
    add(ServiceOrdersFilterChanged(status: state.statusFilter));
  }

  void _onOrderUpdated(
    ServiceOrderUpdated event,
    Emitter<ServiceOrdersState> emit,
  ) {
    final updatedOrders = state.orders.map((order) {
      if (order.id == event.order.id) {
        return event.order;
      }
      return order;
    }).toList();

    emit(state.copyWith(orders: updatedOrders));
  }

  Future<void> _onLoadMore(
    ServiceOrdersLoadMore event,
    Emitter<ServiceOrdersState> emit,
  ) async {
    final token = _token;
    if (token == null ||
        state.isLoadingMore ||
        state.currentPage >= state.lastPage) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      final nextPage = state.currentPage + 1;
      final PaginatedServiceOrders response = await _repository.fetchOrders(
        token: token,
        page: nextPage,
        perPage: state.perPage,
        // _onLoadMore ya usaba _statusFilter, ¡lo cual es perfecto!
        status: _statusFilter,
      );

      emit(
        state.copyWith(
          status: ServiceOrdersStatus.success,
          orders: [...state.orders, ...response.orders],
          currentPage: response.currentPage,
          lastPage: response.lastPage,
          total: response.total,
          perPage: response.perPage ?? state.perPage,
          isLoadingMore: false,
          errorMessage: null,
          statusFilter: _statusFilter,
          token: token,
        ),
      );
    } on ServiceOrderException catch (error) {
      emit(
        state.copyWith(
          status: ServiceOrdersStatus.failure,
          errorMessage: error.message,
          isLoadingMore: false,
          statusFilter: _statusFilter,
          token: token,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
            status: ServiceOrdersStatus.failure,
            // --- ¡AQUÍ ESTABA EL ERROR! ---
            // 'source:' ha sido cambiado por 'errorMessage:'
            errorMessage: 'No se pudieron cargar más órdenes: $error',
            isLoadingMore: false,
            statusFilter: _statusFilter,
            token: token),
      );
    }
  }

  // 3. AÑADIDO: El nuevo handler para cambiar de pestaña (y para refrescar)
  Future<void> _onFilterChanged(
    ServiceOrdersFilterChanged event,
    Emitter<ServiceOrdersState> emit,
  ) async {
    // 1. Obtenemos el token
    final token = _token ?? state.token;
    if (token == null) {
      emit(state.copyWith(
          status: ServiceOrdersStatus.failure, errorMessage: 'No autenticado.'));
      return;
    }

    // 2. Actualizamos el filtro interno del BLoC
    _statusFilter = event.status;

    // 3. Emitimos el estado de 'refreshing', reseteando la lista y la paginación
    emit(
      state.copyWith(
        status: ServiceOrdersStatus.refreshing,
        errorMessage: null,
        isLoadingMore: false,
        statusFilter: _statusFilter, // Guardamos el filtro en el estado
        token: token,
        orders: <ServiceOrder>[], // Reseteamos la lista
        currentPage: 1,
        lastPage: 1,
        total: 0,
      ),
    );

    // 4. Buscamos en la API con el nuevo filtro
    try {
      final PaginatedServiceOrders response = await _repository.fetchOrders(
        token: token,
        page: 1, // Página 1 porque estamos filtrando/refrescando
        perPage: state.perPage,
        status: _statusFilter, // Usamos el filtro actualizado
      );

      // 5. Emitimos el estado de éxito
      emit(
        state.copyWith(
          status: ServiceOrdersStatus.success,
          orders: response.orders,
          currentPage: response.currentPage,
          lastPage: response.lastPage,
          total: response.total,
          perPage: response.perPage ?? state.perPage,
          isLoadingMore: false,
        ),
      );
    } on ServiceOrderException catch (error) {
      // 6. Emitimos fallo
      emit(
        state.copyWith(
          status: ServiceOrdersStatus.failure,
          errorMessage: error.message,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      // 7. Emitimos fallo genérico
      emit(
        state.copyWith(
          status: ServiceOrdersStatus.failure,
          errorMessage: 'No se pudieron cargar las órdenes: $error',
          isLoadingMore: false,
        ),
      );
    }
  }
}