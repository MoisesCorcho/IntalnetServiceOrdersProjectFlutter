import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/paginated_service_orders.dart';
import '../models/service_order.dart';

class ServiceOrderRepository {
  ServiceOrderRepository({
    http.Client? httpClient,
    this.baseUrl = _defaultBaseUrl,
  }) : _httpClient = httpClient ?? http.Client();

  static const String _defaultBaseUrl = 'https://intalnetservicios.kaledmolina.com/api/v1';

  final http.Client _httpClient;
  final String baseUrl;

  Future<PaginatedServiceOrders> fetchOrders({
    required String token,
    int page = 1,
    int perPage = 15,
    String? status,
  }) async {
    final query = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (status != null && status.isNotEmpty) {
      query['state'] = status;
      query['status'] = status;
    }

    final uri = Uri.parse(
      '$baseUrl/service-orders',
    ).replace(queryParameters: query);

    final response = await _httpClient.get(uri, headers: _headers(token));

    if (_isSuccess(response.statusCode)) {
      final body = _decodeBody(response.body);
      return PaginatedServiceOrders.fromJson(body);
    }

    throw ServiceOrderException(_extractErrorMessage(response));
  }

  Future<ServiceOrder> fetchOrder({
    required String token,
    required int serviceOrderId,
  }) async {
    final uri = Uri.parse('$baseUrl/service-orders/$serviceOrderId');

    final response = await _httpClient.get(uri, headers: _headers(token));

    if (_isSuccess(response.statusCode)) {
      final body = _decodeBody(response.body);
      return ServiceOrder.fromEnvelope(body);
    }

    throw ServiceOrderException(_extractErrorMessage(response));
  }

  Future<ServiceOrder> advanceState({
    required String token,
    required int serviceOrderId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/service-orders/$serviceOrderId/advance-state',
    );

    final response = await _httpClient.post(uri, headers: _headers(token));

    if (_isSuccess(response.statusCode)) {
      final body = _decodeBody(response.body);
      return ServiceOrder.fromEnvelope(body);
    }

    throw ServiceOrderException(_extractErrorMessage(response));
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _decodeBody(String source) {
    if (source.isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const ServiceOrderException(
      'El formato de respuesta del servidor no es válido.',
    );
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final candidates = [
          decoded['message'],
          decoded['error'],
          if (decoded['errors'] is Map<String, dynamic>)
            ..._flattenErrors(decoded['errors'] as Map<String, dynamic>),
        ].whereType<String>();

        if (candidates.isNotEmpty) {
          return candidates.first;
        }
      }
    } catch (_) {
      // Ignoramos los errores de parseo y devolvemos mensaje genérico.
    }

    return 'Error ${response.statusCode}. No se pudo completar la solicitud.';
  }

  Iterable<String> _flattenErrors(Map<String, dynamic> errors) sync* {
    for (final value in errors.values) {
      if (value is String) {
        yield value;
      } else if (value is Iterable) {
        yield* value.whereType<String>();
      }
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class ServiceOrderException implements Exception {
  const ServiceOrderException(this.message);

  final String message;

  @override
  String toString() => 'ServiceOrderException: $message';
}
