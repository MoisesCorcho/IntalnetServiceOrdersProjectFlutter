part of 'service_orders_bloc.dart';

enum ServiceOrdersStatus { initial, loading, refreshing, success, failure }

class ServiceOrdersState extends Equatable {
  const ServiceOrdersState({
    this.status = ServiceOrdersStatus.initial,
    this.orders = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.perPage = 15,
    this.errorMessage,
    this.isLoadingMore = false,
    this.statusFilter,
    this.token,
  });

  final ServiceOrdersStatus status;
  final List<ServiceOrder> orders;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final String? errorMessage;
  final bool isLoadingMore;
  final String? statusFilter;
  final String? token;

  bool get isLoading =>
      status == ServiceOrdersStatus.loading ||
      status == ServiceOrdersStatus.refreshing;

  bool get isRefreshing => status == ServiceOrdersStatus.refreshing;
  bool get hasError => status == ServiceOrdersStatus.failure;

  ServiceOrdersState copyWith({
    ServiceOrdersStatus? status,
    List<ServiceOrder>? orders,
    int? currentPage,
    int? lastPage,
    int? total,
    int? perPage,
    String? errorMessage,
    bool? isLoadingMore,
    String? statusFilter,
    String? token,
  }) {
    return ServiceOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      perPage: perPage ?? this.perPage,
      errorMessage: errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      statusFilter: statusFilter ?? this.statusFilter,
      token: token ?? this.token,
    );
  }

  @override
  List<Object?> get props => [
    status,
    orders,
    currentPage,
    lastPage,
    total,
    perPage,
    errorMessage,
    isLoadingMore,
    statusFilter,
    token,
  ];
}
