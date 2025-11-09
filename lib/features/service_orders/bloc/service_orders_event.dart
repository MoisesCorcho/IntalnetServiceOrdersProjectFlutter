part of 'service_orders_bloc.dart';

abstract class ServiceOrdersEvent extends Equatable {
  const ServiceOrdersEvent();

  @override
  List<Object?> get props => const [];
}

class ServiceOrdersRequested extends ServiceOrdersEvent {
  const ServiceOrdersRequested({
    required this.token,
    this.page = 1,
    this.perPage = 15,
    this.status,
  });

  final String token;
  final int page;
  final int perPage;
  final String? status;

  @override
  List<Object?> get props => [token, page, perPage, status];
}

class ServiceOrdersRefreshed extends ServiceOrdersEvent {
  const ServiceOrdersRefreshed();
}

class ServiceOrderUpdated extends ServiceOrdersEvent {
  const ServiceOrderUpdated({required this.order});

  final ServiceOrder order;

  @override
  List<Object?> get props => [order];
}

class ServiceOrdersLoadMore extends ServiceOrdersEvent {
  const ServiceOrdersLoadMore();
}
