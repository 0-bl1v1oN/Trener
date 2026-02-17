import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  late final AppDb db;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = AppDbScope.of(context);
  }

  String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy', 'ru_RU').format(d);

  Future<void> _addClient() async {
    final nameController = TextEditingController();

    String gender = 'Не указано';
    String plan = 'Пробный';
    DateTime start = DateTime.now();
    DateTime end = start.add(const Duration(days: 28));

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: start,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                locale: const Locale('ru', 'RU'),
              );

              if (picked == null) return;

              setLocalState(() {
                start = DateTime(picked.year, picked.month, picked.day);
                end = start.add(const Duration(days: 28));
              });
            }

            return AlertDialog(
              title: const Text('Новый клиент'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Имя'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: gender,
                      items: const [
                        DropdownMenuItem(
                          value: 'Не указано',
                          child: Text('Не указано'),
                        ),
                        DropdownMenuItem(value: 'М', child: Text('М')),
                        DropdownMenuItem(value: 'Ж', child: Text('Ж')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() => gender = v);
                      },
                      decoration: const InputDecoration(labelText: 'Пол'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: plan,
                      items: const [
                        DropdownMenuItem(
                          value: 'Пробный',
                          child: Text('Пробный'),
                        ),
                        DropdownMenuItem(value: '4', child: Text('4')),
                        DropdownMenuItem(value: '8', child: Text('8')),
                        DropdownMenuItem(value: '12', child: Text('12')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() => plan = v);
                      },
                      decoration: const InputDecoration(labelText: 'Абонемент'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: pickStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Начало абонемента',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_fmtDate(start)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Конец абонемента (+28 дней)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_fmtDate(end)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final id = DateTime.now().microsecondsSinceEpoch.toString();

    await db.upsertClient(
      ClientsCompanion.insert(
        id: id,
        name: name,
        gender: Value(gender),
        plan: Value(plan),
        planStart: Value(start),
        planEnd: Value(end),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteClient(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить клиента?'),
        content: const Text('Действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await db.deleteClientById(id);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Клиенты'),
          actions: [
            IconButton(
              onPressed: _addClient,
              icon: const Icon(Icons.add),
              tooltip: 'Добавить',
            ),
          ],
        ),
        body: FutureBuilder<List<Client>>(
          future: db.getAllClients(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final clients = snap.data ?? const <Client>[];
            if (clients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Клиентов пока нет',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Нажми «+», чтобы добавить первого клиента',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: clients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = clients[index];
                return _ClientCard(
                  client: c,
                  dateText: (c.planStart != null && c.planEnd != null)
                      ? '${_fmtDate(c.planStart!)} – ${_fmtDate(c.planEnd!)}'
                      : null,
                  onTap: () async {
                    await context.push('/clients/${c.id}');
                    if (!mounted) return;
                    setState(() {});
                  },
                  onDelete: () => _deleteClient(c.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onDelete,
    this.dateText,
  });

  final Client client;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String? dateText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final subtitleParts = <String>[];

    if (client.gender != null) {
      subtitleParts.add('Пол: ${client.gender}');
    }
    if (client.plan != null) {
      subtitleParts.add('Абонемент: ${client.plan}');
    }

    return Card(
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' • '),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (dateText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Удалить',
                color: colors.error,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
