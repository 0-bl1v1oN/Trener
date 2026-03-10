// lib/features/clients/client_program_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import '../workouts/workout_screen.dart';

class ClientProgramScreen extends StatefulWidget {
  final String clientId;
  final DateTime? day; // если пришли из календаря — это выбранная дата

  const ClientProgramScreen({super.key, required this.clientId, this.day});

  @override
  State<ClientProgramScreen> createState() => _ClientProgramScreenState();
}

class _ClientProgramScreenState extends State<ClientProgramScreen> {
  late Future<_ProgramData> _future;
  bool _loaded = false;
  bool _didAutoScrollToLastDone = false;
  bool _sharingReport = false;
  final ScrollController _programListController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    final db = AppDbScope.of(context);
    _future = _load(db);
  }

  Future<_ProgramData> _load(AppDb db) async {
    final client = await db.getClientById(widget.clientId);
    final overview = await db.getProgramOverview(widget.clientId);
    final gender = client?.plan == 'Пробный'
        ? 'П'
        : ((client?.gender == 'Ж') ? 'Ж' : 'М');
    return _ProgramData(gender: gender, overview: overview);
  }

  Future<void> _reload() async {
    final db = AppDbScope.of(context);
    setState(() {
      _didAutoScrollToLastDone = false;
      _future = _load(db);
    });
  }

  Future<void> _shiftDays(int delta) async {
    final db = AppDbScope.of(context);
    await db.shiftClientProgramDays(clientId: widget.clientId, delta: delta);
    await _reload();
  }

  Future<void> _shareReport(_ProgramData data, DateTime chosenDay) async {
    if (_sharingReport) return;

    setState(() => _sharingReport = true);

    try {
      final db = AppDbScope.of(context);
      final client = await db.getClientById(widget.clientId);
      final rows = <_ReportRow>[];

      for (final slot in data.overview.slots) {
        final details = await db.getWorkoutDetailsForClientProgramSlot(
          clientId: widget.clientId,
          absoluteIndex: slot.absoluteIndex,
          templateIdx: slot.templateIdx,
        );

        final exercises = details.$3;
        if (exercises.isEmpty) continue;

        final dayLabel =
            'День ${slot.slotIndex} • ${_templateTitleForIdx(slot.templateIdx, data.gender)}';

        for (final ex in exercises) {
          rows.add(
            _ReportRow(
              dayLabel: dayLabel,
              exerciseName: ex.name,
              weightKg: ex.lastWeightKg,
              reps: ex.lastReps,
            ),
          );
        }
      }

      if (rows.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Для отчёта пока нет данных.')),
        );
        return;
      }

      final reportHtml = _buildReportHtml(
        rows: rows,
        clientName: client?.name ?? 'Клиент',
        generatedAt: DateTime.now(),
        chosenDay: chosenDay,
      );

      final tempDir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'progress_report_${widget.clientId}_$stamp.html';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(reportHtml);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/html')],
        subject: 'Отчёт по прогрессу: ${client?.name ?? 'Клиент'}',
        text: 'Отчёт по прогрессу клиента во вложении (HTML-таблица).',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось сформировать отчёт: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sharingReport = false);
      }
    }
  }

  String _buildReportHtml({
    required List<_ReportRow> rows,
    required String clientName,
    required DateTime generatedAt,
    required DateTime chosenDay,
  }) {
    final generated = DateFormat('dd.MM.yyyy HH:mm', 'ru').format(generatedAt);
    final activeDay = DateFormat('dd.MM.yyyy', 'ru').format(chosenDay);
    final uniqueDays = rows.map((r) => r.dayLabel).toSet().length;
    final filledWeights = rows.where((r) => r.weightKg != null).length;
    final filledReps = rows.where((r) => r.reps != null).length;

    final bodyRows = rows
        .map(
          (row) =>
              '''
            <tr>
              <td><span class="pill">${_escapeHtml(row.dayLabel)}</span></td>
              <td class="exercise">${_escapeHtml(row.exerciseName)}</td>
              <td class="num">${row.weightKg == null ? '—' : _fmtWeight(row.weightKg!)}</td>
              <td class="num">${row.reps?.toString() ?? '—'}</td>
            </tr>
          ''',
        )
        .join();

    return '''
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Отчёт по прогрессу</title>
  <style>
    :root {
      --bg: #f5f7fb;
      --text: #172033;
      --muted: #60708f;
      --line: #dbe3f1;
      --head: #eef3ff;
      --card: #ffffff;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-family: Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
      line-height: 1.4;
      padding: 20px;
    }
    .wrap { max-width: 1080px; margin: 0 auto; }
    .header {
      background: linear-gradient(135deg, #eef2ff, #ffffff);
      border: 1px solid var(--line);
      border-radius: 18px;
      padding: 20px;
      margin-bottom: 14px;
      box-shadow: 0 6px 22px rgba(23, 32, 51, 0.06);
    }
    h1 { margin: 0 0 8px; font-size: 26px; line-height: 1.2; }
    .meta { color: var(--muted); font-size: 14px; }
    .stats {
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 10px;
      margin-bottom: 14px;
    }
    .stat {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 14px;
      padding: 12px;
    }
    .stat-label { color: var(--muted); font-size: 12px; margin-bottom: 4px; }
    .stat-value { font-size: 22px; font-weight: 700; }
    .table-wrap {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 18px;
      overflow: hidden;
      box-shadow: 0 6px 22px rgba(23, 32, 51, 0.04);
    }
    table { width: 100%; border-collapse: collapse; font-size: 14px; }
    thead th {
      background: var(--head);
      padding: 12px 10px;
      text-align: left;
      border-bottom: 1px solid var(--line);
    }
    tbody td {
      padding: 11px 10px;
      border-bottom: 1px solid #edf2fa;
      vertical-align: top;
    }
    tbody tr:nth-child(even) { background: #fbfcff; }
    .pill {
      display: inline-block;
      border-radius: 999px;
      padding: 4px 9px;
      background: #eef2ff;
      color: #3e3aa8;
      font-weight: 600;
      font-size: 12px;
    }
    .exercise { font-weight: 600; }
    .num { white-space: nowrap; font-variant-numeric: tabular-nums; }
    .footer {
      margin-top: 12px;
      color: var(--muted);
      font-size: 12px;
      text-align: right;
    }
    @media (max-width: 760px) {
      body { padding: 12px; }
      .header { padding: 16px; }
      .stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
      table { font-size: 13px; }
      thead th, tbody td { padding: 9px 8px; }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <section class="header">
      <h1>Отчёт по прогрессу</h1>
      <div class="meta">
        Клиент: <strong>${_escapeHtml(clientName)}</strong><br>
        Сформирован: $generated<br>
        Активная дата в программе: $activeDay
      </div>
    </section>

    <section class="stats">
      <div class="stat">
        <div class="stat-label">Всего записей</div>
        <div class="stat-value">${rows.length}</div>
      </div>
      <div class="stat">
        <div class="stat-label">Дней в отчёте</div>
        <div class="stat-value">$uniqueDays</div>
      </div>
      <div class="stat">
        <div class="stat-label">Заполнено весов</div>
        <div class="stat-value">$filledWeights</div>
      </div>
      <div class="stat">
        <div class="stat-label">Заполнено повторов</div>
        <div class="stat-value">$filledReps</div>
      </div>
    </section>

    <section class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>День</th>
            <th>Упражнение</th>
            <th>Вес, кг</th>
            <th>Повторы</th>
          </tr>
        </thead>
        <tbody>
          $bodyRows
        </tbody>
      </table>
    </section>

    <div class="footer">Сформировано в Trener</div>
  </div>

</body>
</html>
''';
  }

  String _fmtWeight(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  @override
  void dispose() {
    _programListController.dispose();
    super.dispose();
  }

  void _scrollToLastDoneSlot(List<ProgramSlotVm> slots) {
    if (_didAutoScrollToLastDone) return;
    if (!_programListController.hasClients) return;

    var lastDoneIdx = -1;
    for (var i = 0; i < slots.length; i++) {
      if (slots[i].isDone) lastDoneIdx = i;
    }

    _didAutoScrollToLastDone = true;
    if (lastDoneIdx < 0) return;

    const estimatedItemExtent = 88.0;
    final rawOffset = lastDoneIdx * estimatedItemExtent;
    final maxOffset = _programListController.position.maxScrollExtent;
    final targetOffset = rawOffset.clamp(0.0, maxOffset);

    _programListController.jumpTo(targetOffset);
  }

  Future<void> _openSwapDayDialog({
    required ProgramOverviewVm overview,
    required ProgramSlotVm source,
    required String gender,
  }) async {
    if (source.isDone) return;

    final sourceTitle = _templateTitleForIdx(source.templateIdx, gender);
    final db = AppDbScope.of(context);
    final extraSlots = await db.getUpcomingPlannedSlots(
      clientId: widget.clientId,
      fromAbsoluteIndexExclusive: overview.slots.last.absoluteIndex,
      count: gender == 'М' ? 9 : 8,
    );

    final combinedSlots = <ProgramSlotVm>[...overview.slots, ...extraSlots];

    final seenAbs = <int>{};
    final candidates = combinedSlots
        .where(
          (s) =>
              !s.isDone &&
              s.absoluteIndex != source.absoluteIndex &&
              _templateTitleForIdx(s.templateIdx, gender) == sourceTitle &&
              seenAbs.add(s.absoluteIndex),
        )
        .toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Нет подходящих дней для замены этого типа тренировки.',
          ),
        ),
      );
      return;
    }

    Future<List<WorkoutExerciseVm>> loadPreview(ProgramSlotVm slot) {
      return db
          .getWorkoutDetailsForClientOnDayForcedTemplateIdx(
            clientId: widget.clientId,
            day: widget.day ?? DateTime.now(),
            templateIdx: slot.templateIdx,
          )
          .then((t) => t.$3);
    }

    ProgramSlotVm? selected;
    Future<List<WorkoutExerciseVm>>? previewFuture;

    final target = await showModalBottomSheet<ProgramSlotVm>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void selectForPreview(ProgramSlotVm slot) {
            setModalState(() {
              if (selected?.absoluteIndex == slot.absoluteIndex) {
                selected = null;
                previewFuture = null;
                return;
              }
              selected = slot;
              previewFuture = loadPreview(slot);
            });
          }

          return SafeArea(
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.35,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Заменить «День ${source.slotIndex} • $sourceTitle» на:',
                      ),
                      subtitle: const Text(
                        'Выберите день того же типа. Нажмите на день, чтобы открыть предпросмотр упражнений.',
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: candidates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final s = candidates[i];
                          final isSelected =
                              selected?.absoluteIndex == s.absoluteIndex;

                          return Card(
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.swap_horiz),
                                  title: Text(
                                    'День ${s.slotIndex} • $sourceTitle',
                                  ),
                                  trailing: Icon(
                                    isSelected
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                  onTap: () => selectForPreview(s),
                                ),
                                if (isSelected)
                                  FutureBuilder<List<WorkoutExerciseVm>>(
                                    future: previewFuture,
                                    builder: (context, snap) {
                                      if (snap.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: LinearProgressIndicator(),
                                        );
                                      }

                                      if (snap.hasError) {
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            4,
                                            12,
                                            12,
                                          ),
                                          child: Text(
                                            'Не удалось загрузить упражнения: ${snap.error}',
                                          ),
                                        );
                                      }

                                      final items =
                                          snap.data ??
                                          const <WorkoutExerciseVm>[];
                                      return Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              items.isEmpty
                                                  ? 'Упражнений нет'
                                                  : 'Упражнения: ${items.map((e) => e.name).join(' • ')}',
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: FilledButton.icon(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(s),
                                                icon: const Icon(
                                                  Icons.swap_horiz,
                                                ),
                                                label: const Text(
                                                  'Заменить на этот день',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );

    if (target == null) return;

    try {
      await db.swapPlannedProgramDays(
        clientId: widget.clientId,
        firstAbsoluteIndex: source.absoluteIndex,
        secondAbsoluteIndex: target.absoluteIndex,
      );
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дни успешно переставлены.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось переставить дни: $e')));
    }
  }

  String _templateTitleForIdx(int idx, String gender) {
    // Быстрый “человеческий” заголовок без лишних запросов:
    // М: спина/грудь/ноги по кругу, Ж: верх/низ по кругу
    if (gender == 'М') {
      const groups = ['Спина', 'Грудь', 'Ноги'];
      return groups[idx % 3];
    } else if (gender == 'Ж') {
      const groups = [
        'Спина',
        'Ноги',
        'Грудь',
        'Ноги',
        'Спина',
        'Ноги',
        'Грудь',
        'Ноги',
      ];
      return groups[idx % 8];
    }
    return 'Пробная';
  }

  @override
  Widget build(BuildContext context) {
    final chosenDay = widget.day ?? DateTime.now();
    final dayFmt = DateFormat('d MMM yyyy', 'ru');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Программа'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: FutureBuilder<_ProgramData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  'Ошибка: ${snap.error}\n\n${snap.stackTrace ?? ''}',
                ),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: Text('Нет данных'));
          }

          final data = snap.data!;
          final overview = data.overview;
          final st = overview.st;
          final gender = data.gender;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollToLastDoneSlot(overview.slots);
          });

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Дата: ${dayFmt.format(chosenDay)} • Абонемент: ${st.planSize}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          'Выполнено: ${st.completedInPlan}/${st.planSize}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _shiftDays(-1),
                          icon: const Icon(Icons.keyboard_double_arrow_left),
                          label: const Text('День -1'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _shiftDays(1),
                          icon: const Icon(Icons.keyboard_double_arrow_right),
                          label: const Text('День +1'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: _sharingReport
                              ? null
                              : () => _shareReport(data, chosenDay),
                          icon: _sharingReport
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.ios_share),
                          label: const Text('Отчёт'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              if (st.planSize <= 0)
                const Expanded(
                  child: Center(
                    child: Text('У клиента нет активной программы/абонемента'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    controller: _programListController,
                    padding: const EdgeInsets.all(12),
                    itemCount: overview.slots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final slot = overview.slots[i];
                      final isDone = slot.isDone;

                      final title = _templateTitleForIdx(
                        slot.templateIdx,
                        gender,
                      );

                      final subtitle = isDone ? '✅ Выполнено' : 'Запланировано';

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            isDone
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                          ),
                          title: Text('День ${slot.slotIndex} • $title'),
                          subtitle: Text(subtitle),
                          trailing: isDone
                              ? const Icon(Icons.chevron_right)
                              : FilledButton(
                                  onPressed: () async {
                                    final displayTitle =
                                        'День ${slot.slotIndex} • $title';
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => WorkoutScreen(
                                          clientId: widget.clientId,
                                          day: chosenDay,
                                          templateIdx:
                                              slot.templateIdx, // 🔥 главное
                                          displayTitle: displayTitle,
                                          absoluteIndex: slot.absoluteIndex,
                                        ),
                                      ),
                                    );
                                    if (!mounted) return;
                                    await _reload();
                                  },
                                  child: const Text('Провести'),
                                ),
                          onTap: () async {
                            if (isDone) {
                              // Открываем фактическую тренировку по дате выполнения
                              final day = slot.performedAt!;
                              final displayTitle =
                                  'День ${slot.slotIndex} • $title';
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WorkoutScreen(
                                    clientId: widget.clientId,
                                    day: day,
                                    templateIdx: slot.templateIdx,
                                    displayTitle: displayTitle,
                                    absoluteIndex: slot.absoluteIndex,
                                  ),
                                ),
                              );
                              if (!mounted) return;
                              await _reload();
                            } else {
                              // Предпросмотр будущей тренировки (упражнения + последний вес/повторы)
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => WorkoutPreviewSheet(
                                  clientId: widget.clientId,
                                  day: chosenDay,
                                  templateIdx: slot.templateIdx,
                                  title: 'День ${slot.slotIndex} • $title',
                                ),
                              );
                            }
                          },
                          onLongPress: isDone
                              ? null
                              : () => _openSwapDayDialog(
                                  overview: overview,
                                  source: slot,
                                  gender: gender,
                                ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportRow {
  final String dayLabel;
  final String exerciseName;
  final double? weightKg;
  final int? reps;

  const _ReportRow({
    required this.dayLabel,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
  });
}

class WorkoutPreviewSheet extends StatefulWidget {
  final String clientId;
  final DateTime day;
  final int templateIdx;
  final String title;

  const WorkoutPreviewSheet({
    super.key,
    required this.clientId,
    required this.day,
    required this.templateIdx,
    required this.title,
  });

  @override
  State<WorkoutPreviewSheet> createState() => _WorkoutPreviewSheetState();
}

class _WorkoutPreviewSheetState extends State<WorkoutPreviewSheet> {
  bool _loaded = false;
  late Future<List<WorkoutExerciseVm>> _future;

  Future<List<WorkoutExerciseVm>> _loadExercises() {
    final db = AppDbScope.of(context);

    return db
        .getWorkoutDetailsForClientOnDayForcedTemplateIdx(
          clientId: widget.clientId,
          day: widget.day,
          templateIdx: widget.templateIdx,
        )
        .then((t) => t.$3);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadExercises();
    });
  }

  Future<void> _patchExercises(
    List<WorkoutExerciseVm> Function(List<WorkoutExerciseVm> current) patch,
  ) async {
    final current = await _future;
    if (!mounted) return;
    final snapshot = List<WorkoutExerciseVm>.from(current);
    setState(() {
      _future = Future.value(patch(snapshot));
    });
  }

  Future<void> _renameExercise(WorkoutExerciseVm e) async {
    final ctrl = TextEditingController(text: e.name);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать упражнение'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Новое название',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (next == null || next.trim().isEmpty) return;

    final db = AppDbScope.of(context);
    await db.renameWorkoutExerciseForClient(
      clientId: widget.clientId,
      templateExerciseId: e.templateExerciseId,
      newName: next,
    );
    await _patchExercises((current) {
      return current
          .map((item) {
            if (item.templateExerciseId != e.templateExerciseId) return item;
            return WorkoutExerciseVm(
              templateExerciseId: item.templateExerciseId,
              templateId: item.templateId,
              orderIndex: item.orderIndex,
              name: next,
              lastWeightKg: item.lastWeightKg,
              lastReps: item.lastReps,
              supersetGroup: item.supersetGroup,
            );
          })
          .toList(growable: false);
    });
  }

  Future<void> _toggleSuperset(WorkoutExerciseVm e) async {
    final db = AppDbScope.of(context);
    await db.toggleClientSupersetWithNext(
      clientId: widget.clientId,
      templateId: e.templateId,
      templateExerciseId: e.templateExerciseId,
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _deleteExercise(WorkoutExerciseVm e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить упражнение?'),
        content: Text('«${e.name}» будет удалено из этого дня программы.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final db = AppDbScope.of(context);
    await db.deleteWorkoutExerciseForClient(
      clientId: widget.clientId,
      templateExerciseId: e.templateExerciseId,
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _addExercise(List<WorkoutExerciseVm> current) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новое упражнение'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Название упражнения',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;

    final db = AppDbScope.of(context);
    final templateId = current.isNotEmpty
        ? current.first.templateId
        : await db.getTemplateIdForClientTemplateIdx(
            clientId: widget.clientId,
            templateIdx: widget.templateIdx,
          );

    if (templateId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить день программы.')),
      );
      return;
    }

    await db.addWorkoutExerciseForClient(
      clientId: widget.clientId,
      templateId: templateId,
      name: name,
    );
    if (!mounted) return;
    await _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _future = _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Material(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer.withOpacity(0.75),
                        theme.colorScheme.surface,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Редактирование упражнений',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _refresh,
                        tooltip: 'Обновить',
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Закрыть',
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: FutureBuilder<List<WorkoutExerciseVm>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Text(
                              'Ошибка: ${snap.error}${snap.stackTrace ?? ''}',
                            ),
                          ),
                        );
                      }

                      final exercises =
                          snap.data ?? const <WorkoutExerciseVm>[];

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                        itemCount: exercises.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = exercises[i];

                          final lastText =
                              (e.lastWeightKg != null || e.lastReps != null)
                              ? '${e.lastWeightKg?.toStringAsFixed(1) ?? '—'} кг • ${e.lastReps ?? '—'} повт.'
                              : 'Нет истории';

                          return Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(0.45),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                10,
                                10,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          e.name,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      if (e.supersetGroup != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .tertiaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            'Суперсет',
                                            style: theme.textTheme.labelSmall,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    lastText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      FilledButton.tonalIcon(
                                        onPressed: () => _renameExercise(e),
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Название'),
                                      ),
                                      FilledButton.tonalIcon(
                                        onPressed: () => _toggleSuperset(e),
                                        icon: const Icon(Icons.link),
                                        label: Text(
                                          e.supersetGroup != null
                                              ? 'Убрать суперсет'
                                              : 'Суперсет +',
                                        ),
                                      ),
                                      FilledButton.tonalIcon(
                                        onPressed: () => _deleteExercise(e),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Удалить'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                FutureBuilder<List<WorkoutExerciseVm>>(
                  future: _future,
                  builder: (context, snap) {
                    final current = snap.data ?? const <WorkoutExerciseVm>[];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _addExercise(current),
                          icon: const Icon(Icons.add),
                          label: const Text('Добавить упражнение'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgramData {
  final String gender; // 'М' / 'Ж' / 'П'
  final ProgramOverviewVm overview;

  _ProgramData({required this.gender, required this.overview});
}
