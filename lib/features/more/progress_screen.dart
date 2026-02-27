import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _loading = true;
  bool _sharing = false;

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
    await db.ensurePreviousMonthProgressSnapshot();
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
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _sharing
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
