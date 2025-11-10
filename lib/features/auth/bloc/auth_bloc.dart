import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/fcm_service.dart';
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

      // 1. Login en tu backend
      final LoginResponse response = await _authRepository.login(request);

      // 2. Sincronizar token FCM (NUEVO BLOQUE)
      // Esto se hace de forma "silenciosa", si falla no detiene el login
      try {
        final fcmService = FcmService();
        // Inicializa y pide permisos si es necesario
        await fcmService.initialize();
        // Obtiene el token actual
        final fcmToken = await fcmService.getToken();

        if (fcmToken != null) {
          // Lo envía a tu backend usando el nuevo método del repositorio
          await _authRepository.syncFcmToken(
            fcmToken: fcmToken,
            deviceName: event.deviceName,
            userAuthToken: response.token, // Token de Sanctum recién obtenido
          );
        }
      } catch (e) {
        // Logueamos el error pero NO interrumpimos el flujo de login exitoso
        print('⚠️ Advertencia: No se pudo sincronizar FCM tras login: $e');
      }

      // 3. Emitir estado autenticado
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
      // Al hacer logout, FCM podría necesitar limpieza si quisieras,
      // pero por lo general basta con que el backend invalide el token.
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