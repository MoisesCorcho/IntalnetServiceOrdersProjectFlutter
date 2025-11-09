class ServiceOrder {
  const ServiceOrder({
    required this.id,
    this.orderNumber,
    this.title,
    this.description,
    this.state,
    this.stateLabel,
    this.checkInDate,
    this.scheduledAt,
    this.completedAt,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
    this.raw = const {},
  });

  final int id;
  final String? orderNumber;
  final String? title;
  final String? description;
  final String? state;
  final String? stateLabel;
  final DateTime? checkInDate;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? customerName;
  final String? customerAddress;
  final String? customerPhone;
  final Map<String, dynamic> raw;

  factory ServiceOrder.fromEnvelope(Map<String, dynamic> envelope) {
    if (envelope.containsKey('data')) {
      final data = envelope['data'];
      if (data is Map<String, dynamic>) {
        return ServiceOrder.fromJson(data);
      }
    }

    return ServiceOrder.fromJson(envelope);
  }

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'];
    final source = attributes is Map<String, dynamic> ? attributes : json;

    final idValue = json['id'] ?? source['id'];

    return ServiceOrder(
      id: _parseId(idValue),
      orderNumber: _stringOrNull(source['order_number']),
      title: _stringOrNull(source['title']),
      description: _stringOrNull(source['description']),
      state: _stringOrNull(source['state']),
      stateLabel: _stringOrNull(source['state_label']),
      checkInDate: _parseDate(source['check_in_date']),
      scheduledAt: _parseDate(source['scheduled_at']),
      completedAt: _parseDate(source['completed_at']),
      customerName: _stringOrNull(
        source['customer_name_snapshot'] ?? source['customer_name'],
      ),
      customerAddress: _stringOrNull(
        source['customer_address_snapshot'] ?? source['customer_address'],
      ),
      customerPhone: _stringOrNull(
        source['customer_phone_snapshot'] ?? source['customer_phone'],
      ),
      raw: json,
    );
  }

  ServiceOrder copyWith({
    String? orderNumber,
    String? title,
    String? description,
    String? state,
    String? stateLabel,
    DateTime? checkInDate,
    DateTime? scheduledAt,
    DateTime? completedAt,
    String? customerName,
    String? customerAddress,
    String? customerPhone,
    Map<String, dynamic>? raw,
  }) {
    return ServiceOrder(
      id: id,
      orderNumber: orderNumber ?? this.orderNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      state: state ?? this.state,
      stateLabel: stateLabel ?? this.stateLabel,
      checkInDate: checkInDate ?? this.checkInDate,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      customerPhone: customerPhone ?? this.customerPhone,
      raw: raw ?? this.raw,
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) {
      return value.toInt();
    }
    throw const FormatException('El identificador de la orden es inválido.');
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
