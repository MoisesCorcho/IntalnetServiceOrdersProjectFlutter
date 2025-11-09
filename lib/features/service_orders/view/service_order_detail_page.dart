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

          final colors = Theme.of(context).colorScheme;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeaderCard(order: order),
                      const SizedBox(height: 24),
                      _LabeledSection(
                        title: 'Resumen',
                        children: [
                          _InfoRow(
                            label: 'Número de orden',
                            value: order.orderNumber,
                          ),
                          _InfoRow(
                            label: 'Descripción',
                            value: order.description,
                          ),
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
                        ],
                      ),
                      const SizedBox(height: 24),
                      _LabeledSection(
                        title: 'Cliente',
                        children: [
                          _InfoRow(label: 'Nombre', value: order.customerName),
                          _InfoRow(
                            label: 'Teléfono',
                            value: order.customerPhone,
                          ),
                          _InfoRow(
                            label: 'Dirección',
                            value: order.customerAddress,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Container(
                  color: colors.surface.withValues(alpha: 0.94),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
    final theme = Theme.of(context);
    final valueText = value?.trim().isNotEmpty == true ? value!.trim() : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(valueText, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusText = order.stateLabel ?? 'Sin estado';
    final statusMeta = _statusMeta(colors, order.state, order.stateLabel);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.title ?? 'Orden #${order.id}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StatusPill(
                  label: statusText,
                  background: statusMeta.background,
                  foreground: statusMeta.foreground,
                  icon: statusMeta.icon,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(label: 'Orden', value: order.orderNumber ?? '—'),
          ],
        ),
      ),
    );
  }

  _StatusMeta _statusMeta(
    ColorScheme colors,
    String? state,
    String? stateLabel,
  ) {
    final stateKey = (state ?? '').toLowerCase();
    final fallbackKey = (stateLabel ?? '').toLowerCase();

    _StatusMeta build(Color background, Color foreground, IconData icon) =>
        _StatusMeta(background: background, foreground: foreground, icon: icon);

    switch (stateKey) {
      case 'received':
        return build(
          colors.tertiaryContainer.withValues(alpha: 0.45),
          colors.onTertiaryContainer,
          Icons.mark_email_read_outlined,
        );
      case 'on_the_way':
        return build(
          colors.secondaryContainer.withValues(alpha: 0.4),
          colors.onSecondaryContainer,
          Icons.local_shipping_outlined,
        );
      case 'at_destination':
        return build(
          colors.secondaryContainer.withValues(alpha: 0.35),
          colors.onSecondaryContainer,
          Icons.location_on_outlined,
        );
      case 'process_started':
      case 'in_process':
        return build(
          colors.secondaryContainer.withValues(alpha: 0.45),
          colors.onSecondaryContainer,
          Icons.build_outlined,
        );
      case 'completed':
        return build(
          colors.primaryContainer.withValues(alpha: 0.45),
          colors.onPrimaryContainer,
          Icons.task_alt_outlined,
        );
      case 'closed':
        return build(
          colors.primaryContainer.withValues(alpha: 0.45),
          colors.onPrimaryContainer,
          Icons.lock_outline,
        );
    }

    if (fallbackKey.contains('recib')) {
      return build(
        colors.tertiaryContainer.withValues(alpha: 0.45),
        colors.onTertiaryContainer,
        Icons.mark_email_read_outlined,
      );
    }
    if (fallbackKey.contains('camino')) {
      return build(
        colors.secondaryContainer.withValues(alpha: 0.4),
        colors.onSecondaryContainer,
        Icons.local_shipping_outlined,
      );
    }
    if (fallbackKey.contains('destino')) {
      return build(
        colors.secondaryContainer.withValues(alpha: 0.35),
        colors.onSecondaryContainer,
        Icons.location_on_outlined,
      );
    }
    if (fallbackKey.contains('proceso')) {
      return build(
        colors.secondaryContainer.withValues(alpha: 0.45),
        colors.onSecondaryContainer,
        Icons.build_outlined,
      );
    }
    if (fallbackKey.contains('complet')) {
      return build(
        colors.primaryContainer.withValues(alpha: 0.45),
        colors.onPrimaryContainer,
        Icons.task_alt_outlined,
      );
    }
    if (fallbackKey.contains('cerr')) {
      return build(
        colors.primaryContainer.withValues(alpha: 0.45),
        colors.onPrimaryContainer,
        Icons.lock_outline,
      );
    }

    return build(
      colors.surfaceContainerHighest.withValues(alpha: 0.5),
      colors.onSurfaceVariant,
      Icons.list_alt_outlined,
    );
  }
}

class _LabeledSection extends StatelessWidget {
  const _LabeledSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
