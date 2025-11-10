import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/login_request.dart';
import '../models/login_response.dart';

class AuthRepository {
  AuthRepository({http.Client? httpClient, this.baseUrl = _defaultBaseUrl})
    : _httpClient = httpClient ?? http.Client();

  static const String _defaultBaseUrl = 'https://intalnetservicios.kaledmolina.com/api/v1';

  final http.Client _httpClient;
  final String baseUrl;

  Future<LoginResponse> login(LoginRequest request) async {
    final uri = Uri.parse('$baseUrl/login');

    final response = await _httpClient.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (_isSuccess(response.statusCode)) {
      final body = _decodeBody(response.body);
      return LoginResponse.fromJson(body);
    }

    throw AuthException(_extractErrorMessage(response));
  }

  Future<void> logout({required String token}) async {
    final uri = Uri.parse('$baseUrl/logout');

    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (_isSuccess(response.statusCode)) {
      return;
    }

    throw AuthException(_extractErrorMessage(response));
  }

  // NUEVO MÉTODO PARA SINCRONIZAR EL TOKEN FCM
  Future<void> syncFcmToken({
    required String fcmToken,
    required String deviceName,
    required String userAuthToken,
  }) async {
    final uri = Uri.parse('$baseUrl/fcm-tokens'); // Ajusta si tu ruta es diferente, ej: /v1/fcm-tokens

    try {
      final response = await _httpClient.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $userAuthToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'device_name': deviceName,
        }),
      );

      if (!_isSuccess(response.statusCode)) {
        // Puedes decidir si quieres lanzar una excepción aquí o solo loguear el error.
        // Por ahora, solo imprimimos para debug, pero podrías lanzar AuthException.
        print("❌ Error al sincronizar FCM Token: ${_extractErrorMessage(response)}");
      } else {
         print("✅ FCM Token sincronizado correctamente.");
      }
    } catch (e) {
      print("❌ Excepción al sincronizar FCM Token: $e");
      // Opcional: rethrow; si quieres manejarlo arriba.
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _decodeBody(String source) {
    if (source.isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const AuthException(
      'El formato de respuesta del servidor no es válido.',
    );
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final Iterable<String> messageCandidates = [
          decoded['message'],
          decoded['error'],
          if (decoded['errors'] is Map<String, dynamic>)
            ..._flattenErrorMessages(decoded['errors'] as Map<String, dynamic>),
        ].whereType<String>();

        if (messageCandidates.isNotEmpty) {
          return messageCandidates.first;
        }
      }
    } catch (_) {
      // Ignore json parsing errors; fall back to generic message.
    }

    return 'Error ${response.statusCode}. No se pudo completar la solicitud.';
  }

  Iterable<String> _flattenErrorMessages(Map<String, dynamic> errors) sync* {
    for (final value in errors.values) {
      if (value is String) {
        yield value;
      } else if (value is List) {
        yield* value.whereType<String>();
      }
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}