import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/bloc/auth_bloc.dart';
import '../bloc/service_orders_bloc.dart';
import '../models/service_order.dart';
import 'service_order_detail_page.dart';

class ServiceOrdersSection extends StatefulWidget {
  const ServiceOrdersSection({super.key});

  @override
  State<ServiceOrdersSection> createState() => _ServiceOrdersSectionState();
}

class _ServiceOrdersSectionState extends State<ServiceOrdersSection> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ServiceOrdersList(controller: _scrollController);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels <= 200) {
      context.read<ServiceOrdersBloc>().add(const ServiceOrdersLoadMore());
    }
  }
}

class _ServiceOrdersList extends StatelessWidget {
  const _ServiceOrdersList({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceOrdersBloc, ServiceOrdersState>(
      builder: (context, state) {
        if (state.status == ServiceOrdersStatus.loading &&
            state.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.hasError && state.orders.isEmpty) {
          return _ErrorView(
            message:
                state.errorMessage ??
                'No se pudieron cargar las órdenes de servicio.',
            onRetry: () {
              final bloc = context.read<ServiceOrdersBloc>();
              if (bloc.state.token == null) {
                return;
              }
              bloc.add(const ServiceOrdersRefreshed());
            },
          );
        }

        if (state.orders.isEmpty) {
          return _EmptyView(
            onRetry: () {
              final bloc = context.read<ServiceOrdersBloc>();
              if (bloc.state.token == null) {
                return;
              }
              bloc.add(const ServiceOrdersRefreshed());
            },
          );
        }

        final showLoader = state.isLoadingMore;
        final itemCount = state.orders.length + (showLoader ? 1 : 0);

        return RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<ServiceOrdersBloc>();
            bloc.add(const ServiceOrdersRefreshed());
            await bloc.stream.firstWhere(
              (updated) => updated.status != ServiceOrdersStatus.refreshing,
            );
          },
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= state.orders.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final order = state.orders[index];
              return _ServiceOrderTile(
                order: order,
                onTap: () async {
                  final ordersBloc = context.read<ServiceOrdersBloc>();
                  final authBloc = context.read<AuthBloc>();

                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: ordersBloc),
                          BlocProvider.value(value: authBloc),
                        ],
                        child: ServiceOrderDetailPage(
                          orderId: order.id,
                          initialOrder: order,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 16),
          ),
        );
      },
    );
  }
}

class _ServiceOrderTile extends StatelessWidget {
  const _ServiceOrderTile({required this.order, required this.onTap});

  final ServiceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = order.title ?? 'Orden #${order.id}';
    final statusLabel = order.stateLabel ?? 'Sin estado';
    final scheduledDate = _formatDate(order.scheduledAt);
    final statusMeta = _statusMeta(colors);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatusPill(
                  label: statusLabel,
                  background: statusMeta.background,
                  foreground: statusMeta.foreground,
                  icon: statusMeta.icon,
                ),
                if (order.customerName != null || order.scheduledAt != null)
                  const SizedBox(height: 16),
                if (order.customerName != null)
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: order.customerName!,
                  ),
                if (order.customerName != null && order.scheduledAt != null)
                  const SizedBox(height: 8),
                if (order.scheduledAt != null)
                  _InfoRow(
                    icon: Icons.event_outlined,
                    label: 'Programada: $scheduledDate',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '—';
    }
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  _StatusMeta _statusMeta(ColorScheme colors) {
    final stateKey = (order.state ?? '').toLowerCase();
    final labelKey = (order.stateLabel ?? '').toLowerCase();

    _StatusMeta metaFor({
      required Color background,
      required Color foreground,
      required IconData icon,
    }) =>
        _StatusMeta(
          background: background,
          foreground: foreground,
          icon: icon,
        );

    switch (stateKey) {
      case 'received':
        return metaFor(
          background: colors.tertiaryContainer.withValues(alpha: 0.45),
          foreground: colors.onTertiaryContainer,
          icon: Icons.mark_email_read_outlined,
        );
      case 'on_the_way':
        return metaFor(
          background: colors.secondaryContainer.withValues(alpha: 0.4),
          foreground: colors.onSecondaryContainer,
          icon: Icons.local_shipping_outlined,
        );
      case 'at_destination':
        return metaFor(
          background: colors.secondaryContainer.withValues(alpha: 0.35),
          foreground: colors.onSecondaryContainer,
          icon: Icons.location_on_outlined,
        );
      case 'process_started':
      case 'in_process':
        return metaFor(
          background: colors.secondaryContainer.withValues(alpha: 0.45),
          foreground: colors.onSecondaryContainer,
          icon: Icons.build_outlined,
        );
      case 'completed':
        return metaFor(
          background: colors.primaryContainer.withValues(alpha: 0.45),
          foreground: colors.onPrimaryContainer,
          icon: Icons.task_alt_outlined,
        );
      case 'closed':
        return metaFor(
          background: colors.primaryContainer.withValues(alpha: 0.45),
          foreground: colors.onPrimaryContainer,
          icon: Icons.lock_outline,
        );
    }

    if (labelKey.contains('recib')) {
      return metaFor(
        background: colors.tertiaryContainer.withValues(alpha: 0.45),
        foreground: colors.onTertiaryContainer,
        icon: Icons.mark_email_read_outlined,
      );
    }
    if (labelKey.contains('camino')) {
      return metaFor(
        background: colors.secondaryContainer.withValues(alpha: 0.4),
        foreground: colors.onSecondaryContainer,
        icon: Icons.local_shipping_outlined,
      );
    }
    if (labelKey.contains('destino')) {
      return metaFor(
        background: colors.secondaryContainer.withValues(alpha: 0.35),
        foreground: colors.onSecondaryContainer,
        icon: Icons.location_on_outlined,
      );
    }
    if (labelKey.contains('proceso')) {
      return metaFor(
        background: colors.secondaryContainer.withValues(alpha: 0.45),
        foreground: colors.onSecondaryContainer,
        icon: Icons.build_outlined,
      );
    }
    if (labelKey.contains('complet')) {
      return metaFor(
        background: colors.primaryContainer.withValues(alpha: 0.45),
        foreground: colors.onPrimaryContainer,
        icon: Icons.task_alt_outlined,
      );
    }
    if (labelKey.contains('cerr')) {
      return metaFor(
        background: colors.primaryContainer.withValues(alpha: 0.45),
        foreground: colors.onPrimaryContainer,
        icon: Icons.lock_outline,
      );
    }

    return metaFor(
      background: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      foreground: colors.onSurfaceVariant,
      icon: Icons.list_alt_outlined,
    );
  }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      ],
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No hay órdenes asignadas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Actualizar')),
          ],
        ),
      ),
    );
  }
}
