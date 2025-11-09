part of 'service_order_detail_cubit.dart';

enum ServiceOrderDetailStatus { initial, loading, success, advancing, failure }

class ServiceOrderDetailState extends Equatable {
  const ServiceOrderDetailState({
    this.status = ServiceOrderDetailStatus.initial,
    this.order,
    this.errorMessage,
  });

  final ServiceOrderDetailStatus status;
  final ServiceOrder? order;
  final String? errorMessage;

  bool get isLoading =>
      status == ServiceOrderDetailStatus.loading ||
      status == ServiceOrderDetailStatus.advancing;

  ServiceOrderDetailState copyWith({
    ServiceOrderDetailStatus? status,
    ServiceOrder? order,
    String? errorMessage,
  }) {
    return ServiceOrderDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, order, errorMessage];
}
