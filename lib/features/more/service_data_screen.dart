import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class ServiceDataScreen extends StatefulWidget {
  const ServiceDataScreen({super.key});

  @override
  State<ServiceDataScreen> createState() => _ServiceDataScreenState();
}

class _ServiceDataScreenState extends State<ServiceDataScreen> {
  AppDb? _db;
  late Future<_ServiceData> _future;
  String? _selectedClientId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDbScope.of(context);
    if (identical(_db, db)) return;
    _db = db;
    _selectedClientId = null;
    _future = _load(db);
  }

  Future<_ServiceData> _load(AppDb db) async {
    await db.ensureExternalIdentities();
    final trainerUuid = await db.getTrainerUuid();
    final activeClients = await db.getAllClients();
    final archivedClients = await db.getArchivedClients();
    final clients = [...activeClients, ...archivedClients]
      ..sort((a, b) => a.name.compareTo(b.name));
    return _ServiceData(trainerUuid: trainerUuid, clients: clients);
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('UUID скопирован')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Служебные данные')),
      body: FutureBuilder<_ServiceData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Не удалось загрузить UUID: ${snapshot.error}'),
            );
          }

          final data = snapshot.data!;
          final selectedClient = data.clients
              .where((client) => client.id == _selectedClientId)
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _IdentityBlock(
                title: 'Тренер',
                icon: Icons.badge_outlined,
                child: _UuidValue(
                  label: 'UUID тренера',
                  value: data.trainerUuid,
                  onCopy: () => _copy(data.trainerUuid),
                ),
              ),
              const SizedBox(height: 14),
              _IdentityBlock(
                title: 'Клиент',
                icon: Icons.person_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.clients.isEmpty)
                      const Text('Клиентов пока нет')
                    else
                      DropdownButtonFormField<String>(
                        initialValue: _selectedClientId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Выберите клиента',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final client in data.clients)
                            DropdownMenuItem(
                              value: client.id,
                              child: Text(
                                client.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedClientId = value);
                        },
                      ),
                    if (selectedClient != null) ...[
                      const SizedBox(height: 18),
                      Text(
                        selectedClient.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      _UuidValue(
                        label: 'UUID клиента',
                        value: selectedClient.externalId ?? '—',
                        onCopy: selectedClient.externalId == null
                            ? null
                            : () => _copy(selectedClient.externalId!),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceData {
  const _ServiceData({required this.trainerUuid, required this.clients});

  final String trainerUuid;
  final List<Client> clients;
}

class _IdentityBlock extends StatelessWidget {
  const _IdentityBlock({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _UuidValue extends StatelessWidget {
  const _UuidValue({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Копировать'),
        ),
      ],
    );
  }
}
