part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({
    required this.email,
    required this.password,
    required this.deviceName,
  });

  final String email;
  final String password;
  final String deviceName;

  @override
  List<Object?> get props => [email, password, deviceName];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
