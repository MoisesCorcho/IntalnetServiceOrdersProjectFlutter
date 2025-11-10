import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Esta función debe estar FUERA de cualquier clase (top-level)
// Maneja los mensajes cuando la app está en segundo plano o terminada.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Inicializa el servicio, pide permisos y configura los listeners
  Future<void> initialize() async {
    // 1. Solicitar permisos (Crítico para iOS, buena práctica en Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }

    // 2. Configurar handler de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Listener para mensajes en primer plano (cuando la app está abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      }
      // AQUÍ PUEDES AGREGAR LÓGICA PARA MOSTRAR UN SNACKBAR O DIÁLOGO SI QUIERES
      // Por ejemplo, podrías usar un StreamController para notificar a la UI.
    });
  }

  // Obtiene el token FCM actual del dispositivo
  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  // Stream para escuchar si el token cambia (poco común pero posible)
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;
}