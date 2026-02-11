// lib/features/clients/client_program_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final gender = (client?.gender ?? 'М');
    return _ProgramData(
      gender: (gender == 'Ж') ? 'Ж' : 'М',
      overview: overview,
    );
  }

  Future<void> _reload() async {
    final db = AppDbScope.of(context);
    setState(() {
      _future = _load(db);
    });
  }

  Future<void> _shiftWindow(int delta) async {
    final db = AppDbScope.of(context);
    await db.shiftClientProgramWindow(clientId: widget.clientId, delta: delta);
    await _reload();
  }

  String _templateTitleForIdx(int idx, String gender) {
    // Быстрый “человеческий” заголовок без лишних запросов:
    // М: спина/грудь/ноги по кругу, Ж: верх/низ по кругу
    if (gender == 'М') {
      const groups = ['Спина', 'Грудь', 'Ноги'];
      return groups[idx % 3];
    } else {
      const groups = ['Верх', 'Низ'];
      return groups[idx % 2];
    }
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

                    if (st.planSize == 4) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _shiftWindow(-4),
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Пред. 4'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _shiftWindow(4),
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('След. 4'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              st.windowStart == 0
                                  ? 'Окно: 1–4 из 8'
                                  : 'Окно: 5–8 из 8',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: ListView.separated(
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

                    final subtitle = isDone
                        ? '✅ Выполнено: ${dayFmt.format(slot.performedAt!)}'
                        : 'Слот ${slot.slotIndex}/${st.planSize} • Тренировка ${slot.templateIdx + 1}';

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                        ),
                        title: Text(
                          '$title • Тренировка ${slot.templateIdx + 1}',
                        ),
                        subtitle: Text(subtitle),
                        trailing: isDone
                            ? const Icon(Icons.chevron_right)
                            : FilledButton(
                                onPressed: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkoutScreen(
                                        clientId: widget.clientId,
                                        day: chosenDay,
                                        templateIdx:
                                            slot.templateIdx, // 🔥 главное
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
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => WorkoutScreen(
                                  clientId: widget.clientId,
                                  day: day,
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
                                title:
                                    '$title • Тренировка ${slot.templateIdx + 1}',
                              ),
                            );
                          }
                        },
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    final db = AppDbScope.of(context);

    // Берём упражнения “как будто на этот день выбрана эта тренировка”
    _future = db
        .getWorkoutDetailsForClientOnDayForcedTemplateIdx(
          clientId: widget.clientId,
          day: widget.day,
          templateIdx: widget.templateIdx,
        )
        .then((t) => t.$3);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Material(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Предпросмотр • ${widget.title}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
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
                              'Ошибка: ${snap.error}\n\n${snap.stackTrace ?? ''}',
                            ),
                          ),
                        );
                      }

                      final exercises =
                          snap.data ?? const <WorkoutExerciseVm>[];
                      if (exercises.isEmpty) {
                        return const Center(child: Text('Упражнений нет'));
                      }

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: exercises.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = exercises[i];

                          final lastKg = e.lastWeightKg;
                          final lastReps = e.lastReps;

                          final lastText = (lastKg != null || lastReps != null)
                              ? '${lastKg?.toStringAsFixed(1) ?? '—'} кг • ${lastReps ?? '—'} повт.'
                              : 'нет истории';

                          return Card(
                            child: ListTile(
                              title: Text(e.name),
                              subtitle: Text('Последнее: $lastText'),
                              trailing: e.supersetGroup != null
                                  ? const Icon(Icons.link)
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
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
  final String gender; // 'М' / 'Ж'
  final ProgramOverviewVm overview;

  _ProgramData({required this.gender, required this.overview});
}
