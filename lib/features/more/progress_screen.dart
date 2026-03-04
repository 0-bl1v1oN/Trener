import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  static const String _progressCollectionEnabledKey =
      'progress_collection_enabled';
  bool _loading = true;
  bool _sharing = false;
  bool _collectionEnabled = true;

  List<ProgressSnapshotVm> _snapshots = const [];
  int? _selectedSnapshotId;
  List<ProgressSnapshotClientVm> _clients = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<Directory> _progressExportDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'progress_exports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _reload() async {
    final db = AppDbScope.of(context);
    final prefs = await SharedPreferences.getInstance();
    final collectionEnabled =
        prefs.getBool(_progressCollectionEnabledKey) ?? true;

    if (collectionEnabled) {
      await db.ensurePreviousMonthProgressSnapshot();
    }
    final snapshots = await db.getProgressSnapshots();

    int? selected = _selectedSnapshotId;
    if (selected == null || !snapshots.any((s) => s.snapshotId == selected)) {
      selected = snapshots.isEmpty ? null : snapshots.first.snapshotId;
    }

    final clients = selected == null
        ? const <ProgressSnapshotClientVm>[]
        : await db.getSnapshotClients(selected);

    if (!mounted) return;
    setState(() {
      _snapshots = snapshots;
      _selectedSnapshotId = selected;
      _clients = clients;
      _collectionEnabled = collectionEnabled;
      _loading = false;
    });
  }

  Future<void> _changeSnapshot(int id) async {
    final db = AppDbScope.of(context);
    final clients = await db.getSnapshotClients(id);
    if (!mounted) return;
    setState(() {
      _selectedSnapshotId = id;
      _clients = clients;
    });
  }

  Future<void> _toggleCollection(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_progressCollectionEnabledKey, enabled);
    if (!mounted) return;

    setState(() {
      _collectionEnabled = enabled;
      _loading = true;
    });

    await _reload();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Сбор данных прогресса включён'
              : 'Сбор данных прогресса выключен',
        ),
      ),
    );
  }

  Future<void> _deleteSelectedMonthData() async {
    final selected = _selectedSnapshot;
    if (selected == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить данные за месяц?'),
        content: Text(
          'Будут удалены все данные прогресса за период ${selected.periodKey}. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = AppDbScope.of(context);
    await db.deleteProgressSnapshot(selected.snapshotId);

    if (!mounted) return;
    setState(() => _loading = true);
    await _reload();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Данные за ${selected.periodKey} удалены')),
    );
  }

  Future<void> _exportSelectedSnapshot() async {
    final selected = _selectedSnapshotId;
    if (selected == null || _sharing) return;

    setState(() => _sharing = true);
    try {
      final db = AppDbScope.of(context);
      final payload = await db.buildProgressExportPayload(selected);
      final period = payload['period'] as String? ?? 'unknown';

      final dir = await _progressExportDir();
      final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(p.join(dir.path, 'progress_${period}_$ts.json'));
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(payload),
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Экспорт прогресса за $period',
        subject: 'Progress export $period',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл собран: ${p.basename(file.path)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  ProgressSnapshotVm? get _selectedSnapshot {
    final selected = _selectedSnapshotId;
    if (selected == null) return null;
    for (final s in _snapshots) {
      if (s.snapshotId == selected) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Прогресс')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          value: _selectedSnapshotId,
                          decoration: const InputDecoration(
                            labelText: 'Период',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _snapshots
                              .map(
                                (s) => DropdownMenuItem<int>(
                                  value: s.snapshotId,
                                  child: Text(s.periodKey),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (v) {
                            if (v == null) return;
                            _changeSnapshot(v);
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Клиентов в периоде: ${_selectedSnapshot?.clientsCount ?? 0}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _collectionEnabled,
                          title: const Text('Сбор данных прогресса'),
                          subtitle: const Text(
                            'Автосбор среза за предыдущий месяц',
                          ),
                          onChanged: _toggleCollection,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _selectedSnapshot == null
                                ? null
                                : _deleteSelectedMonthData,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text(
                              'Удалить данные за выбранный месяц',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _sharing || _selectedSnapshot == null
                                ? null
                                : _exportSelectedSnapshot,
                            icon: const Icon(Icons.ios_share),
                            label: const Text('Собрать данные'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _clients.isEmpty
                        ? Center(
                            child: Text(
                              'Нет данных за выбранный период',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: _clients.length,
                            itemBuilder: (context, i) {
                              final c = _clients[i];
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: colors.outlineVariant.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c.clientName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Отходил занятий: ${c.sessionsDone}',
                                      ),
                                      const SizedBox(height: 8),
                                      ...c.days.map((d) {
                                        final dayNumber = d['dayNumber'] ?? '?';
                                        final title =
                                            d['title'] ?? 'Тренировка';
                                        final exercises =
                                            (d['exercises'] as List?) ??
                                            const [];
                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: colors
                                                .surfaceContainerHighest
                                                .withOpacity(0.35),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('День $dayNumber ($title)'),
                                              const SizedBox(height: 4),
                                              ...exercises.map((raw) {
                                                final row = raw is Map
                                                    ? raw
                                                    : const <String, dynamic>{};
                                                final name =
                                                    row['name'] ?? 'Упражнение';
                                                final w = row['weightKg'];
                                                final wt = w == null
                                                    ? '—'
                                                    : '${(w as num).toStringAsFixed(1)} кг';
                                                return Text('• $name — $wt');
                                              }),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
