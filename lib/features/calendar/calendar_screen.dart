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

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  late final AppDb db;
  bool _dbInited = false;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final Map<DateTime, int> _apptCountByDay = {}; // ключ = DateTime(y,m,d)

  // --- добавить вот это ---
  StreamSubscription<Map<DateTime, int>>? _countsSub;
  StreamSubscription<List<WorkoutSession>>? _workoutSessionsSub;
  DateTime? _countsFrom;
  DateTime? _countsTo;

  TimeOfDay? _lastTime;

  // один контроллер списка (используем его)
  final ScrollController _appointmentsController = ScrollController();
  bool _userDragging = false;
  double _dragSum = 0;
  bool _toggledThisDrag = false;

  static const double _gestureThreshold = 14; // пиксели "намеренного" свайпа

  // формат календаря
  // формат, который реально отрисовывает TableCalendar
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // защита от дерганья
  bool _collapseLock = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_dbInited) {
      db = AppDbScope.of(context);
      _dbInited = true;

      // стартуем подписку 1 раз
      _setCountsWindow(_focusedDay);

      _workoutSessionsSub = db.select(db.workoutSessions).watch().listen((_) {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _countsSub?.cancel();
    _workoutSessionsSub?.cancel();
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

    _countsSub?.cancel();
    _countsSub = db.watchAppointmentCountsByDay(from: from, to: to).listen((m) {
      if (!mounted) return;
      setState(() {
        _apptCountByDay
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
    setState(() => _calendarFormat = CalendarFormat.week);
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
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Поиск по имени',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                              onChanged: (v) =>
                                  setLocalState(() => clientQuery = v),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: filteredClients.isEmpty
                                  ? null
                                  : selectedClientId,
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
                              decoration: const InputDecoration(
                                labelText: 'Клиент',
                                border: OutlineInputBorder(),
                                filled: true,
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
                                value: weeks,
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

    DateTime planStart = _selectedDay;
    DateTime planEnd = planStart.add(const Duration(days: 28));

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
                initialDate: planStart,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
                locale: const Locale('ru', 'RU'),
              );
              if (picked == null) return;
              setLocalState(() {
                planStart = DateTime(picked.year, picked.month, picked.day);
                planEnd = planStart.add(const Duration(days: 28));
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
                if (selectedWeekdays.isEmpty)
                  selectedWeekdays.add(startDate.weekday);
              });
            }

            Widget chip(String label, int wd) => FilterChip(
              selected: selectedWeekdays.contains(wd),
              label: Text(label),
              onSelected: (_) => toggleWeekday(wd),
            );

            return AlertDialog(
              title: const Text('Новый клиент'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя',
                        border: OutlineInputBorder(),
                      ),
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
                      onChanged: (v) =>
                          setLocalState(() => gender = v ?? 'Не указано'),
                      decoration: const InputDecoration(
                        labelText: 'Пол',
                        border: OutlineInputBorder(),
                      ),
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
                      onChanged: (v) =>
                          setLocalState(() => plan = v ?? 'Пробный'),
                      decoration: const InputDecoration(
                        labelText: 'Абонемент',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: pickPlanStart,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Начало абонемента',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('dd.MM.yyyy', 'ru_RU').format(planStart),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Конец абонемента (+28 дней)',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd.MM.yyyy', 'ru_RU').format(planEnd),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    InkWell(
                      onTap: pickStartDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Старт расписания (дата)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('dd.MM.yyyy', 'ru_RU').format(startDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Время',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Использовать расписание'),
                      subtitle: const Text(
                        'Если выключено — создастся одна запись',
                      ),
                      value: useSchedule,
                      onChanged: (v) => setLocalState(() => useSchedule = v),
                    ),
                    const SizedBox(height: 12),

                    if (useSchedule) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Дни недели'),
                      ),
                      const SizedBox(height: 6),
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
                        value: weeks,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 неделя')),
                          DropdownMenuItem(value: 2, child: Text('2 недели')),
                          DropdownMenuItem(value: 4, child: Text('4 недели')),
                          DropdownMenuItem(value: 8, child: Text('8 недель')),
                          DropdownMenuItem(value: 12, child: Text('12 недель')),
                        ],
                        onChanged: (v) => setLocalState(() => weeks = v ?? 4),
                        decoration: const InputDecoration(
                          labelText: 'Период',
                          border: OutlineInputBorder(),
                        ),
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
                  child: const Text('Создать'),
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

    final clientId = DateTime.now().microsecondsSinceEpoch.toString();

    await db.upsertClient(
      ClientsCompanion.insert(
        id: clientId,
        name: name,
        gender: Value(gender),
        plan: Value(plan),
        planStart: Value(planStart),
        planEnd: Value(planEnd),
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

  Future<void> _openAppointmentActions(AppointmentWithClient item) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Открыть клиента'),
              subtitle: Text(item.client.name),
              onTap: () {
                Navigator.pop(context);
                context.push('/clients/${item.client.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать время'),
              subtitle: Text(_fmtTime(item.appointment.startAt)),
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
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Перенести на дату'),
              subtitle: Text(
                'Сейчас: ${DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(item.appointment.startAt)}',
              ),
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
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Удалить запись'),
              onTap: () async {
                Navigator.pop(context);
                await db.deleteAppointmentById(item.appointment.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Отметить тренировку выполненной'),
              subtitle: Text(
                DateFormat('dd.MM.yyyy', 'ru_RU').format(_selectedDay),
              ),
              onTap: () async {
                Navigator.pop(context);

                // отмечаем на дату записи/выбранную дату (не "сейчас")
                final when = DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                  12,
                  0,
                );

                await db.completeWorkoutForClient(
                  clientId: item.client.id,
                  when: when,
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Тренировка отмечена ✅')),
                );

                setState(() {}); // обновит FutureBuilder в subtitle
              },
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final selectedLabel = _fmtDate(_selectedDay);

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

            return NotificationListener<ScrollNotification>(
              onNotification: _onListScroll,
              child: CustomScrollView(
                controller: _appointmentsController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Календарь сверху
                  SliverToBoxAdapter(
                    child: ClipRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: Material(
                          type: MaterialType.transparency,
                          child: TableCalendar(
                            // важно: явно разрешаем жесты календаря
                            availableGestures: AvailableGestures.all,

                            locale: 'ru_RU',
                            availableCalendarFormats: const {
                              CalendarFormat.month: 'Месяц',
                              CalendarFormat.week: 'Неделя',
                            },
                            calendarFormat: _calendarFormat,

                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
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
                              final c = _apptCountByDay[key] ?? 0;
                              return List.filled(c, 1);
                            },

                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, day, events) {
                                if (events.isEmpty) return null;

                                final dots = events.length > 3
                                    ? 3
                                    : events.length;
                                final primary = Theme.of(
                                  context,
                                ).colorScheme.primary;

                                return IgnorePointer(
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(dots, (_) {
                                          return Container(
                                            width: 6,
                                            height: 6,
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primary,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  blurRadius: 6,
                                                  spreadRadius: 0.5,
                                                  color: primary,
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
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

                  const SliverToBoxAdapter(child: Divider(height: 1)),

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

                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'На этот день записей нет',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final it = items[i];
                        return Column(
                          children: [
                            ListTile(
                              title: Text(
                                '${_fmtTime(it.appointment.startAt)} • ${it.client.name}',
                              ),
                              subtitle: FutureBuilder<WorkoutDayInfo>(
                                future: db.getWorkoutInfoForClientOnDay(
                                  clientId: it.client.id,
                                  day: _selectedDay,
                                ),
                                builder: (context, snap) {
                                  final info = snap.data;
                                  if (info == null || !info.hasPlan) {
                                    return Text(
                                      it.client.plan == null
                                          ? ''
                                          : 'Абонемент: ${it.client.plan}',
                                    );
                                  }

                                  final planText =
                                      'Абонемент: ${it.client.plan}';
                                  final workoutText = info.doneToday
                                      ? '✅ Выполнено: ${info.label} — ${info.title}'
                                      : 'Сегодня: ${info.label} — ${info.title}';

                                  return Text('$planText\n$workoutText');
                                },
                              ),
                              trailing: FutureBuilder<WorkoutDayInfo>(
                                future: db.getWorkoutInfoForClientOnDay(
                                  clientId: it.client.id,
                                  day: _selectedDay,
                                ),
                                builder: (context, snap) {
                                  final done = snap.data?.doneToday == true;

                                  return IconButton(
                                    icon: Icon(
                                      done
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                    ),
                                    onPressed: () async {
                                      await db.toggleWorkoutForClientOnDay(
                                        clientId: it.client.id,
                                        day: _selectedDay,
                                      );
                                      if (!mounted) return;
                                      setState(() {});
                                    },
                                  );
                                },
                              ),
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
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      }, childCount: items.length),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
