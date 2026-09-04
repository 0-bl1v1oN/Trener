import 'package:flutter/material.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

/// Single catalog-only entry point for choosing an exercise for a program slot.
Future<ExerciseIdentity?> showExerciseSelector(
  BuildContext context, {
  AppDb? database,
}) {
  final db = database ?? AppDbScope.of(context);
  return showModalBottomSheet<ExerciseIdentity>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ExerciseSelectorSheet(db: db),
  );
}

class _ExerciseSelectorSheet extends StatefulWidget {
  const _ExerciseSelectorSheet({required this.db});

  final AppDb db;

  @override
  State<_ExerciseSelectorSheet> createState() => _ExerciseSelectorSheetState();
}

class _ExerciseSelectorSheetState extends State<_ExerciseSelectorSheet> {
  final _controller = TextEditingController();
  String _query = '';
  bool _creating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _createFromQuery() async {
    final value = _controller.text;
    if (AppDb.normalizeExerciseName(value).isEmpty || _creating) return;
    setState(() => _creating = true);
    try {
      final exercise = await widget.db.createExercise(value);
      if (mounted) Navigator.of(context).pop(exercise);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось добавить упражнение: $error')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Выберите упражнение',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Поиск упражнений',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              if (AppDb.normalizeExerciseName(_query).isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _creating ? null : _createFromQuery,
                  icon: _creating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text('Добавить «${_controller.text.trim()}»'),
                ),
              const SizedBox(height: 4),
              Expanded(
                child: FutureBuilder<List<ExerciseIdentity>>(
                  future: widget.db.searchExercises(_query),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final exercises =
                        snapshot.data ?? const <ExerciseIdentity>[];
                    if (exercises.isEmpty) {
                      return Center(
                        child: Text(
                          'Упражнения не найдены',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: exercises.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final exercise = exercises[index];
                        return ListTile(
                          title: Text(exercise.canonicalName),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).pop(exercise),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
