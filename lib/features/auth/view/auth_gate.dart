import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import 'authenticated_home.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final shouldShowHome =
            state.isAuthenticated ||
            state.status == AuthStatus.logoutInProgress;

        if (shouldShowHome) {
          return const AuthenticatedHome();
        }

        return const LoginPage();
      },
    );
  }
}
