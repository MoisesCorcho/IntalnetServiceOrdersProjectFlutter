// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intalnet_service_orders_project/features/auth/data/auth_repository.dart';
import 'package:intalnet_service_orders_project/features/service_orders/data/service_order_repository.dart';
import 'package:intalnet_service_orders_project/main.dart';

void main() {
  testWidgets('se muestra la pantalla de login por defecto', (tester) async {
    final authRepository = AuthRepository();
    final serviceOrderRepository = ServiceOrderRepository(
      baseUrl: authRepository.baseUrl,
    );

    await tester.pumpWidget(
      MyApp(
        authRepository: authRepository,
        serviceOrderRepository: serviceOrderRepository,
      ),
    );

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
