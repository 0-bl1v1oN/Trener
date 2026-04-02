import 'dart:async';
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
  late AppDb db;

  final _nameController = TextEditingController();

  Timer? _autosaveTimer;
  String _gender = 'Не указано';
  String _plan = 'Пробный';
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 28));
  int _completedInPlan = 0;

  bool _loaded = false;
  bool _isHydrating = true;
  bool _isSaving = false;
  bool _saveQueued = false;
  String? _lastSavedSnapshot;

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

  String _buildClientSnapshot() {
    return [
      _nameController.text.trim(),
      _gender,
      _plan,
      _start.millisecondsSinceEpoch,
      _end.millisecondsSinceEpoch,
    ].join('|');
  }

  void _scheduleAutosave({Duration delay = const Duration(milliseconds: 500)}) {
    if (!_loaded || _isHydrating) return;

    final snapshot = _buildClientSnapshot();
    if (snapshot == _lastSavedSnapshot) return;

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(delay, () {
      unawaited(_flushAutosave());
    });
  }

  Future<void> _flushAutosave() async {
    _autosaveTimer?.cancel();
    if (!_loaded || _isHydrating) return;

    final snapshot = _buildClientSnapshot();
    if (snapshot == _lastSavedSnapshot) return;

    if (_isSaving) {
      _saveQueued = true;
      return;
    }

    _setSaving(true);
    final saved = await _saveClientData();
    if (saved) {
      _lastSavedSnapshot = snapshot;
    }
    _setSaving(false);

    if (_saveQueued) {
      _saveQueued = false;
      _scheduleAutosave(delay: Duration.zero);
    }
  }

  void _updateClient(VoidCallback applyChanges) {
    setState(applyChanges);
    _scheduleAutosave();
  }

  void _onNameChanged() {
    _scheduleAutosave();
  }

  void _setSaving(bool value) {
    if (_isSaving == value) return;
    if (!mounted) {
      _isSaving = value;
      return;
    }

    setState(() {
      _isSaving = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
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

    _isHydrating = true;
    setState(() {
      _nameController.text = c.name;
      _gender = c.gender ?? 'Не указано';
      _plan = c.plan ?? 'Пробный';
      _start = c.planStart ?? DateTime.now();
      _end = c.planEnd ?? _start.add(const Duration(days: 28));
      _completedInPlan = overview.st.completedInPlan;
    });
    _lastSavedSnapshot = _buildClientSnapshot();
    _isHydrating = false;
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
    final normalizedPicked = DateTime(picked.year, picked.month, picked.day);
    final previousDefaultEnd = _start.add(const Duration(days: 28));

    _updateClient(() {
      _start = normalizedPicked;
      if (_end == previousDefaultEnd) {
        _end = _start.add(const Duration(days: 28));
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end.isBefore(_start) ? _start : _end,
      firstDate: _start,
      lastDate: DateTime(2035, 12, 31),
      locale: const Locale('ru', 'RU'),
    );

    if (picked == null) return;

    _updateClient(() {
      _end = DateTime(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _purchaseSubscription() async {
    final current = await db.getClientById(widget.clientId);
    if (current == null) return;
    if (current.plan == null || current.plan == 'Пробный') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выбери абонемент 4/8/12 для клиента'),
        ),
      );
      return;
    }

    final initialDate = current.planEnd ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      locale: const Locale('ru', 'RU'),
    );

    if (picked == null) return;
    final startDate = DateTime(picked.year, picked.month, picked.day);
    final nextEnd = startDate.add(const Duration(days: 28));

    await db.renewClientPlanKeepingProgramDay(
      clientId: current.id,
      startDate: startDate,
      days: 28,
    );

    await db.clearClientPlanEndAlertOverride(current.id);

    await _load();
    if (!mounted) return;
    final startFmt = DateFormat('dd.MM.yyyy', 'ru_RU').format(startDate);
    final endFmt = DateFormat('dd.MM.yyyy', 'ru_RU').format(nextEnd);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Абонемент продлён: с $startFmt до $endFmt')),
    );
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

  InputDecoration _fieldDecoration(
    String label,
    ColorScheme colors, {
    String? iconAsset,
    IconData? fallbackIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: iconAsset == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                iconAsset,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  fallbackIcon ?? Icons.image_not_supported_outlined,
                  size: 18,
                ),
              ),
            ),
      filled: true,
      fillColor: colors.surfaceContainerHighest.withOpacity(0.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outlineVariant.withOpacity(0.75)),
      ),
    );
  }

  DateTime _recordsWeekStart(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    if (day.weekday == DateTime.sunday) {
      return day.add(const Duration(days: 1));
    }
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  String _weekdayShortRu(int weekday) {
    const map = {
      DateTime.monday: 'Пн',
      DateTime.tuesday: 'Вт',
      DateTime.wednesday: 'Ср',
      DateTime.thursday: 'Чт',
      DateTime.friday: 'Пт',
      DateTime.saturday: 'Сб',
    };
    return map[weekday] ?? '';
  }

  Widget _buildWeekRecordsCard(ColorScheme colors) {
    final now = DateTime.now();
    final weekStart = _recordsWeekStart(now);
    final weekEndExclusive = weekStart.add(const Duration(days: 6));
    final days = List.generate(6, (i) => weekStart.add(Duration(days: i)));

    final titleRange =
        '${_fmtDate(weekStart)} — ${_fmtDate(weekEndExclusive.subtract(const Duration(days: 1)))}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.08),
            colors.secondary.withOpacity(0.03),
          ],
        ),
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Image.asset(
                      'assets/clients/client_records.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.edit_calendar_outlined,
                        size: 16,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Записи',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                titleRange,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<Appointment>>(
                stream: db.watchAppointmentsForClientInRange(
                  clientId: widget.clientId,
                  fromInclusive: weekStart,
                  toExclusive: weekEndExclusive,
                ),
                builder: (context, snap) {
                  final items = snap.data ?? const <Appointment>[];
                  final byDay = <DateTime, List<Appointment>>{};
                  for (final a in items) {
                    final key = DateTime(
                      a.startAt.year,
                      a.startAt.month,
                      a.startAt.day,
                    );
                    byDay.putIfAbsent(key, () => <Appointment>[]).add(a);
                  }

                  return Column(
                    children: [
                      for (final day in days) ...[
                        _WeekDayRecordsRow(
                          dayLabel:
                              '${_weekdayShortRu(day.weekday)} ${DateFormat('dd.MM').format(day)}',
                          appointments: byDay[day] ?? const <Appointment>[],
                        ),
                        if (day != days.last) const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _autosaveTimer?.cancel();
    if (!_isHydrating && _buildClientSnapshot() != _lastSavedSnapshot) {
      unawaited(_saveClientData());
    }
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Клиент'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSaving
                      ? const SizedBox(
                          key: ValueKey('saving'),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.cloud_done_outlined,
                          key: const ValueKey('saved'),
                          size: 20,
                          color: colors.primary,
                        ),
                ),
              ),
            ),
          ],
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
                          iconAsset: 'assets/clients/client_name.png',
                          fallbackIcon: Icons.person_outline,
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
                            _updateClient(() => _gender = v ?? 'Не указано'),
                        decoration: _fieldDecoration(
                          'Пол',
                          colors,
                          iconAsset: 'assets/clients/client_gender.png',
                          fallbackIcon: Icons.wc,
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
                            _updateClient(() => _plan = v ?? 'Пробный'),
                        decoration: _fieldDecoration(
                          'Абонемент',
                          colors,
                          iconAsset: 'assets/clients/client_plan.png',
                          fallbackIcon: Icons.confirmation_num_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Все изменения сохраняются автоматически.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
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
                            iconAsset: 'assets/clients/client_plan_start.png',
                            fallbackIcon: Icons.event,
                          ),
                          child: Text(_fmtDate(_start)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickEndDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration:
                              _fieldDecoration(
                                'Конец абонемента',
                                colors,
                                iconAsset: 'assets/clients/client_plan_end.png',
                                fallbackIcon: Icons.event_available,
                              ).copyWith(
                                helperText:
                                    'По умолчанию: +28 дней от даты начала',
                              ),
                          child: Text(_fmtDate(_end)),
                        ),
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
                            Image.asset(
                              'assets/clients/client_sessions_left.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.fitness_center,
                                size: 18,
                                color: colors.onPrimaryContainer,
                              ),
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
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _purchaseSubscription,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: colors.secondaryContainer
                                .withOpacity(0.44),
                            foregroundColor: colors.onSecondaryContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                            side: BorderSide(
                              color: colors.outlineVariant.withOpacity(0.22),
                            ),
                            textStyle: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          icon: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 20,
                          ),
                          label: const Text('Покупка абонемента'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildWeekRecordsCard(colors),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await context.push('/clients/${widget.clientId}/program');
                    if (!mounted) return;
                    await _load();
                  },
                  icon: Image.asset(
                    'assets/clients/client_program.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.view_list),
                  ),
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

class _WeekDayRecordsRow extends StatelessWidget {
  const _WeekDayRecordsRow({
    required this.dayLabel,
    required this.appointments,
  });

  final String dayLabel;
  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              dayLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: appointments.isEmpty
                ? Text(
                    '—',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final a in appointments)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.primary.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            DateFormat('HH:mm').format(a.startAt),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
