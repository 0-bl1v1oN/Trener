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
        final colors = Theme.of(context).colorScheme;
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

            InputDecoration fieldDecor({
              required String label,
              IconData? icon,
            }) {
              return InputDecoration(
                labelText: label,
                prefixIcon: icon == null ? null : Icon(icon, size: 18),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withOpacity(0.35),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Новый клиент',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Заполните данные клиента',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: fieldDecor(
                        label: 'Имя клиента',
                        icon: Icons.person_outline,
                      ),
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: gender,
                      items: const [
                        DropdownMenuItem(
                          value: 'Не указано',
                          child: Text('Не указано'),
                        ),
                        DropdownMenuItem(value: 'М', child: Text('Мужчина')),
                        DropdownMenuItem(value: 'Ж', child: Text('Женщина')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() => gender = v);
                      },
                      decoration: fieldDecor(label: 'Пол', icon: Icons.wc),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: plan,
                      items: const [
                        DropdownMenuItem(
                          value: 'Пробный',
                          child: Text('Пробный'),
                        ),
                        DropdownMenuItem(value: '4', child: Text('4 занятия')),
                        DropdownMenuItem(value: '8', child: Text('8 занятий')),
                        DropdownMenuItem(
                          value: '12',
                          child: Text('12 занятий'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setLocalState(() => plan = v);
                      },
                      decoration: fieldDecor(
                        label: 'Абонемент',
                        icon: Icons.workspace_premium_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: pickStartDate,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Начало абонемента',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_fmtDate(start)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InputDecorator(
                      decoration: fieldDecor(
                        label: 'Конец абонемента (+28 дней)',
                        icon: Icons.event_available_outlined,
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
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Сохранить'),
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

            final maleCount = clients.where((c) => c.gender == 'М').length;
            final femaleCount = clients.where((c) => c.gender == 'Ж').length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              children: [
                _ClientsSummaryCard(
                  total: clients.length,
                  male: maleCount,
                  female: femaleCount,
                ),
                const SizedBox(height: 12),
                ...clients.map((c) {
                  final dateText = (c.planStart != null && c.planEnd != null)
                      ? '${_fmtDate(c.planStart!)} – ${_fmtDate(c.planEnd!)}'
                      : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ClientCard(
                      client: c,
                      dateText: dateText,
                      onTap: () async {
                        await context.push('/clients/${c.id}');
                        if (!mounted) return;
                        setState(() {});
                      },
                      onDelete: () => _deleteClient(c.id),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ClientsSummaryCard extends StatelessWidget {
  const _ClientsSummaryCard({
    required this.total,
    required this.male,
    required this.female,
  });

  final int total;
  final int male;
  final int female;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.16),
            colors.secondary.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: colors.primary.withOpacity(0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'База клиентов',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                icon: Icons.groups_2_outlined,
                label: 'Всего: $total',
              ),
              _SummaryChip(icon: Icons.male, label: 'М: $male'),
              _SummaryChip(icon: Icons.female, label: 'Ж: $female'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
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
    final now = DateTime.now();

    final subtitleParts = <String>[];

    final gender = client.gender ?? '—';
    final plan = client.plan ?? '—';

    int? daysLeft;
    if (client.planEnd != null) {
      final end = DateTime(
        client.planEnd!.year,
        client.planEnd!.month,
        client.planEnd!.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      daysLeft = end.difference(today).inDays;
    }
    Color statusColor = colors.primary;
    String statusText = 'Без даты';
    if (daysLeft != null) {
      if (daysLeft < 0) {
        statusColor = colors.error;
        statusText = 'Истёк';
      } else if (daysLeft <= 3) {
        statusColor = colors.tertiary;
        statusText = 'Скоро конец';
      } else {
        statusColor = colors.primary;
        statusText = 'Активен';
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.surface, colors.primary.withOpacity(0.03)],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaChip(icon: Icons.wc, label: 'Пол: $gender'),
                          _MetaChip(
                            icon: Icons.workspace_premium,
                            label: 'Абонемент: $plan',
                          ),
                          _MetaChip(
                            icon: Icons.circle,
                            iconColor: statusColor,
                            label: statusText,
                          ),
                        ],
                      ),
                      if (dateText != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dateText!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
                          ],
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
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.iconColor});

  final IconData icon;
  final String label;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? colors.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
