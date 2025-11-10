import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart'; // 1. Importado
import 'package:path_provider/path_provider.dart'; // 2. Importado

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/view/auth_gate.dart';
import 'features/service_orders/data/service_order_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 3. Configurar Hydrated Bloc
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );

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
        // 4. Iniciar el BLoC. HydratedBloc se encargará
        //    automáticamente de restaurar el estado aquí.
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