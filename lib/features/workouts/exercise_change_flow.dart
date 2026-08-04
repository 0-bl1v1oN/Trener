import 'package:flutter/material.dart';

import '../../db/app_db.dart';

enum ExerciseChangeKind { sameExercise, newExercise }

Future<ExerciseChangeKind?> showExerciseChangeDialog(BuildContext context) {
  return showDialog<ExerciseChangeKind>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Изменение упражнения'),
      content: const Text(
        'Это то же упражнение с новым названием или вы заменили его другим?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton.tonal(
          onPressed: () =>
              Navigator.pop(context, ExerciseChangeKind.sameExercise),
          child: const Text('То же упражнение'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, ExerciseChangeKind.newExercise),
          child: const Text('Новое упражнение'),
        ),
      ],
    ),
  );
}

Future<void> applyClientExerciseNameChange({
  required AppDb db,
  required String clientId,
  required int templateExerciseId,
  required String newName,
  required ExerciseChangeKind? kind,
}) async {
  if (kind == null) return;
  if (kind == ExerciseChangeKind.newExercise) {
    await db.replaceExerciseIdentityForClient(
      clientId: clientId,
      templateExerciseId: templateExerciseId,
    );
  }
  await db.renameWorkoutExerciseForClient(
    clientId: clientId,
    templateExerciseId: templateExerciseId,
    newName: newName,
  );
}

Future<void> applyTemplateExerciseNameChange({
  required AppDb db,
  required int templateExerciseId,
  required String newName,
  required ExerciseChangeKind? kind,
}) async {
  if (kind == null) return;
  if (kind == ExerciseChangeKind.newExercise) {
    await db.replaceTemplateExerciseIdentity(
      templateExerciseId: templateExerciseId,
    );
  }
  await db.renameWorkoutTemplateExercise(
    templateExerciseId: templateExerciseId,
    newName: newName,
  );
}
