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
      length: 2,
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
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ProgramTemplatesTab(future: _maleFuture),
            _ProgramTemplatesTab(future: _femaleFuture),
          ],
        ),
      ),
    );
  }
}

class _ProgramTemplatesTab extends StatelessWidget {
  const _ProgramTemplatesTab({required this.future});

  final Future<List<WorkoutTemplate>> future;

  @override
  Widget build(BuildContext context) {
    final db = AppDbScope.of(context);

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
              child: ExpansionTile(
                title: Text(t.title),
                subtitle: Text('${t.label} • Тренировка ${t.idx + 1}'),
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
                            ListTile(
                              dense: true,
                              title: Text(e.name),
                              trailing: e.groupId == null
                                  ? null
                                  : Chip(label: Text('СС ${e.groupId}')),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
