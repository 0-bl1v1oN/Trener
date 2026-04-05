import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppErrorReport {
  final DateTime timestamp;
  final String source;
  final Object error;
  final StackTrace stackTrace;

  const AppErrorReport({
    required this.timestamp,
    required this.source,
    required this.error,
    required this.stackTrace,
  });

  String get formatted =>
      '[${timestamp.toIso8601String()}][$source] $error\n$stackTrace';
}

class AppErrorReporter {
  static final ValueNotifier<AppErrorReport?> lastError =
      ValueNotifier<AppErrorReport?>(null);

  static void record(
    Object error,
    StackTrace stackTrace, {
    required String source,
  }) {
    final report = AppErrorReport(
      timestamp: DateTime.now(),
      source: source,
      error: error,
      stackTrace: stackTrace,
    );
    lastError.value = report;
    debugPrint('⛔ APP ERROR ${report.formatted}');
  }

  static void clear() {
    lastError.value = null;
  }
}

class AppErrorOverlay extends StatelessWidget {
  const AppErrorOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppErrorReport?>(
      valueListenable: AppErrorReporter.lastError,
      builder: (context, report, _) {
        if (report == null) return child;
        return Stack(
          children: [
            child,
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ошибка (${report.source})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.error.toString(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: report.formatted),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Текст ошибки скопирован'),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Копировать',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: AppErrorReporter.clear,
                                child: const Text(
                                  'Скрыть',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
