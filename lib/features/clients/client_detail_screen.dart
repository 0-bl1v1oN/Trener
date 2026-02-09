import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import 'package:go_router/go_router.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late final AppDb db;

  final _nameController = TextEditingController();

  String _gender = 'Не указано';
  String _plan = 'Пробный';
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 28));

  bool _loaded = false;

  String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy', 'ru_RU').format(d);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = AppDbScope.of(context);
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final c = await db.getClientById(widget.clientId);
    if (!mounted) return;

    if (c == null) {
      // Клиент удалён или не найден
      Navigator.pop(context);
      return;
    }

    setState(() {
      _nameController.text = c.name;
      _gender = c.gender ?? 'Не указано';
      _plan = c.plan ?? 'Пробный';
      _start = c.planStart ?? DateTime.now();
      _end = c.planEnd ?? _start.add(const Duration(days: 28));
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      locale: const Locale('ru', 'RU'),
    );

    if (picked == null) return;

    setState(() {
      _start = DateTime(picked.year, picked.month, picked.day);
      _end = _start.add(const Duration(days: 28));
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await db.upsertClient(
      ClientsCompanion.insert(
        id: widget.clientId,
        name: name,
        gender: Value(_gender),
        plan: Value(_plan),
        planStart: Value(_start),
        planEnd: Value(_end),
      ),
    );

    await db.syncProgramStateFromClient(widget.clientId);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Клиент'),
          actions: [
            IconButton(
              onPressed: _save,
              icon: const Icon(Icons.save),
              tooltip: 'Сохранить',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(
                    value: 'Не указано',
                    child: Text('Не указано'),
                  ),
                  DropdownMenuItem(value: 'М', child: Text('М')),
                  DropdownMenuItem(value: 'Ж', child: Text('Ж')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'Не указано'),
                decoration: const InputDecoration(
                  labelText: 'Пол',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _plan,
                items: const [
                  DropdownMenuItem(value: 'Пробный', child: Text('Пробный')),
                  DropdownMenuItem(value: '4', child: Text('4')),
                  DropdownMenuItem(value: '8', child: Text('8')),
                  DropdownMenuItem(value: '12', child: Text('12')),
                ],
                onChanged: (v) => setState(() => _plan = v ?? 'Пробный'),
                decoration: const InputDecoration(
                  labelText: 'Абонемент',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _pickStartDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Начало абонемента',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_fmtDate(_start)),
                ),
              ),
              const SizedBox(height: 12),

              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Конец абонемента (+28 дней)',
                  border: OutlineInputBorder(),
                ),
                child: Text(_fmtDate(_end)),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/clients/${widget.clientId}/program'),
                  icon: const Icon(Icons.view_list),
                  label: const Text('Программа'),
                ),
              ),

              const Text('Нажми 💾 чтобы сохранить изменения.'),
            ],
          ),
        ),
      ),
    );
  }
}
