import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../../service_orders/bloc/service_orders_bloc.dart';
import '../../service_orders/data/service_order_repository.dart';
import '../../service_orders/view/service_orders_section.dart';

class AuthenticatedHome extends StatelessWidget {
  const AuthenticatedHome({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.logoutInProgress &&
          current.status == AuthStatus.failure &&
          current.errorMessage != null,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final token = state.token;
          if (token == null || token.isEmpty) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = state.user;
          final isLoggingOut = state.status == AuthStatus.logoutInProgress;

          return BlocProvider<ServiceOrdersBloc>(
            key: ValueKey(token),
            create: (context) => ServiceOrdersBloc(
              repository: context.read<ServiceOrderRepository>(),
            )..add(ServiceOrdersRequested(token: token)),
            child: _ServiceOrdersScreen(
              user: user,
              token: token,
              isLoggingOut: isLoggingOut,
            ),
          );
        },
      ),
    );
  }
}

class _ServiceOrdersScreen extends StatefulWidget {
  const _ServiceOrdersScreen({
    required this.user,
    required this.token,
    required this.isLoggingOut,
  });

  final Map<String, dynamic>? user;
  final String token;
  final bool isLoggingOut;

  @override
  State<_ServiceOrdersScreen> createState() => _ServiceOrdersScreenState();
}

class _ServiceOrdersScreenState extends State<_ServiceOrdersScreen> {
  String? _selectedStatus;

  static const List<_StatusOption> _statusOptions = [
    _StatusOption(null, 'Todas las órdenes', Icons.list_alt_outlined),
    _StatusOption('received', 'Recibido', Icons.mark_email_read_outlined),
    _StatusOption('on_the_way', 'En camino', Icons.local_shipping_outlined),
    _StatusOption('at_destination', 'En destino', Icons.location_on_outlined),
    _StatusOption('process_started', 'Proceso iniciado', Icons.build_outlined),
    _StatusOption('completed', 'Completado', Icons.task_alt_outlined),
    _StatusOption('closed', 'Cerrado', Icons.lock_outline),
  ];

  void _onStatusSelected(String? status) {
    setState(() {
      _selectedStatus = status;
    });

    final bloc = context.read<ServiceOrdersBloc>();
    bloc.add(
      ServiceOrdersRequested(
        token: widget.token,
        status: status,
        perPage: bloc.state.perPage,
      ),
    );
    Navigator.of(context).pop();
  }

  void _onLogout() {
    Navigator.of(context).pop();
    context.read<AuthBloc>().add(const LogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Servicio de Órdenes')),
      drawer: _OrdersDrawer(
        user: widget.user,
        selectedStatus: _selectedStatus,
        onStatusSelected: _onStatusSelected,
        onLogout: _onLogout,
        isLoggingOut: widget.isLoggingOut,
      ),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: ServiceOrdersSection(),
      ),
    );
  }
}

class _OrdersDrawer extends StatelessWidget {
  const _OrdersDrawer({
    required this.user,
    required this.selectedStatus,
    required this.onStatusSelected,
    required this.onLogout,
    required this.isLoggingOut,
  });

  final Map<String, dynamic>? user;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusSelected;
  final VoidCallback onLogout;
  final bool isLoggingOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name =
        (user?['full_name'] ??
                user?['name'] ??
                user?['first_name'] ??
                user?['last_name'])
            ?.toString();
    final email = user?['email']?.toString() ?? '';
    final trimmed = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : email.trim();
    final initial = trimmed.isNotEmpty
        ? trimmed.substring(0, 1).toUpperCase()
        : 'U';

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(initial, style: theme.textTheme.headlineSmall),
                  ),
                  const SizedBox(height: 12),
                  Text(name ?? 'Técnico', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Filtrar por estado'.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._ServiceOrdersScreenState._statusOptions.map(
                    (option) => ListTile(
                      leading: Icon(option.icon),
                      title: Text(option.label),
                      selected: option.value == selectedStatus,
                      onTap: () => onStatusSelected(option.value),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: isLoggingOut ? null : onLogout,
              trailing: isLoggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption {
  const _StatusOption(this.value, this.label, this.icon);

  final String? value;
  final String label;
  final IconData icon;
}
