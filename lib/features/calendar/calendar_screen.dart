import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import 'package:drift/drift.dart' show Value;

import 'package:flutter/services.dart';

import 'package:myfitness/theme_controller.dart';
import 'dart:async';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarCategory {
  final String id;
  final String name;
  final Color color;
  final bool isSystem;
  final bool visible;

  const _CalendarCategory({
    required this.id,
    required this.name,
    required this.color,
    this.isSystem = false,
    this.visible = true,
  });

  _CalendarCategory copyWith({
    String? id,
    String? name,
    Color? color,
    bool? isSystem,
    bool? visible,
  }) {
    return _CalendarCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      isSystem: isSystem ?? this.isSystem,
      visible: visible ?? this.visible,
    );
  }
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late final AppDb db;
  bool _dbInited = false;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final Map<DateTime, int> _workApptCountByDay = {};
  final Map<DateTime, int> _trialApptCountByDay = {};
  final Map<DateTime, int> _planEndCountByDay = {};

  static const String _workCategoryId = 'work';
  static const String _trialCategoryId = 'trial';

  List<_CalendarCategory> _categories = const [
    _CalendarCategory(
      id: _workCategoryId,
      name: 'Работа',
      color: Color(0xFF4E6CC8),
      isSystem: true,
      visible: true,
    ),
    _CalendarCategory(
      id: _trialCategoryId,
      name: 'Пробный',
      color: Color(0xFFFF9F43),
      isSystem: true,
      visible: true,
    ),
  ];

  StreamSubscription<Map<DateTime, int>>? _workCountsSub;
  StreamSubscription<Map<DateTime, int>>? _trialCountsSub;
  StreamSubscription<Map<DateTime, int>>? _planEndCountsSub;
  DateTime? _countsFrom;
  DateTime? _countsTo;

  TimeOfDay? _lastTime;

  // один контроллер списка (используем его)
  final ScrollController _appointmentsController = ScrollController();
  bool _userDragging = false;
  double _dragSum = 0;
  bool _toggledThisDrag = false;

  static const double _gestureThreshold = 26; // пиксели "намеренного" свайпа

  // формат календаря
  // формат, который реально отрисовывает TableCalendar
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // защита от дерганья
  bool _collapseLock = false;
  bool _openingCategoriesFromRoute = false;

  static const String _attendanceMarker = '[attended]';

  bool _isAppointmentDone(Appointment appointment) =>
      appointment.note?.contains(_attendanceMarker) == true;

  String? _withAttendanceMarker(String? note, bool done) {
    final current = (note ?? '').replaceAll(_attendanceMarker, '').trim();
    if (!done) return current.isEmpty ? null : current;
    return current.isEmpty ? _attendanceMarker : '$current $_attendanceMarker';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_dbInited) {
      db = AppDbScope.of(context);
      _dbInited = true;

      // стартуем подписку 1 раз
      _setCountsWindow(_focusedDay);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _workCountsSub?.cancel();
    _trialCountsSub?.cancel();
    _planEndCountsSub?.cancel();
    _appointmentsController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeek(DateTime d) {
    final day = _dateOnly(d);
    return day.subtract(Duration(days: day.weekday - 1)); // monday
  }

  void _setCountsWindow(DateTime anchor) {
    final a = _dateOnly(anchor);

    DateTime from;
    DateTime to;

    if (_calendarFormat == CalendarFormat.week) {
      from = _startOfWeek(a);
      to = from.add(const Duration(days: 7));
    } else {
      from = DateTime(a.year, a.month, 1);
      to = DateTime(a.year, a.month + 1, 1);
    }

    // буфер, чтобы на сетке месяца точки на "хвостах" тоже показывались
    from = from.subtract(const Duration(days: 7));
    to = to.add(const Duration(days: 7));

    if (_countsFrom == from && _countsTo == to) return;
    _countsFrom = from;
    _countsTo = to;

    _workCountsSub?.cancel();
    _trialCountsSub?.cancel();
    _planEndCountsSub?.cancel();

    _workCountsSub = db
        .watchAppointmentCountsByDay(from: from, to: to, onlyTrial: false)
        .listen((m) {
          if (!mounted) return;
          setState(() {
            _workApptCountByDay
              ..clear()
              ..addAll(m);
          });
        });

    _trialCountsSub = db
        .watchAppointmentCountsByDay(from: from, to: to, onlyTrial: true)
        .listen((m) {
          if (!mounted) return;
          setState(() {
            _trialApptCountByDay
              ..clear()
              ..addAll(m);
          });
        });

    _planEndCountsSub = db.watchPlanEndCountsByDay(from: from, to: to).listen((
      m,
    ) {
      setState(() {
        _planEndCountByDay
          ..clear()
          ..addAll(m);
      });
    });
  }

  void _armScrollLock() {
    _collapseLock = true;
    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      _collapseLock = false;
    });
  }

  void _collapseToWeek() {
    if (_calendarFormat == CalendarFormat.week) return;
    setState(() {
      _calendarFormat = CalendarFormat.week;
      // При схлопывании всегда привязываемся к выбранному дню,
      // иначе после листания месяцев может открыться "чужая" неделя.
      _focusedDay = _selectedDay;
    });
    _setCountsWindow(_focusedDay);
    _armScrollLock();
  }

  void _expandToMonth() {
    if (_calendarFormat == CalendarFormat.month) return;
    setState(() => _calendarFormat = CalendarFormat.month);
    _setCountsWindow(_focusedDay);
    _armScrollLock();
  }

  bool _onListScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (_collapseLock) return false;

    // фиксируем: пользователь тащит пальцем (а не инерция)
    if (n is ScrollStartNotification) {
      _userDragging = n.dragDetails != null;
      _dragSum = 0;
      _toggledThisDrag = false;
      return false;
    }

    if (n is ScrollEndNotification) {
      _userDragging = false;
      _dragSum = 0;
      _toggledThisDrag = false;
      return false;
    }

    if (!_userDragging || _toggledThisDrag) return false;

    double delta = 0;
    if (n is ScrollUpdateNotification) {
      delta = n.scrollDelta ?? 0;
    } else if (n is OverscrollNotification) {
      delta = n.overscroll;
    } else {
      return false;
    }

    _dragSum += delta.abs();
    if (_dragSum < _gestureThreshold) return false;

    // Вверх -> схлопываем
    if (delta > 0 && _calendarFormat != CalendarFormat.week) {
      _toggledThisDrag = true;
      _collapseToWeek();
      return false;
    }

    // Вниз у верхней границы -> раскрываем
    if (delta < 0 &&
        n.metrics.pixels <= 0 &&
        _calendarFormat != CalendarFormat.month) {
      _toggledThisDrag = true;
      _expandToMonth();
      return false;
    }

    return false;
  }

  String _fmtDate(DateTime d) => DateFormat('d MMMM y', 'ru_RU').format(d);
  String _fmtTime(DateTime d) => DateFormat('HH:mm', 'ru_RU').format(d);

  DateTime _combine(DateTime day, TimeOfDay t) =>
      DateTime(day.year, day.month, day.day, t.hour, t.minute);

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    final hCtrl = TextEditingController(text: '');
    final mCtrl = TextEditingController(text: '');

    final hFocus = FocusNode();
    final mFocus = FocusNode();

    TimeOfDay? result;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Время'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Сейчас: ${initial.hour.toString().padLeft(2, '0')}:${initial.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hCtrl,
                      focusNode: hFocus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),

                      inputFormatters: [
                        // только цифры, максимум 2 символа
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (v) {
                        if (v.length == 2) {
                          mFocus.requestFocus(); // авто-переход на минуты
                        }
                      },
                      onSubmitted: (_) => mFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: mCtrl,
                      focusNode: mFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onSubmitted: (_) => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final hs = hCtrl.text.trim();
                final ms = mCtrl.text.trim();

                if (hs.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Введите часы')));
                  hFocus.requestFocus();
                  return;
                }

                // часы: 1 цифра -> 0X
                final hh = (hs.length == 1) ? '0$hs' : hs;

                // минуты: пусто -> 00, 1 цифра -> 0X
                final mm = ms.isEmpty ? '00' : (ms.length == 1 ? '0$ms' : ms);

                final h = int.tryParse(hh) ?? -1;
                final m = int.tryParse(mm) ?? -1;

                if (h < 0 || h > 23 || m < 0 || m > 59) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Неверное время')),
                  );
                  return;
                }

                result = TimeOfDay(hour: h, minute: m);
                Navigator.pop(context);
              },
              child: const Text('Ок'),
            ),
          ],
        );
      },
    );

    hFocus.dispose();
    mFocus.dispose();

    return result;
  }

  // --- UI Entry points ---
  Future<void> _openAddMenu({TimeOfDay? prefillTime}) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add_alt_1),
              title: const Text('Новый клиент'),
              onTap: () async {
                Navigator.pop(context);
                await _addNewClientAndAppointment(prefillTime: prefillTime);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_search),
              title: const Text('Существующий клиент'),
              onTap: () async {
                Navigator.pop(context);
                await _addExistingClientAppointment(prefillTime: prefillTime);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isCategoryVisible(String id) {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return true;
    return _categories[idx].visible;
  }

  Color _categoryColor(String id, Color fallback) {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return fallback;
    return _categories[idx].color;
  }

  Future<void> _openCategoriesSheet() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> createCategory() async {
              final nameController = TextEditingController();
              Color selectedColor = _categoryColor(
                _workCategoryId,
                Theme.of(context).colorScheme.primary,
              );

              final created = await showDialog<_CalendarCategory>(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setDialogState) {
                      return AlertDialog(
                        title: const Text('Создать категорию'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              maxLength: 50,
                              decoration: const InputDecoration(
                                hintText: 'Введите название',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Цвет',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              children:
                                  [
                                    _categoryColor(
                                      _workCategoryId,
                                      const Color(0xFF4E6CC8),
                                    ),
                                    _categoryColor(
                                      _trialCategoryId,
                                      const Color(0xFFFF9F43),
                                    ),
                                  ].map((c) {
                                    final selected =
                                        c.value == selectedColor.value;
                                    return GestureDetector(
                                      onTap: () => setDialogState(
                                        () => selectedColor = c,
                                      ),
                                      child: Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: c,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: selected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Отмена'),
                          ),
                          FilledButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;
                              Navigator.pop(
                                context,
                                _CalendarCategory(
                                  id: DateTime.now().microsecondsSinceEpoch
                                      .toString(),
                                  name: name,
                                  color: selectedColor,
                                  isSystem: false,
                                  visible: true,
                                ),
                              );
                            },
                            child: const Text('Сохранить'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (created == null || !mounted) return;
              setState(() => _categories = [..._categories, created]);
              setLocalState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Категории',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Работа и Пробный используются автоматически по типу абонемента.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    ..._categories.asMap().entries.map((entry) {
                      final i = entry.key;
                      final c = entry.value;
                      return SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: c.visible,
                        onChanged: (v) {
                          final next = c.copyWith(visible: v);
                          setState(() {
                            _categories = [..._categories]..[i] = next;
                          });
                          setLocalState(() {});
                        },
                        title: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(c.name)),
                          ],
                        ),
                        subtitle: c.isSystem
                            ? const Text('Системная категория')
                            : null,
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: createCategory,
                      icon: const Icon(Icons.add),
                      label: const Text('Создать категорию'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addExistingClientAppointment({TimeOfDay? prefillTime}) async {
    final clients = await db.getAllClients();
    clients.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    if (!mounted) return;

    if (clients.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Сначала добавьте клиента')));
      return;
    }

    String selectedClientId = clients.first.id;

    DateTime startDate = _selectedDay;

    TimeOfDay time =
        prefillTime ?? _lastTime ?? const TimeOfDay(hour: 10, minute: 0);

    final selectedWeekdays = <int>{_selectedDay.weekday};
    bool useSchedule = false;
    int weeks = 4;
    String clientQuery = '';

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                locale: const Locale('ru', 'RU'),
              );
              if (picked == null) return;
              setLocalState(() {
                startDate = DateTime(picked.year, picked.month, picked.day);
                selectedWeekdays
                  ..clear()
                  ..add(startDate.weekday);
              });
            }

            Future<void> pickTime() async {
              final picked = await _pickTime(time);
              if (picked == null) return;
              setLocalState(() => time = picked);
            }

            void toggleWeekday(int wd) {
              setLocalState(() {
                if (selectedWeekdays.contains(wd)) {
                  selectedWeekdays.remove(wd);
                } else {
                  selectedWeekdays.add(wd);
                }
                if (selectedWeekdays.isEmpty) {
                  selectedWeekdays.add(startDate.weekday);
                }
              });
            }

            Widget chip(String label, int wd) => FilterChip(
              selected: selectedWeekdays.contains(wd),
              label: Text(label),
              onSelected: (_) => toggleWeekday(wd),
            );

            final query = clientQuery.trim().toLowerCase();
            final filteredClients = clients
                .where((c) => c.name.toLowerCase().contains(query))
                .toList();

            if (filteredClients.isNotEmpty &&
                !filteredClients.any((c) => c.id == selectedClientId)) {
              selectedClientId = filteredClients.first.id;
            }

            Widget pickerField({
              required String title,
              required String value,
              required VoidCallback onTap,
            }) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget formCard({
              required String title,
              required Widget child,
              EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            }) {
              return Container(
                padding: padding,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    child,
                  ],
                ),
              );
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Center(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person_add_alt_1,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Записать клиента',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            formCard(
                              title: 'Поиск',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Поиск по имени',
                                  prefixIcon: Icon(Icons.search),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (v) =>
                                    setLocalState(() => clientQuery = v),
                              ),
                            ),
                            const SizedBox(height: 12),
                            formCard(
                              title: 'Клиент',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: filteredClients.isEmpty
                                      ? null
                                      : selectedClientId,
                                  hint: const Text('Выберите клиента'),
                                  items: filteredClients
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(
                                            c.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: filteredClients.isEmpty
                                      ? null
                                      : (v) => setLocalState(
                                          () => selectedClientId =
                                              v ?? selectedClientId,
                                        ),
                                ),
                              ),
                            ),
                            if (filteredClients.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  'Клиенты не найдены',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: pickerField(
                                    title: 'Дата',
                                    value: DateFormat(
                                      'dd.MM.yyyy',
                                      'ru_RU',
                                    ).format(startDate),
                                    onTap: pickStartDate,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: pickerField(
                                    title: 'Время',
                                    value:
                                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    onTap: pickTime,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: SwitchListTile.adaptive(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                title: const Text('Использовать расписание'),
                                subtitle: const Text(
                                  'Если выключено — создастся одна запись',
                                ),
                                value: useSchedule,
                                onChanged: (v) =>
                                    setLocalState(() => useSchedule = v),
                              ),
                            ),
                            if (useSchedule) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Дни недели',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  chip('Пн', 1),
                                  chip('Вт', 2),
                                  chip('Ср', 3),
                                  chip('Чт', 4),
                                  chip('Пт', 5),
                                  chip('Сб', 6),
                                  chip('Вс', 7),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                initialValue: weeks,
                                items: const [
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text('1 неделя'),
                                  ),
                                  DropdownMenuItem(
                                    value: 2,
                                    child: Text('2 недели'),
                                  ),
                                  DropdownMenuItem(
                                    value: 4,
                                    child: Text('4 недели'),
                                  ),
                                  DropdownMenuItem(
                                    value: 8,
                                    child: Text('8 недель'),
                                  ),
                                  DropdownMenuItem(
                                    value: 12,
                                    child: Text('12 недель'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setLocalState(() => weeks = v ?? 4),
                                decoration: const InputDecoration(
                                  labelText: 'Период',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                const SizedBox(width: 10),
                                FilledButton(
                                  onPressed: filteredClients.isEmpty
                                      ? null
                                      : () => Navigator.pop(context, true),
                                  child: const Text('Создать'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (ok != true) return;

    if (useSchedule) {
      await _createSchedule(
        clientId: selectedClientId,
        startDay: startDate,
        weekdays: selectedWeekdays,
        time: time,
        weeks: weeks,
      );
    } else {
      final startAt = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        time.hour,
        time.minute,
      );
      await db.addAppointmentIfNotExists(
        clientId: selectedClientId,
        startAt: startAt,
      );
    }

    _lastTime = time;
  }

  // Future<void> _pickTimeKeyboard({
  //   required void Function(TimeOfDay newTime) onPicked,
  //   required StateSetter setLocalState,
  //   required TimeOfDay current,
  // }) async {
  //   final controller = TextEditingController(text: ''); // пусто, как ты хотел
  //   final formatter = MaskTextInputFormatter(
  //     mask: '##:##',
  //     filter: {'#': RegExp(r'[0-9]')},
  //   );

  //   final ok = await showDialog<bool>(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text('Время'),
  //         content: TextField(
  //           controller: controller,
  //           keyboardType: TextInputType.number,
  //           autofocus: true,
  //           inputFormatters: [formatter],
  //           decoration: const InputDecoration(
  //             hintText: 'ЧЧ:ММ',
  //             border: OutlineInputBorder(),
  //           ),
  //           onChanged: (v) {
  //             // авто-прыжок на минуты после 2 цифр часов
  //             // маска сама ставит ":" после 2 цифр
  //           },
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text('Отмена'),
  //           ),
  //           FilledButton(
  //             onPressed: () {
  //               final raw = formatter
  //                   .getUnmaskedText(); // только цифры, без ":"
  //               // raw может быть '10' или '103' или '1030' и т.д.
  //               String hh = '00';
  //               String mm = '00';

  //               if (raw.length >= 2) {
  //                 hh = raw.substring(0, 2);
  //               } else if (raw.length == 1) {
  //                 hh = '0${raw.substring(0, 1)}';
  //               }

  //               if (raw.length >= 4) {
  //                 mm = raw.substring(2, 4);
  //               } else if (raw.length == 3) {
  //                 mm = '${raw.substring(2, 3)}0';
  //               } else {
  //                 mm = '00'; // если минут нет — 00
  //               }

  //               final h = int.tryParse(hh) ?? 0;
  //               final m = int.tryParse(mm) ?? 0;

  //               if (h < 0 || h > 23 || m < 0 || m > 59) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(content: Text('Неверное время')),
  //                 );
  //                 return;
  //               }

  //               onPicked(TimeOfDay(hour: h, minute: m));
  //               Navigator.pop(context, true);
  //             },
  //             child: const Text('Ок'),
  //           ),
  //         ],
  //       );
  //     },
  //   );

  //   if (ok == true) {
  //     // обновление UI делаем там, где вызвали
  //   }
  // }

  Future<void> _addNewClientAndAppointment({TimeOfDay? prefillTime}) async {
    final nameController = TextEditingController();

    String gender = 'Не указано';
    String plan = 'Пробный';

    DateTime? planStart;
    DateTime? planEnd;

    void syncPlanDates(String selectedPlan) {
      if (selectedPlan == 'Пробный') {
        planStart = null;
        planEnd = null;
        return;
      }
      planStart ??= _selectedDay;
      planEnd = planStart!.add(const Duration(days: 28));
    }

    syncPlanDates(plan);

    DateTime startDate = _selectedDay;
    final selectedWeekdays = <int>{_selectedDay.weekday};

    TimeOfDay time =
        prefillTime ?? _lastTime ?? const TimeOfDay(hour: 10, minute: 0);
    int weeks = 4;
    bool useSchedule = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> pickPlanStart() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: planStart ?? _selectedDay,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                locale: const Locale('ru', 'RU'),
              );
              if (picked == null) return;
              setLocalState(() {
                planStart = DateTime(picked.year, picked.month, picked.day);
                planEnd = planStart!.add(const Duration(days: 28));
              });
            }

            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                locale: const Locale('ru', 'RU'),
              );
              if (picked == null) return;
              setLocalState(() {
                startDate = DateTime(picked.year, picked.month, picked.day);
                selectedWeekdays
                  ..clear()
                  ..add(startDate.weekday);
              });
            }

            Future<void> pickTime() async {
              final picked = await _pickTime(time);
              if (picked == null) return;
              setLocalState(() => time = picked);
            }

            void toggleWeekday(int wd) {
              setLocalState(() {
                if (selectedWeekdays.contains(wd)) {
                  selectedWeekdays.remove(wd);
                } else {
                  selectedWeekdays.add(wd);
                }
                if (selectedWeekdays.isEmpty) {
                  selectedWeekdays.add(startDate.weekday);
                }
              });
            }

            Widget chip(String label, int wd) => FilterChip(
              selected: selectedWeekdays.contains(wd),
              label: Text(label),
              onSelected: (_) => toggleWeekday(wd),
            );

            Widget pickerField({
              required String title,
              required String value,
              required VoidCallback onTap,
            }) {
              return InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            Widget formCard({
              required String title,
              required Widget child,
              EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            }) {
              return Container(
                padding: padding,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    child,
                  ],
                ),
              );
            }

            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Center(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person_add,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Новый клиент',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            formCard(
                              title: 'Имя',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Введите имя клиента',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                autofocus: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            formCard(
                              title: 'Пол',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: gender,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Не указано',
                                      child: Text('Не указано'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'М',
                                      child: Text('М'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Ж',
                                      child: Text('Ж'),
                                    ),
                                  ],
                                  onChanged: (v) =>
                                      setLocalState(() => gender = v ?? gender),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            formCard(
                              title: 'Абонемент',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: plan,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Пробный',
                                      child: Text('Пробный'),
                                    ),
                                    DropdownMenuItem(
                                      value: '4',
                                      child: Text('4'),
                                    ),
                                    DropdownMenuItem(
                                      value: '8',
                                      child: Text('8'),
                                    ),
                                    DropdownMenuItem(
                                      value: '12',
                                      child: Text('12'),
                                    ),
                                  ],
                                  onChanged: (v) => setLocalState(() {
                                    plan = v ?? plan;
                                    syncPlanDates(plan);
                                  }),
                                ),
                              ),
                            ),
                            if (plan != 'Пробный') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: pickerField(
                                      title: 'Начало абонемента',
                                      value: DateFormat(
                                        'dd.MM.yyyy',
                                        'ru_RU',
                                      ).format(planStart!),
                                      onTap: pickPlanStart,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: formCard(
                                      title: 'Конец абонемента (+28 дней)',
                                      child: Text(
                                        DateFormat(
                                          'dd.MM.yyyy',
                                          'ru_RU',
                                        ).format(planEnd!),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: pickerField(
                                    title: 'Дата',
                                    value: DateFormat(
                                      'dd.MM.yyyy',
                                      'ru_RU',
                                    ).format(startDate),
                                    onTap: pickStartDate,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: pickerField(
                                    title: 'Время',
                                    value:
                                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                    onTap: pickTime,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: SwitchListTile.adaptive(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                title: const Text('Использовать расписание'),
                                subtitle: const Text(
                                  'Если выключено — создастся одна запись',
                                ),
                                value: useSchedule,
                                onChanged: (v) =>
                                    setLocalState(() => useSchedule = v),
                              ),
                            ),
                            if (useSchedule) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Дни недели',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  chip('Пн', 1),
                                  chip('Вт', 2),
                                  chip('Ср', 3),
                                  chip('Чт', 4),
                                  chip('Пт', 5),
                                  chip('Сб', 6),
                                  chip('Вс', 7),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<int>(
                                initialValue: weeks,
                                items: const [
                                  DropdownMenuItem(
                                    value: 1,
                                    child: Text('1 неделя'),
                                  ),
                                  DropdownMenuItem(
                                    value: 2,
                                    child: Text('2 недели'),
                                  ),
                                  DropdownMenuItem(
                                    value: 4,
                                    child: Text('4 недели'),
                                  ),
                                  DropdownMenuItem(
                                    value: 8,
                                    child: Text('8 недель'),
                                  ),
                                  DropdownMenuItem(
                                    value: 12,
                                    child: Text('12 недель'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setLocalState(() => weeks = v ?? 4),
                                decoration: const InputDecoration(
                                  labelText: 'Период',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Отмена'),
                                ),
                                const SizedBox(width: 10),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Создать'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (ok != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final clientId = DateTime.now().microsecondsSinceEpoch.toString();

    await db.upsertClient(
      ClientsCompanion.insert(
        id: clientId,
        name: name,
        gender: Value(gender),
        plan: Value(plan),
        planStart: planStart == null ? const Value.absent() : Value(planStart),
        planEnd: planEnd == null ? const Value.absent() : Value(planEnd),
      ),
    );

    if (useSchedule) {
      await _createSchedule(
        clientId: clientId,
        startDay: startDate,
        weekdays: selectedWeekdays,
        time: time,
        weeks: weeks,
      );
    } else {
      final startAt = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        time.hour,
        time.minute,
      );
      await db.addAppointmentIfNotExists(clientId: clientId, startAt: startAt);
    }

    _lastTime = time;
  }

  Future<void> _openScheduleEditorForClient({
    required Client client,
    required bool hasSchedule,
  }) async {
    DateTime startDate = _selectedDay;
    TimeOfDay time = _lastTime ?? const TimeOfDay(hour: 10, minute: 0);
    final selectedWeekdays = <int>{_selectedDay.weekday};
    int weeks = 4;
    bool scheduleEnabled = hasSchedule;

    if (hasSchedule) {
      final upcoming = await db.getFutureAppointmentsForClient(
        clientId: client.id,
        from: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day),
      );
      if (upcoming.isNotEmpty) {
        final first = upcoming.first.startAt;
        time = TimeOfDay.fromDateTime(first);
        selectedWeekdays
          ..clear()
          ..addAll(upcoming.map((e) => e.startAt.weekday).toSet());
        startDate = DateTime(first.year, first.month, first.day);
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) {
          Widget chip(String label, int wd) => FilterChip(
            selected: selectedWeekdays.contains(wd),
            label: Text(label),
            onSelected: (v) {
              setLocal(() {
                if (v) {
                  selectedWeekdays.add(wd);
                } else {
                  selectedWeekdays.remove(wd);
                }
                if (selectedWeekdays.isEmpty) {
                  selectedWeekdays.add(startDate.weekday);
                }
              });
            },
          );

          return AlertDialog(
            title: Text(
              scheduleEnabled ? 'Изменить расписание' : 'Создать расписание',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: scheduleEnabled,
                    title: const Text('Расписание активно'),
                    subtitle: Text(
                      scheduleEnabled
                          ? 'Можно менять дни и время'
                          : 'Будет отключено',
                    ),
                    onChanged: (v) => setLocal(() => scheduleEnabled = v),
                  ),
                  if (scheduleEnabled) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        chip('Пн', DateTime.monday),
                        chip('Вт', DateTime.tuesday),
                        chip('Ср', DateTime.wednesday),
                        chip('Чт', DateTime.thursday),
                        chip('Пт', DateTime.friday),
                        chip('Сб', DateTime.saturday),
                        chip('Вс', DateTime.sunday),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Время'),
                      subtitle: Text(time.format(context)),
                      trailing: const Icon(Icons.schedule),
                      onTap: () async {
                        final picked = await _pickTime(time);
                        if (picked != null) setLocal(() => time = picked);
                      },
                    ),
                    DropdownButtonFormField<int>(
                      value: weeks,
                      decoration: const InputDecoration(
                        labelText: 'Период (недель)',
                      ),
                      items: const [4, 8, 12, 16]
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          )
                          .toList(),
                      onChanged: (v) => setLocal(() => weeks = v ?? 4),
                    ),
                  ],
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
      ),
    );

    if (ok != true) return;

    final from = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day + 1,
    );
    await db.deleteFutureAppointmentsForClient(clientId: client.id, from: from);

    if (scheduleEnabled) {
      await _createSchedule(
        clientId: client.id,
        startDay: startDate,
        weekdays: selectedWeekdays,
        time: time,
        weeks: weeks,
      );
      _lastTime = time;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          scheduleEnabled ? 'Расписание обновлено' : 'Расписание отключено',
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openAppointmentActions(AppointmentWithClient item) async {
    final colors = Theme.of(context).colorScheme;
    final upcoming = await db.getFutureAppointmentsForClient(
      clientId: item.client.id,
      from: DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day + 1,
      ),
    );
    final hasSchedule = upcoming.length >= 2;

    Widget actionTile({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
      Color? iconColor,
    }) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: (iconColor ?? colors.primary).withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor ?? colors.primary),
        ),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        onTap: onTap,
      );
    }

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Wrap(
            children: [
              actionTile(
                icon: Icons.person,
                title: 'Открыть клиента',
                subtitle: item.client.name,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/clients/${item.client.id}');
                },
              ),
              actionTile(
                icon: Icons.edit,
                title: 'Редактировать время',
                subtitle: _fmtTime(item.appointment.startAt),
                onTap: () async {
                  Navigator.pop(context);
                  final initial = TimeOfDay.fromDateTime(
                    item.appointment.startAt,
                  );
                  final picked = await _pickTime(initial);
                  if (picked == null) return;

                  final newStart = _combine(_selectedDay, picked);
                  await db.updateAppointmentTime(
                    id: item.appointment.id,
                    newStartAt: newStart,
                  );

                  _lastTime = picked;
                },
              ),
              actionTile(
                icon: Icons.repeat,
                title: hasSchedule
                    ? 'Изменить расписание'
                    : 'Создать расписание',
                subtitle: hasSchedule
                    ? 'Изменить дни/время или отключить'
                    : 'Создать регулярные тренировки',
                onTap: () async {
                  Navigator.pop(context);
                  await _openScheduleEditorForClient(
                    client: item.client,
                    hasSchedule: hasSchedule,
                  );
                },
              ),
              actionTile(
                icon: Icons.calendar_month,
                title: 'Перенести на дату',
                subtitle:
                    'Сейчас: ${DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(item.appointment.startAt)}',
                onTap: () async {
                  Navigator.pop(context);

                  final current = item.appointment.startAt;

                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(
                      current.year,
                      current.month,
                      current.day,
                    ),
                    firstDate: DateTime(2020, 1, 1),
                    lastDate: DateTime(2035, 12, 31),
                    locale: const Locale('ru', 'RU'),
                  );
                  if (pickedDate == null) return;

                  final pickedTime = await _pickTime(
                    TimeOfDay.fromDateTime(current),
                  );
                  if (pickedTime == null) return;

                  // отмечаем на дату записи/выбранную дату (не "сейчас")
                  final newStart = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    pickedTime.hour,
                    pickedTime.minute,
                  );

                  await db.updateAppointmentTime(
                    id: item.appointment.id,
                    newStartAt: newStart,
                  );
                  _lastTime = pickedTime;
                },
              ),
              actionTile(
                icon: Icons.delete_outline,
                title: 'Удалить запись',
                iconColor: colors.error,
                onTap: () async {
                  Navigator.pop(context);
                  await db.deleteAppointmentById(item.appointment.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<int> _createSchedule({
    required String clientId,
    required DateTime startDay,
    required Set<int> weekdays, // 1=Пн ... 7=Вс
    required TimeOfDay time,
    required int weeks,
  }) async {
    final start = DateTime(startDay.year, startDay.month, startDay.day);
    final totalDays = weeks * 7;

    int created = 0;
    for (int i = 0; i < totalDays; i++) {
      final day = start.add(Duration(days: i));
      if (!weekdays.contains(day.weekday)) continue;

      final startAt = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      await db.addAppointmentIfNotExists(clientId: clientId, startAt: startAt);
      created++;
    }
    return created;
  }

  Future<void> _extendClientPlan(Client client, {int days = 28}) async {
    if (client.plan == null || client.plan == 'Пробный') return;

    final base = client.planEnd ?? _selectedDay;
    final baseDate = DateTime(base.year, base.month, base.day);
    final nextEnd = baseDate.add(Duration(days: days));

    await db.upsertClient(
      ClientsCompanion(
        id: Value(client.id),
        name: Value(client.name),
        gender: Value(client.gender),
        plan: Value(client.plan),
        planStart: client.planStart == null
            ? Value(
                DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                ),
              )
            : Value(client.planStart!),
        planEnd: Value(nextEnd),
      ),
    );

    await db.syncProgramStateFromClient(client.id);

    if (!mounted) return;
    final fmt = DateFormat('dd.MM.yyyy', 'ru_RU').format(nextEnd);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Абонемент ${client.name} продлён до $fmt')),
    );
  }

  double? _parseWeight(String raw) {
    final s = raw.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  int? _parseReps(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  Future<void> _openQuickWorkoutCheck(AppointmentWithClient item) async {
    final nextSlot = await db.getNextPlannedProgramSlotForClient(
      item.client.id,
    );

    if (nextSlot == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У клиента нет активной программы.')),
      );
      return;
    }
    final nextAbsoluteIndex = nextSlot.$1;
    final nextTemplateIdx = nextSlot.$2;

    final details = await db.getWorkoutDetailsForClientProgramSlot(
      clientId: item.client.id,
      absoluteIndex: nextAbsoluteIndex,
      templateIdx: nextTemplateIdx,
    );

    final drafts = await db.getWorkoutDraftResults(
      clientId: item.client.id,
      day: _selectedDay,
      templateIdx: nextTemplateIdx,
      absoluteIndex: nextAbsoluteIndex,
    );

    final exercises = details.$3.map((e) {
      final d = drafts[e.templateExerciseId];
      if (d == null) return e;
      return WorkoutExerciseVm(
        templateExerciseId: e.templateExerciseId,
        templateId: e.templateId,
        orderIndex: e.orderIndex,
        name: e.name,
        lastWeightKg: d.$1,
        lastReps: d.$2,
        supersetGroup: e.supersetGroup,
      );
    }).toList();

    final kgControllers = <int, TextEditingController>{};
    final repsControllers = <int, TextEditingController>{};

    for (final e in exercises) {
      kgControllers[e.templateExerciseId] = TextEditingController(
        text: e.lastWeightKg == null ? '' : e.lastWeightKg!.toString(),
      );
      repsControllers[e.templateExerciseId] = TextEditingController(
        text: e.lastReps?.toString() ?? '',
      );
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Проверка весов • ${item.client.name}'),
        content: SizedBox(
          width: 420,
          child: exercises.isEmpty
              ? const Text('В этой тренировке пока нет упражнений.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final e = exercises[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: kgControllers[e.templateExerciseId],
                                decoration: const InputDecoration(
                                  labelText: 'Вес (кг)',
                                  isDense: true,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller:
                                    repsControllers[e.templateExerciseId],
                                decoration: const InputDecoration(
                                  labelText: 'Повторы',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ок'),
          ),
        ],
      ),
    );

    if (ok != true) {
      for (final c in [...kgControllers.values, ...repsControllers.values]) {
        c.dispose();
      }
      return;
    }

    final results = <int, (double? kg, int? reps)>{};
    for (final e in exercises) {
      final kg = _parseWeight(kgControllers[e.templateExerciseId]?.text ?? '');
      final reps = _parseReps(
        repsControllers[e.templateExerciseId]?.text ?? '',
      );
      results[e.templateExerciseId] = (kg, reps);
    }

    for (final c in [...kgControllers.values, ...repsControllers.values]) {
      c.dispose();
    }

    final now = DateTime.now();
    final completeAt = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      12,
      0,
      0,
      now.millisecond,
      now.microsecond,
    );

    await db.completeWorkoutForClientWithTemplateIdx(
      clientId: item.client.id,
      when: completeAt,
      templateIdx: nextTemplateIdx,
    );

    await db.saveWorkoutResultsAndMarkDone(
      clientId: item.client.id,
      day: _selectedDay,
      resultsByTemplateExerciseId: results,
      templateIdx: nextTemplateIdx,
      absoluteIndex: nextAbsoluteIndex,
    );

    await db.updateAppointmentNote(
      id: item.appointment.id,
      note: _withAttendanceMarker(item.appointment.note, true),
    );

    if (!mounted) return;
    setState(() {});
  }

  void _maybeOpenCategoriesFromRoute() {
    final uri = GoRouterState.of(context).uri;
    final shouldOpen = uri.queryParameters['openCategories'] == '1';

    if (!shouldOpen) {
      _openingCategoriesFromRoute = false;
      return;
    }

    if (_openingCategoriesFromRoute) return;
    _openingCategoriesFromRoute = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _openCategoriesSheet();
      if (!mounted) return;
      _openingCategoriesFromRoute = false;
      context.go('/calendar');
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _fmtDate(_selectedDay);
    final colors = Theme.of(context).colorScheme;
    _maybeOpenCategoriesFromRoute();

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Календарь'),
          actions: [
            IconButton(
              onPressed: () => themeController.toggle(),
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAddMenu(),
          child: const Icon(Icons.add),
        ),
        body: StreamBuilder<List<AppointmentWithClient>>(
          stream: db.watchAppointmentsForDay(_selectedDay),
          builder: (context, snap) {
            final items = snap.data ?? const <AppointmentWithClient>[];

            return StreamBuilder<List<Client>>(
              stream: db.watchClientsWithPlanEndForDay(_selectedDay),
              builder: (context, planSnap) {
                final expiringClients = planSnap.data ?? const <Client>[];
                final hasAnyItems =
                    items.isNotEmpty || expiringClients.isNotEmpty;

                return NotificationListener<ScrollNotification>(
                  onNotification: _onListScroll,
                  child: CustomScrollView(
                    controller: _appointmentsController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Календарь сверху
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: colors.outlineVariant.withOpacity(
                                      0.7,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    8,
                                    8,
                                    6,
                                  ),
                                  child: TableCalendar(
                                    // вертикальный жест календаря отключен: формат
                                    // переключаем только прокруткой списка,
                                    // чтобы горизонтальный свайп месяца не схлопывал вид
                                    availableGestures:
                                        AvailableGestures.horizontalSwipe,

                                    pageAnimationCurve: Curves.easeOutCubic,
                                    pageAnimationDuration: const Duration(
                                      milliseconds: 280,
                                    ),

                                    locale: 'ru_RU',
                                    availableCalendarFormats: const {
                                      CalendarFormat.month: 'Месяц',
                                      CalendarFormat.week: 'Неделя',
                                    },
                                    calendarFormat: _calendarFormat,

                                    headerStyle: HeaderStyle(
                                      formatButtonVisible: false,
                                      titleCentered: true,
                                      titleTextStyle:
                                          Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ) ??
                                          const TextStyle(fontSize: 22),
                                      leftChevronIcon: Icon(
                                        Icons.chevron_left,
                                        color: colors.onSurface,
                                      ),
                                      rightChevronIcon: Icon(
                                        Icons.chevron_right,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                    daysOfWeekStyle: DaysOfWeekStyle(
                                      weekdayStyle:
                                          Theme.of(
                                            context,
                                          ).textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ) ??
                                          const TextStyle(),
                                      weekendStyle:
                                          Theme.of(
                                            context,
                                          ).textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: colors.onSurfaceVariant,
                                          ) ??
                                          const TextStyle(),
                                    ),
                                    calendarStyle: CalendarStyle(
                                      outsideTextStyle: TextStyle(
                                        color: colors.onSurface.withOpacity(
                                          0.35,
                                        ),
                                      ),
                                      weekendTextStyle: TextStyle(
                                        color: colors.onSurface.withOpacity(
                                          0.85,
                                        ),
                                      ),
                                      defaultDecoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      todayDecoration: BoxDecoration(
                                        color: colors.primary.withOpacity(0.18),
                                        shape: BoxShape.circle,
                                      ),
                                      selectedDecoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.primary.withOpacity(
                                              0.28,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      markersAlignment: Alignment.bottomCenter,
                                      markersMaxCount: 3,
                                      markerDecoration: BoxDecoration(
                                        color: colors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      markerSize: 6,
                                      markerMargin: const EdgeInsets.symmetric(
                                        horizontal: 1.5,
                                      ),
                                    ),

                                    firstDay: DateTime.utc(2020, 1, 1),
                                    lastDay: DateTime.utc(2035, 12, 31),
                                    focusedDay: _focusedDay,

                                    startingDayOfWeek: StartingDayOfWeek.monday,
                                    selectedDayPredicate: (day) =>
                                        isSameDay(_selectedDay, day),

                                    onDaySelected: (selectedDay, focusedDay) {
                                      setState(() {
                                        _selectedDay = DateTime(
                                          selectedDay.year,
                                          selectedDay.month,
                                          selectedDay.day,
                                        );
                                        _focusedDay = focusedDay;
                                      });
                                    },

                                    onPageChanged: (focusedDay) {
                                      setState(() => _focusedDay = focusedDay);
                                      _setCountsWindow(focusedDay);
                                    },

                                    eventLoader: (day) {
                                      final key = DateTime(
                                        day.year,
                                        day.month,
                                        day.day,
                                      );
                                      final visibleWork =
                                          _isCategoryVisible(_workCategoryId)
                                          ? (_workApptCountByDay[key] ?? 0)
                                          : 0;
                                      final visibleTrial =
                                          _isCategoryVisible(_trialCategoryId)
                                          ? (_trialApptCountByDay[key] ?? 0)
                                          : 0;
                                      final planEnd =
                                          _planEndCountByDay[key] ?? 0;
                                      final total =
                                          visibleWork + visibleTrial + planEnd;
                                      return List.filled(total, 1);
                                    },

                                    calendarBuilders: CalendarBuilders(
                                      markerBuilder: (context, day, events) {
                                        final key = DateTime(
                                          day.year,
                                          day.month,
                                          day.day,
                                        );
                                        final markers = <Color>[];

                                        if (_isCategoryVisible(
                                              _workCategoryId,
                                            ) &&
                                            (_workApptCountByDay[key] ?? 0) >
                                                0) {
                                          markers.add(
                                            _categoryColor(
                                              _workCategoryId,
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          );
                                        }

                                        if (_isCategoryVisible(
                                              _trialCategoryId,
                                            ) &&
                                            (_trialApptCountByDay[key] ?? 0) >
                                                0) {
                                          markers.add(
                                            _categoryColor(
                                              _trialCategoryId,
                                              const Color(0xFFFF9F43),
                                            ),
                                          );
                                        }

                                        if ((_planEndCountByDay[key] ?? 0) >
                                            0) {
                                          markers.add(Colors.redAccent);
                                        }

                                        if (markers.isEmpty) return null;

                                        return IgnorePointer(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Wrap(
                                                spacing: 3,
                                                children: [
                                                  for (final color
                                                      in markers.take(3))
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: BoxDecoration(
                                                        color: color,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 4)),

                      // Заголовок (скроллится вместе со списком)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Записи на $selectedLabel',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      ),

                      if (expiringClients.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final client = expiringClients[i];
                            final planEnd = client.planEnd == null
                                ? ''
                                : DateFormat(
                                    'dd.MM.yyyy',
                                    'ru_RU',
                                  ).format(client.planEnd!);
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                              child: Card(
                                elevation: 0,
                                color: colors.errorContainer.withOpacity(0.45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: colors.error.withOpacity(0.4),
                                  ),
                                ),
                                child: ListTile(
                                  leading: Icon(
                                    Icons.warning_amber_rounded,
                                    color: colors.error,
                                  ),
                                  title: Text(
                                    'Заканчивается абонемент • ${client.name}',
                                  ),
                                  subtitle: Text(
                                    planEnd.isEmpty
                                        ? 'Проверьте дату окончания'
                                        : 'Дата окончания: $planEnd',
                                  ),
                                  trailing: FilledButton.tonalIcon(
                                    onPressed: () => _extendClientPlan(client),
                                    icon: const Icon(Icons.event_repeat),
                                    label: const Text('+28 дней'),
                                  ),
                                ),
                              ),
                            );
                          }, childCount: expiringClients.length),
                        ),

                      if (items.isEmpty && !hasAnyItems)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'На этот день записей и окончаний абонемента нет',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        )
                      else if (items.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final it = items[i];
                            final done = _isAppointmentDone(it.appointment);
                            final hasPlan = (it.client.plan ?? '')
                                .trim()
                                .isNotEmpty;
                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                12,
                                0,
                                12,
                                i == items.length - 1 ? 98 : 10,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () async {
                                  final dayStr = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDay);
                                  await context.push(
                                    '/clients/${it.client.id}/program?day=$dayStr',
                                  );
                                  if (!mounted) return;
                                  setState(() {});
                                },
                                onLongPress: () => _openAppointmentActions(it),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    12,
                                    8,
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: LinearGradient(
                                      colors: [
                                        colors.surface,
                                        colors.surfaceContainerLow,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: done
                                          ? colors.primary.withOpacity(0.28)
                                          : colors.outlineVariant.withOpacity(
                                              0.6,
                                            ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.shadow.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colors
                                                        .primaryContainer
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _fmtTime(
                                                      it.appointment.startAt,
                                                    ),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    it.client.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.1,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                if (hasPlan)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: colors
                                                          .secondaryContainer
                                                          .withOpacity(0.65),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .confirmation_number_outlined,
                                                          size: 15,
                                                          color: colors
                                                              .onSecondaryContainer,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'Абонемент ${it.client.plan}',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .labelMedium,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: done
                                                        ? Colors.green
                                                              .withOpacity(0.14)
                                                        : colors.errorContainer
                                                              .withOpacity(
                                                                0.45,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        done
                                                            ? Icons
                                                                  .check_rounded
                                                            : Icons
                                                                  .hourglass_bottom_rounded,
                                                        size: 15,
                                                        color: done
                                                            ? Colors
                                                                  .green
                                                                  .shade800
                                                            : colors
                                                                  .onErrorContainer,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        done
                                                            ? 'Выполнено'
                                                            : 'Не выполнено',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: done
                                                                  ? Colors
                                                                        .green
                                                                        .shade800
                                                                  : colors
                                                                        .onErrorContainer,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton.filledTonal(
                                            visualDensity:
                                                VisualDensity.compact,
                                            tooltip: done
                                                ? 'Снять отметку выполнения'
                                                : 'Проверить и отметить выполненной',
                                            icon: Icon(
                                              done
                                                  ? Icons.check_circle
                                                  : Icons
                                                        .radio_button_unchecked,
                                            ),
                                            onPressed: () async {
                                              if (done) {
                                                await db
                                                    .toggleWorkoutForClientOnDay(
                                                      clientId: it.client.id,
                                                      day: _selectedDay,
                                                    );
                                                await db.updateAppointmentNote(
                                                  id: it.appointment.id,
                                                  note: _withAttendanceMarker(
                                                    it.appointment.note,
                                                    false,
                                                  ),
                                                );
                                                if (!mounted) return;
                                                setState(() {});
                                                return;
                                              }

                                              await _openQuickWorkoutCheck(it);
                                            },
                                          ),
                                          PopupMenuButton<String>(
                                            tooltip: 'Действия',
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      size: 18,
                                                      color: colors.error,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Удалить запись',
                                                      style: TextStyle(
                                                        color: colors.error,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (value) async {
                                              if (value == 'delete') {
                                                await db.deleteAppointmentById(
                                                  it.appointment.id,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.more_horiz_rounded,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }, childCount: items.length),
                        ),
                    ],
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
