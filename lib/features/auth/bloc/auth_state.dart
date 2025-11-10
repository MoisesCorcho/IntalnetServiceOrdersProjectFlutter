part of 'auth_bloc.dart';

enum AuthStatus {
  unauthenticated,
  authenticating,
  authenticated,
  logoutInProgress,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.token,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? token;
  // ¡Genial! Map<String, dynamic> es directamente serializable
  final Map<String, dynamic>? user;
  final String? errorMessage;

  bool get isAuthenticated =>
      token != null && status != AuthStatus.unauthenticated;
  bool get isLoading =>
      status == AuthStatus.authenticating ||
      status == AuthStatus.logoutInProgress;

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    Map<String, dynamic>? user,
    String? errorMessage,
    bool clearToken = false,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: clearToken ? null : token ?? this.token,
      user: clearUser ? null : user ?? this.user,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, token, user, errorMessage];

  // --- MÉTODOS AÑADIDOS PARA HYDRATED BLOC ---

  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      // Usamos 'byName' para convertir el String guardado de nuevo a Enum
      status: AuthStatus.values.byName(
          json['status'] ?? AuthStatus.unauthenticated.name),
      token: json['token'] as String?,
      // El mapa se lee directamente desde JSON
      user: json['user'] != null
          ? json['user'] as Map<String, dynamic>
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Usamos '.name' para guardar el Enum como un String
      'status': status.name,
      'token': token,
      'user': user, // El mapa se guarda directamente
      'errorMessage': errorMessage,
    };
  }
  // --- FIN DE MÉTODOS AÑADIDOS ---
}