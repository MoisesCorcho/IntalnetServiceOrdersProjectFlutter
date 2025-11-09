import 'service_order.dart';

class PaginatedServiceOrders {
  const PaginatedServiceOrders({
    required this.orders,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    this.perPage,
    this.raw = const {},
  });

  final List<ServiceOrder> orders;
  final int currentPage;
  final int lastPage;
  final int total;
  final int? perPage;
  final Map<String, dynamic> raw;

  bool get hasMore => currentPage < lastPage;

  factory PaginatedServiceOrders.fromJson(Map<String, dynamic> json) {
    final data = _extractDataList(json);

    final orders = data
        .whereType<Map<String, dynamic>>()
        .map(ServiceOrder.fromJson)
        .toList();

    final meta = json['meta'];
    final currentPage = _parseInt(meta?['current_page']) ?? 1;
    final lastPage = _parseInt(meta?['last_page']) ?? 1;
    final total = _parseInt(meta?['total']) ?? orders.length;
    final perPage = _parseInt(meta?['per_page']);

    return PaginatedServiceOrders(
      orders: orders,
      currentPage: currentPage,
      lastPage: lastPage,
      total: total,
      perPage: perPage,
      raw: json,
    );
  }

  static List<dynamic> _extractDataList(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      return [data];
    }

    if (json.containsKey('orders') && json['orders'] is List) {
      return json['orders'] as List<dynamic>;
    }

    return const [];
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }
}
