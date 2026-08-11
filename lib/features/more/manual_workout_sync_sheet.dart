import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../db/app_db.dart';
import '../../sync/sync_models.dart';
import '../../sync/sync_service.dart';
import '../../sync/workout_sync_payload.dart';

class ManualWorkoutSendOutcome {
  const ManualWorkoutSendOutcome({required this.message});

  final String message;
}

class ManualWorkoutSyncSheet extends StatefulWidget {
  const ManualWorkoutSyncSheet({
    super.key,
    required this.db,
    required this.service,
  });

  final AppDb db;
  final SyncService service;

  @override
  State<ManualWorkoutSyncSheet> createState() => _ManualWorkoutSyncSheetState();
}

class _ManualWorkoutSyncSheetState extends State<ManualWorkoutSyncSheet> {
  List<PendingWorkoutSyncClientVm>? _clients;
  PendingWorkoutSyncClientVm? _selectedClient;
  List<PendingWorkoutSyncTaskVm>? _tasks;
  PendingWorkoutSyncTaskVm? _selectedTask;
  WorkoutSyncPayload? _preview;
  bool _sending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() {
      _clients = null;
      _errorMessage = null;
    });
    try {
      final clients = await widget.db.getPendingWorkoutSyncClients();
      if (!mounted) return;
      setState(() => _clients = clients);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Не удалось прочитать очередь.');
    }
  }

  Future<void> _selectClient(PendingWorkoutSyncClientVm client) async {
    setState(() {
      _selectedClient = client;
      _tasks = null;
      _errorMessage = null;
    });
    try {
      final tasks = await widget.db.getPendingWorkoutSyncTasksForClient(
        client.clientId,
      );
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Не удалось прочитать тренировки.');
    }
  }

  Future<void> _selectTask(PendingWorkoutSyncTaskVm task) async {
    setState(() {
      _selectedTask = task;
      _preview = null;
      _errorMessage = null;
    });
    try {
      final queued = await widget.db.getPendingWorkoutSyncTask(task.taskId);
      final preview = queued == null
          ? null
          : await widget.db.buildWorkoutSyncPayload(queued.entityExternalId);
      if (!mounted) return;
      if (preview == null) {
        setState(() => _errorMessage = 'Тренировка уже не ожидает отправки.');
        return;
      }
      setState(() => _preview = preview);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Не удалось подготовить предпросмотр.');
    }
  }

  Future<void> _sendSelected() async {
    final task = _selectedTask;
    if (task == null || _sending) return;
    setState(() {
      _sending = true;
      _errorMessage = null;
    });
    final result = await widget.service.syncTaskById(task.taskId);
    if (!mounted) return;
    if (result.status == SingleSyncStatus.success) {
      final idSuffix = result.recordId == null
          ? ''
          : '. ID записи: ${result.recordId}';
      Navigator.of(
        context,
      ).pop(ManualWorkoutSendOutcome(message: '${result.message}$idSuffix'));
      return;
    }
    setState(() {
      _sending = false;
      _errorMessage = result.message;
    });
  }

  void _goBack() {
    if (_sending) return;
    if (_selectedTask != null) {
      setState(() {
        _selectedTask = null;
        _preview = null;
        _errorMessage = null;
      });
      return;
    }
    if (_selectedClient != null) {
      setState(() {
        _selectedClient = null;
        _tasks = null;
        _errorMessage = null;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = _selectedTask != null
        ? 'Предпросмотр'
        : _selectedClient != null
        ? _selectedClient!.name
        : 'Выберите клиента';
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _sending ? null : _goBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    if (_selectedTask != null) return _buildPreview();
    if (_selectedClient != null) return _buildTasks();
    return _buildClients();
  }

  Widget _buildClients() {
    final clients = _clients;
    if (clients == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (clients.isEmpty) {
      return const Center(child: Text('Нет тренировок, ожидающих отправки'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: clients.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final client = clients[index];
        return Card(
          elevation: 0,
          child: ListTile(
            title: Text(client.name),
            subtitle: Text('Ожидают отправки: ${client.pendingWorkoutCount}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectClient(client),
          ),
        );
      },
    );
  }

  Widget _buildTasks() {
    final tasks = _tasks;
    if (tasks == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tasks.isEmpty) {
      return const Center(child: Text('У клиента нет ожидающих тренировок'));
    }
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'ru_RU');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final dayName = task.displayName;
        return Card(
          elevation: 0,
          child: ListTile(
            title: Text(dayName ?? 'Тренировка'),
            subtitle: Text(
              '${dateFormat.format(task.performedAt.toLocal())}\n'
              'Упражнений: ${task.exerciseCount}',
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectTask(task),
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    final preview = _preview;
    if (preview == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final date = DateFormat(
      'dd.MM.yyyy HH:mm',
      'ru_RU',
    ).format(preview.performedAt.toLocal());
    final dayName = _firstNonEmpty(preview.dayTitle, preview.dayLabel);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _PreviewField(label: 'Клиент', value: preview.clientName),
        const SizedBox(height: 12),
        _PreviewField(label: 'Дата', value: date),
        if (dayName != null) ...[
          const SizedBox(height: 12),
          _PreviewField(label: 'Тренировка', value: dayName),
        ],
        const SizedBox(height: 18),
        Text(
          'Упражнения',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final exercise in preview.exercises)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('• ${exercise.name} — ${_resultText(exercise)}'),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _sending ? null : _sendSelected,
          icon: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload_outlined),
          label: const Text('Отправить эту тренировку'),
        ),
      ],
    );
  }

  String _resultText(WorkoutSyncExerciseSource exercise) {
    final weight = exercise.weightKg;
    final reps = exercise.reps;
    final weightText = weight == null
        ? null
        : '${weight == weight.roundToDouble() ? weight.toInt() : weight} кг';
    if (weightText != null && reps != null) return '$weightText × $reps';
    if (weightText != null) return weightText;
    if (reps != null) return '$reps повторов';
    return 'нет данных';
  }

  String? _firstNonEmpty(String? first, String? second) {
    final firstValue = first?.trim() ?? '';
    if (firstValue.isNotEmpty) return firstValue;
    final secondValue = second?.trim() ?? '';
    return secondValue.isEmpty ? null : secondValue;
  }
}

class _PreviewField extends StatelessWidget {
  const _PreviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
