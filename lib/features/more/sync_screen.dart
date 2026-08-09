import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import '../../sync/sync_models.dart';
import '../../sync/sync_service.dart';
import '../../sync/sync_transport.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  AppDb? _db;
  SyncService? _service;
  bool _loading = true;
  bool _syncing = false;
  int _syncSent = 0;
  int _syncTotal = 0;
  int _pendingCount = 0;
  DateTime? _lastSuccessAt;
  List<SyncLogEntry> _logs = const [];
  Object? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = AppDbScope.of(context);
    if (identical(_db, db)) return;
    _db = db;
    _service = SyncService(db: db, transport: const DisabledSyncTransport());
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
    if (service == null || _syncing) return;
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
      final message = switch ((result.status, result.stopReason)) {
        (SyncRunStatus.notConfigured, _) =>
          'Сервер синхронизации пока не настроен',
        (_, SyncRunStopReason.transientFailure) =>
          'Отправлено: ${result.succeeded}. '
              'Проход остановлен: сервер или сеть недоступны',
        (_, SyncRunStopReason.permanentFailure) =>
          'Отправлено: ${result.succeeded}. '
              'Проход остановлен: ошибка контракта сервера',
        _ => 'Отправлено: ${result.succeeded}, ошибок: ${result.failed}',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _load();
    } finally {
      if (mounted) setState(() => _syncing = false);
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
                                Icons.cloud_off_outlined,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Сервер не настроен',
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
                              onPressed: _syncing ? null : _syncNow,
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
