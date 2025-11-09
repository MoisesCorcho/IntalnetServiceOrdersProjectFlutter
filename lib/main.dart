import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/view/auth_gate.dart';
import 'features/service_orders/data/service_order_repository.dart';

void main() {
  final authRepository = AuthRepository();
  final serviceOrderRepository = ServiceOrderRepository(
    baseUrl: authRepository.baseUrl,
  );

  runApp(
    MyApp(
      authRepository: authRepository,
      serviceOrderRepository: serviceOrderRepository,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.authRepository,
    required this.serviceOrderRepository,
  });

  final AuthRepository authRepository;
  final ServiceOrderRepository serviceOrderRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: serviceOrderRepository),
      ],
      child: BlocProvider(
        create: (_) => AuthBloc(authRepository: authRepository),
        child: MaterialApp(
          title: 'Intalnet Service Orders',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}
