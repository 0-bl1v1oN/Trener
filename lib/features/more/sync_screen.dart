import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import '../../sync/connection_test_service.dart';
import '../../sync/sync_models.dart';
import '../../sync/sync_service.dart';
import '../../sync/sync_transport.dart';
import 'manual_workout_sync_sheet.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key, this.connectionTestService});

  final ConnectionTestService? connectionTestService;

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  AppDb? _db;
  SyncService? _service;
  SyncService? _manualService;
  bool _loading = true;
  bool _syncing = false;
  bool _checkingConnection = false;
  bool _rebuildingQueue = false;
  int _syncSent = 0;
  int _syncTotal = 0;
  int _pendingCount = 0;
  DateTime? _lastSuccessAt;
  List<SyncLogEntry> _logs = const [];
  Object? _error;

  late final ConnectionTestService _connectionTestService =
      widget.connectionTestService ?? ConnectionTestService.fromEnvironment();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDbScope.of(context);
    if (identical(_db, db)) return;
    _db = db;
    final transport = HttpSyncTransport.fromEnvironment();
    _service = SyncService(db: db, transport: transport);
    _manualService = SyncService(db: db, transport: transport);
    _load();
  }

  Future<void> _load() async {
    final db = _db;
    if (db == null) return;
    try {
      await db.cleanupSyncLogs();
      final values = await Future.wait<Object?>([
        db.getPendingSyncTaskCount(),
        db.getLastSuccessfulSyncAt(),
        db.getRecentSyncLogs(),
      ]);
      if (!mounted) return;
      setState(() {
        _pendingCount = values[0]! as int;
        _lastSuccessAt = values[1] as DateTime?;
        _logs = values[2]! as List<SyncLogEntry>;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _syncNow() async {
    final service = _service;
    if (service == null ||
        _syncing ||
        _checkingConnection ||
        _rebuildingQueue) {
      return;
    }
    setState(() {
      _syncing = true;
      _syncSent = 0;
      _syncTotal = _pendingCount;
    });
    try {
      final result = await service.syncPending(
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _syncSent = progress.sent;
            _syncTotal = progress.total;
          });
        },
      );
      if (!mounted) return;
      await _showSyncResult(result);
      await _load();
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _showSyncResult(SyncRunResult result) async {
    if (result.status == SyncRunStatus.notConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Токен сервера не настроен.')),
      );
      return;
    }
    if (result.stopReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Синхронизация завершена\nОтправлено: ${result.succeeded}',
          ),
        ),
      );
      return;
    }

    final httpError = result.httpStatus == null
        ? result.errorMessage ?? 'Не удалось подключиться к серверу.'
        : 'HTTP ${result.httpStatus}';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Синхронизация остановлена'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Успешно отправлено: ${result.succeeded}'),
              const SizedBox(height: 8),
              Text('Ошибка: $httpError'),
              if (result.responseBody != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'Ответ сервера:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  result.responseBody!,
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkConnection() async {
    if (_checkingConnection || _syncing || _rebuildingQueue) return;
    setState(() => _checkingConnection = true);
    try {
      final result = await _connectionTestService.run();
      if (!mounted) return;
      final message = switch (result.status) {
        ConnectionTestStatus.success =>
          'Сервер доступен. Тестовые данные успешно отправлены.'
              '${result.recordId == null ? '' : ' ID записи: ${result.recordId}'}',
        ConnectionTestStatus.httpError =>
          'Сервер вернул ошибку: HTTP ${result.httpStatus}',
        ConnectionTestStatus.connectionError =>
          'Не удалось подключиться к серверу.',
        ConnectionTestStatus.notConfigured => 'Токен сервера не настроен.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _checkingConnection = false);
    }
  }

  Future<void> _openManualSend() async {
    final db = _db;
    final service = _manualService;
    if (db == null ||
        service == null ||
        _syncing ||
        _checkingConnection ||
        _rebuildingQueue) {
      return;
    }
    final outcome = await showModalBottomSheet<ManualWorkoutSendOutcome>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ManualWorkoutSyncSheet(db: db, service: service),
    );
    if (!mounted || outcome == null) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(outcome.message)));
  }

  Future<void> _rebuildQueue() async {
    final db = _db;
    if (db == null || _syncing || _checkingConnection || _rebuildingQueue) {
      return;
    }

    setState(() => _rebuildingQueue = true);
    try {
      final preview = await db.analyzeWorkoutSyncQueueRebuild();
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Пересобрать очередь?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Очередь синхронизации будет заново сформирована из '
                  'локальной истории тренировок. Сами тренировки и '
                  'результаты изменены не будут.',
                ),
                const SizedBox(height: 16),
                Text('Всего workout_sessions: ${preview.totalSessions}'),
                Text('Будет добавлено в очередь: ${preview.tasksToCreate}'),
                Text('Исключено пустых: ${preview.emptySessions}'),
                Text('Исключено удалённых клиентов: ${preview.missingClients}'),
                Text(
                  'Исключено без workout UUID: '
                  '${preview.missingWorkoutExternalIds}',
                ),
                Text('Конфликтных тренировок: ${preview.conflictSessions}'),
                Text('Ошибок payload: ${preview.payloadErrors}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Пересобрать'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final result = await db.rebuildWorkoutSyncQueue(preview);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Очередь пересобрана\n'
            'Задач создано: ${result.createdTasks}\n'
            'Пустых пропущено: ${result.emptySessions}\n'
            'Отсутствующих клиентов пропущено: ${result.missingClients}\n'
            'Конфликтных пропущено: ${result.conflictSessions}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось пересобрать очередь: $error')),
      );
    } finally {
      if (mounted) setState(() => _rebuildingQueue = false);
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('dd.MM.yyyy HH:mm', 'ru_RU').format(value.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Синхронизация')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (_error != null)
                    Card(
                      color: colors.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text('Не удалось прочитать очередь: $_error'),
                      ),
                    ),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cloud_queue_outlined,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Очередь синхронизации',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _StatusRow(
                            label: 'Последняя успешная синхронизация',
                            value: _formatDate(_lastSuccessAt),
                          ),
                          const SizedBox(height: 10),
                          _StatusRow(
                            label: 'Ожидают отправки',
                            value: '$_pendingCount',
                          ),
                          if (_syncing) ...[
                            const SizedBox(height: 10),
                            _StatusRow(
                              label: 'Прогресс',
                              value: 'Отправлено $_syncSent из $_syncTotal',
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _syncing ||
                                      _checkingConnection ||
                                      _rebuildingQueue
                                  ? null
                                  : _syncNow,
                              icon: _syncing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.sync),
                              label: const Text('Синхронизировать сейчас'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _syncing ||
                                      _checkingConnection ||
                                      _rebuildingQueue
                                  ? null
                                  : _checkConnection,
                              icon: _checkingConnection
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.wifi_tethering_outlined),
                              label: const Text('Проверить соединение'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _syncing ||
                                      _checkingConnection ||
                                      _rebuildingQueue
                                  ? null
                                  : _rebuildQueue,
                              icon: _rebuildingQueue
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.replay_circle_filled),
                              label: const Text('Пересобрать очередь'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Локальные данные работают независимо от сервера. '
                            'Ожидающие задачи сохраняются на устройстве.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Ручная отправка',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Выберите клиента и одну конкретную тренировку из очереди.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed:
                                  _syncing ||
                                      _checkingConnection ||
                                      _rebuildingQueue
                                  ? null
                                  : _openManualSend,
                              icon: const Icon(Icons.fitness_center),
                              label: const Text('Выбрать тренировку'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Журнал',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_logs.isEmpty)
                    const Card(
                      elevation: 0,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Событий синхронизации пока нет'),
                      ),
                    )
                  else
                    for (final log in _logs)
                      Card(
                        elevation: 0,
                        child: ListTile(
                          leading: Icon(
                            log.result == SyncLogResults.success
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: log.result == SyncLogResults.success
                                ? colors.primary
                                : colors.error,
                          ),
                          title: Text(
                            log.result == SyncLogResults.success
                                ? 'Успешно'
                                : 'Ошибка',
                          ),
                          subtitle: Text(
                            '${_formatDate(log.timestamp)} · попытка ${log.attemptNumber}'
                            '${log.message == null ? '' : '\n${log.message}'}',
                          ),
                          isThreeLine: log.message != null,
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
