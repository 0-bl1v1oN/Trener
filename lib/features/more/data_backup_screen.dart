import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/app_db_scope.dart';
import '../../main.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  final DateFormat _format = DateFormat('dd.MM.yyyy HH:mm');

  List<FileSystemEntity> _files = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reloadFiles();
  }

  Future<Directory> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'backups'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _reloadFiles() async {
    final dir = await _backupDir();
    final entities = await dir
        .list()
        .where((e) => e.path.endsWith('.json'))
        .toList();

    entities.sort((a, b) => b.path.compareTo(a.path));

    if (!mounted) return;
    setState(() => _files = entities);
  }

  Future<File> _createBackupFile() async {
    final db = AppDbScope.of(context);
    final dir = await _backupDir();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = p.join(dir.path, 'backup_$ts.json');
    await db.exportBackupToFile(filePath);
    return File(filePath);
  }

  Future<void> _createBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _createBackupFile();
      await _reloadFiles();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Резервная копия сохранена: ${p.basename(file.path)}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _createAndShareBackup() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await _createBackupFile();
      await _reloadFiles();

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Резервная копия данных MyFitness. Сохраните файл в облако/на устройство, чтобы восстановить данные после переустановки.',
        subject: 'Резервная копия MyFitness',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Открылось меню “Поделиться”. Сохраните файл вне приложения (например, в облако).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка внешнего экспорта: $e')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importBackup(File file) async {
    if (_busy) return;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Импорт данных'),
        content: Text(
          'Импорт из ${p.basename(file.path)} перезапишет текущие данные. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Импортировать'),
          ),
        ],
      ),
    );

    if (approved != true) return;

    setState(() => _busy = true);
    try {
      final db = AppDbScope.of(context);
      await db.importBackupFromFile(file.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Импорт завершён. Данные восстановлены.')),
      );

      final shouldRestart = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Перезапустить приложение?'),
          content: const Text(
            'Чтобы все экраны сразу обновили данные после импорта, рекомендуется перезапуск приложения.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Нет'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Да, перезапустить'),
            ),
          ],
        ),
      );

      if (shouldRestart == true && mounted) {
        await AppBootstrap.restart(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка импорта: $e')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickAndImportBackup() async {
    if (_busy) return;
    setState(() => _busy = true);

    File? localCopy;
    try {
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
      } on PlatformException catch (e) {
        final message = e.message?.toLowerCase() ?? '';
        final unsupportedFilter =
            message.contains('unsupported filter') ||
            message.contains('unsupported file extension');

        if (!unsupportedFilter) {
          rethrow;
        }

        result = await FilePicker.platform.pickFiles(type: FileType.any);
      }

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedPath = result.files.single.path;
      if (pickedPath == null || pickedPath.isEmpty) {
        throw const FileSystemException(
          'Не удалось получить путь выбранного файла',
        );
      }

      final pickedFile = File(pickedPath);
      if (!await pickedFile.exists()) {
        throw FileSystemException('Файл не найден', pickedPath);
      }
      final rawContent = await pickedFile.readAsString();
      final dynamic parsed = jsonDecode(rawContent);
      if (parsed is! Map<String, dynamic> || parsed['tables'] is! Map) {
        throw const FormatException('Выберите JSON-файл резервной копии');
      }

      // Сохраняем копию в локальном списке бэкапов приложения.
      final backupDir = await _backupDir();
      final targetPath = p.join(
        backupDir.path,
        'imported_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
      );
      localCopy = await pickedFile.copy(targetPath);
      await _reloadFiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка выбора файла: $e')));
      return;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }

    if (localCopy != null && mounted) {
      await _importBackup(localCopy);
    }
  }

  Future<void> _deleteBackup(File file) async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      if (await file.exists()) {
        await file.delete();
      }
      await _reloadFiles();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Удалено: ${p.basename(file.path)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Экспорт / Импорт данных')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _createBackup,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Создать резервную копию'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _createAndShareBackup,
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Создать и сохранить вне приложения'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickAndImportBackup,
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Импортировать из файла устройства'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Важно: чтобы бэкап пережил удаление приложения, после создания сохраните файл во внешнее место (облако, Телеграм, Google Drive, iCloud и т.д.).',
          ),
          const SizedBox(height: 20),
          Text(
            'Локальные копии в приложении',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (_files.isEmpty)
            const Card(
              child: ListTile(
                title: Text('Пока нет резервных копий'),
                subtitle: Text('Сначала нажмите «Создать резервную копию».'),
              ),
            )
          else
            ..._files.map((entity) {
              final file = File(entity.path);
              final stat = file.statSync();
              final subtitle =
                  '${_format.format(stat.modified)} · ${(stat.size / 1024).toStringAsFixed(1)} КБ';

              return Card(
                child: ListTile(
                  title: Text(p.basename(file.path)),
                  subtitle: Text(subtitle),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _busy ? null : () => _importBackup(file),
                        icon: const Icon(Icons.download_for_offline_outlined),
                        tooltip: 'Импортировать',
                      ),
                      IconButton(
                        onPressed: _busy ? null : () => _deleteBackup(file),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Удалить с устройства',
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
