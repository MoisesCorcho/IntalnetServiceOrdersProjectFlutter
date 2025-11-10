import 'dart:async';

import 'package:equatable/equatable.dart';
// 1. Importar HydratedBloc
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../core/services/fcm_service.dart';
import '../data/auth_repository.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
// (ELIMINADA la importación de 'user.dart', ya no es necesaria)

part 'auth_event.dart';
part 'auth_state.dart';

// 2. Cambiar 'Bloc' por 'HydratedBloc'
class AuthBloc extends HydratedBloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        // 3. El estado inicial se cargará desde el disco si existe
        super(const AuthState(status: AuthStatus.unauthenticated)) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  // 4. Añadir los métodos de HydratedBloc
  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      // Leemos el estado desde el JSON guardado usando el factory
      return AuthState.fromJson(json);
    } catch (_) {
      // Si falla la lectura, empezamos de cero
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    // Solo guardamos estados "estables" (autenticado o no)
    // No queremos guardar "authenticating" o "logoutInProgress"
    if (state.status == AuthStatus.authenticated ||
        state.status == AuthStatus.unauthenticated ||
        state.status == AuthStatus.failure) {
      return state.toJson();
    }
    // No guardar estados transitorios
    return null;
  }

  // --- TU LÓGICA DE LOGIN/LOGOUT (SIN CAMBIOS) ---
  // (Esta es la lógica que me enviaste en el primer archivo)

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

      try {
        final fcmService = FcmService();
        await fcmService.initialize();
        final fcmToken = await fcmService.getToken();

        if (fcmToken != null) {
          await _authRepository.syncFcmToken(
            fcmToken: fcmToken,
            deviceName: event.deviceName,
            userAuthToken: response.token,
          );
        }
      } catch (e) {
        print('⚠️ Advertencia: No se pudo sincronizar FCM tras login: $e');
      }

      // ¡HydratedBloc guardará este estado automáticamente!
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          token: response.token,
          user: response.user, // 'response.user' es Map<String, dynamic>?
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
      emit(const AuthState(status: AuthStatus.unauthenticated));
      return;
    }

    emit(state.copyWith(status: AuthStatus.logoutInProgress, clearError: true));

    try {
      await _authRepository.logout(token: state.token!);

      // ¡HydratedBloc guardará este estado (vacío)!
      emit(const AuthState(status: AuthStatus.unauthenticated));
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