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
  int _completedInPlan = 0;

  bool _loaded = false;

  String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy', 'ru_RU').format(d);

  int _planSize(String value) {
    if (value == 'Пробный') return 1;
    return int.tryParse(value) ?? 0;
  }

  int _remainingSessions() {
    final size = _planSize(_plan);
    if (size <= 0) return 0;

    final completedInBundle = _completedInPlan % size;
    if (completedInBundle == 0 && _completedInPlan > 0) return 0;
    return size - completedInBundle;
  }

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
    final overview = await db.getProgramOverview(widget.clientId);
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
      _completedInPlan = overview.st.completedInPlan;
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

  Future<bool> _saveClientData() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
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
    return true;
  }

  Future<void> _save() async {
    final saved = await _saveClientData();
    if (!saved) return;
    if (!mounted) return;
    Navigator.pop(context);
  }

  InputDecoration _fieldDecoration(
    String label,
    ColorScheme colors, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 18),
      filled: true,
      fillColor: colors.surfaceContainerHighest.withOpacity(0.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant.withOpacity(0.75)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Клиент')),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Сохранить'),
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colors.outlineVariant.withOpacity(0.7),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: _fieldDecoration(
                          'Имя',
                          colors,
                          icon: Icons.person_outline,
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
                        onChanged: (v) =>
                            setState(() => _gender = v ?? 'Не указано'),
                        decoration: _fieldDecoration(
                          'Пол',
                          colors,
                          icon: Icons.wc,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _plan,
                        items: const [
                          DropdownMenuItem(
                            value: 'Пробный',
                            child: Text('Пробный'),
                          ),
                          DropdownMenuItem(value: '4', child: Text('4')),
                          DropdownMenuItem(value: '8', child: Text('8')),
                          DropdownMenuItem(value: '12', child: Text('12')),
                        ],
                        onChanged: (v) =>
                            setState(() => _plan = v ?? 'Пробный'),
                        decoration: _fieldDecoration(
                          'Абонемент',
                          colors,
                          icon: Icons.confirmation_num_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colors.outlineVariant.withOpacity(0.7),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: _pickStartDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: _fieldDecoration(
                            'Начало абонемента',
                            colors,
                            icon: Icons.event,
                          ),
                          child: Text(_fmtDate(_start)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: _fieldDecoration(
                          'Конец абонемента (+28 дней)',
                          colors,
                          icon: Icons.event_available,
                        ),
                        child: Text(_fmtDate(_end)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 18,
                              color: colors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Осталось занятий: ${_remainingSessions()}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/clients/${widget.clientId}/program'),
                  icon: const Icon(Icons.view_list),
                  label: const Text('Программа'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
