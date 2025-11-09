class LoginResponse {
  const LoginResponse({required this.token, this.user, this.raw});

  final String token;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? raw;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final token = _extractToken(json);

    if (token == null || token.isEmpty) {
      throw const FormatException(
        'No se encontró un token en la respuesta del servidor.',
      );
    }

    final user = _extractUser(json);

    return LoginResponse(token: token, user: user, raw: json);
  }

  static String? _extractToken(Map<String, dynamic> json) {
    final candidates = [
      json['token'],
      json['plain_text_token'],
      json['access_token'],
      if (json['data'] is Map<String, dynamic>)
        (json['data'] as Map<String, dynamic>)['token'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _extractUser(Map<String, dynamic> json) {
    final candidates = [
      json['user'],
      if (json['data'] is Map<String, dynamic>)
        (json['data'] as Map<String, dynamic>)['user'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        return candidate;
      }
    }

    return null;
  }
}
