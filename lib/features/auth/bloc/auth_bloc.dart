import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.authenticating, clearError: true));

    try {
      final request = LoginRequest(
        email: event.email,
        password: event.password,
        deviceName: event.deviceName,
      );

      final LoginResponse response = await _authRepository.login(request);

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          token: response.token,
          user: response.user,
          clearError: true,
        ),
      );
    } on AuthException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.message,
          clearToken: true,
          clearUser: true,
        ),
      );
    } on FormatException catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: error.message,
          clearToken: true,
          clearUser: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo iniciar sesión. Inténtalo de nuevo. $error',
          clearToken: true,
          clearUser: true,
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isAuthenticated || state.token == null) {
      emit(const AuthState());
      return;
    }

    emit(state.copyWith(status: AuthStatus.logoutInProgress, clearError: true));

    try {
      await _authRepository.logout(token: state.token!);
      emit(const AuthState());
    } on AuthException catch (error) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: error.message),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'No se pudo cerrar sesión. Inténtalo de nuevo.',
        ),
      );
    }
  }
}
