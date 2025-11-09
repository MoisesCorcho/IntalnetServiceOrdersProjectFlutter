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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= state.orders.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(order.title ?? 'Orden #${order.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order.stateLabel != null)
              Text('Estado: ${order.stateLabel}', style: _mutedStyle),
            if (order.customerName != null)
              Text('Cliente: ${order.customerName}', style: _mutedStyle),
            if (order.scheduledAt != null)
              Text(
                'Programada: ${_formatDate(order.scheduledAt)}',
                style: _mutedStyle,
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  TextStyle get _mutedStyle => const TextStyle(fontSize: 12);

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '—';
    }
    return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
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
