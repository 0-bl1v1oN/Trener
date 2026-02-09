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
              return const Center(child: Text('Клиентов пока нет'));
            }

            return ListView.separated(
              itemCount: clients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final c = clients[index];

                final parts = <String>[];
                if (c.gender != null) parts.add('Пол: ${c.gender}');
                if (c.plan != null) parts.add('Абонемент: ${c.plan}');
                if (c.planStart != null && c.planEnd != null) {
                  parts.add(
                    '${_fmtDate(c.planStart!)} – ${_fmtDate(c.planEnd!)}',
                  );
                }

                return ListTile(
                  title: Text(c.name),
                  subtitle: parts.isEmpty ? null : Text(parts.join(' • ')),
                  onTap: () async {
                    await context.push('/clients/${c.id}');
                    if (!mounted) return;
                    setState(() {}); // обновить список после возврата
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Удалить',
                    onPressed: () => _deleteClient(c.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
