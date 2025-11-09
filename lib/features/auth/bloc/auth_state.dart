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
}
