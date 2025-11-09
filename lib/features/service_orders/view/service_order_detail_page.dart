import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../bloc/service_orders_bloc.dart';
import '../cubit/service_order_detail_cubit.dart';
import '../data/service_order_repository.dart';
import '../models/service_order.dart';

class ServiceOrderDetailPage extends StatelessWidget {
  const ServiceOrderDetailPage({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  final int orderId;
  final ServiceOrder? initialOrder;

  @override
  Widget build(BuildContext context) {
    final token = context.select<AuthBloc, String?>((bloc) => bloc.state.token);

    if (token == null) {
      return const Scaffold(body: Center(child: Text('Sesión no válida.')));
    }

    return BlocProvider(
      create: (context) => ServiceOrderDetailCubit(
        repository: context.read<ServiceOrderRepository>(),
      )..load(token: token, orderId: orderId, initialOrder: initialOrder),
      child: _ServiceOrderDetailView(orderId: orderId),
    );
  }
}

class _ServiceOrderDetailView extends StatelessWidget {
  const _ServiceOrderDetailView({required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Orden #$orderId')),
      body: BlocConsumer<ServiceOrderDetailCubit, ServiceOrderDetailState>(
        listener: (context, state) {
          if (state.status == ServiceOrderDetailStatus.failure &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.order == null && state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = state.order;
          if (order == null) {
            return const Center(child: Text('No se pudo cargar la orden.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _InfoRow(label: 'Título', value: order.title),
                    _InfoRow(label: 'Estado', value: order.stateLabel),
                    _InfoRow(
                      label: 'Número de orden',
                      value: order.orderNumber,
                    ),
                    _InfoRow(label: 'Descripción', value: order.description),
                    _InfoRow(
                      label: 'Entrada',
                      value: _formatDate(order.checkInDate),
                    ),
                    _InfoRow(
                      label: 'Programada',
                      value: _formatDate(order.scheduledAt),
                    ),
                    _InfoRow(
                      label: 'Completada',
                      value: _formatDate(order.completedAt),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cliente',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Nombre', value: order.customerName),
                    _InfoRow(label: 'Teléfono', value: order.customerPhone),
                    _InfoRow(label: 'Dirección', value: order.customerAddress),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          state.status == ServiceOrderDetailStatus.advancing
                          ? null
                          : () async {
                              final updated = await context
                                  .read<ServiceOrderDetailCubit>()
                                  .advanceState();
                              if (updated != null && context.mounted) {
                                context.read<ServiceOrdersBloc>().add(
                                  ServiceOrderUpdated(order: updated),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Estado actualizado correctamente.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: state.status == ServiceOrderDetailStatus.advancing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Avanzar estado'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '—';
    }
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} '
        '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(value?.isNotEmpty == true ? value! : '—'),
          ),
        ],
      ),
    );
  }
}
