import 'package:flutter/material.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class DefaultProgramsScreen extends StatefulWidget {
  const DefaultProgramsScreen({super.key});

  @override
  State<DefaultProgramsScreen> createState() => _DefaultProgramsScreenState();
}

class _DefaultProgramsScreenState extends State<DefaultProgramsScreen> {
  bool _loaded = false;
  late Future<List<WorkoutTemplate>> _maleFuture;
  late Future<List<WorkoutTemplate>> _femaleFuture;

  static const List<String> _trialExercises = [
    'Тяга верхнего блока параллельным хватом',
    'Тяга нижнего блока самолётным хватом',
    'Жим в хамере',
    'Жим ногами',
    'Выпады на месте',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    final db = AppDbScope.of(context);
    _maleFuture = db.getWorkoutTemplatesByGender('М');
    _femaleFuture = db.getWorkoutTemplatesByGender('Ж');
  }

  Future<void> _reload() async {
    final db = AppDbScope.of(context);
    setState(() {
      _maleFuture = db.getWorkoutTemplatesByGender('М');
      _femaleFuture = db.getWorkoutTemplatesByGender('Ж');
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Программа'),
          actions: [
            IconButton(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Мужчины'),
              Tab(text: 'Женщины'),
              Tab(text: 'Пробная'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProgramTemplatesTab(future: _maleFuture),
            _ProgramTemplatesTab(future: _femaleFuture),
            const _TrialProgramTab(exercises: _trialExercises),
          ],
        ),
      ),
    );
  }
}

class _ProgramTemplatesTab extends StatelessWidget {
  const _ProgramTemplatesTab({required this.future});

  final Future<List<WorkoutTemplate>> future;

  String _titleWithoutDayPrefix(String title) {
    final parts = title.split('•');
    if (parts.length > 1 && parts.first.trim().startsWith('День')) {
      return parts.sublist(1).join('•').trim();
    }
    return title.trim();
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDbScope.of(context);
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<List<WorkoutTemplate>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Ошибка: ${snap.error}'));
        }

        final list = snap.data ?? const <WorkoutTemplate>[];
        if (list.isEmpty) {
          return const Center(child: Text('Шаблоны не найдены'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final t = list[i];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                  childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  title: Text(_titleWithoutDayPrefix(t.title)),
                  subtitle: Text('Тренировка ${t.idx + 1}'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  children: [
                    FutureBuilder<List<WorkoutTemplateExercise>>(
                      future: db.getTemplateExercisesByTemplateId(t.id),
                      builder: (context, exSnap) {
                        final ex =
                            exSnap.data ?? const <WorkoutTemplateExercise>[];
                        if (ex.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Упражнений пока нет'),
                          );
                        }

                        return Column(
                          children: [
                            for (final e in ex)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest
                                      .withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(e.name)),
                                    if (e.groupId != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'Суперсет ${e.groupId}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color:
                                                    colors.onTertiaryContainer,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
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
}

class _TrialProgramTab extends StatelessWidget {
  const _TrialProgramTab({required this.exercises});

  final List<String> exercises;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant.withOpacity(0.7)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: const Text('Пробная тренировка'),
              subtitle: const Text('Тренировка 1'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              children: [
                for (final e in exercises)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(e),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
