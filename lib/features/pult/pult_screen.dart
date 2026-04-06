import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../app/app_db_scope.dart';
import '../../db/app_db.dart';
import 'pult_store.dart';

class _PultHeaderVideoWarmup {
  static Future<void>? _future;

  static Future<void> ensureWarmedUp() {
    return _future ??= _warmUp();
  }

  static Future<void> _warmUp() async {
    final controller = VideoPlayerController.asset(
      _PultWorkoutPageState.headerVideoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await controller.initialize();
    } catch (_) {
      // Warm-up is best effort only.
    } finally {
      await controller.dispose();
    }
  }
}

class _PultAssetVideoWarmup {
  static final Map<String, Future<void>> _futures = <String, Future<void>>{};

  static Future<void> warmUp(String assetPath) {
    return _futures.putIfAbsent(assetPath, () async {
      final controller = VideoPlayerController.asset(
        assetPath,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      try {
        await controller.initialize();
      } catch (_) {
        // best effort warm-up
      } finally {
        await controller.dispose();
      }
    });
  }
}

Future<void> warmUpPultHeaderVideo() {
  return _PultHeaderVideoWarmup.ensureWarmedUp();
}

class _PultHeaderBackgroundOption {
  final String id;
  final String title;
  final String subtitle;
  final String? assetPath;
  final String? previewAssetPath;
  final IconData icon;

  const _PultHeaderBackgroundOption({
    required this.id,
    required this.title,
    required this.subtitle,
    this.assetPath,
    this.previewAssetPath,
    this.icon = Icons.photo_filter_rounded,
  });
}

class _PultHeaderAvatarOption {
  final String id;
  final String title;
  final String assetPath;

  const _PultHeaderAvatarOption({
    required this.id,
    required this.title,
    required this.assetPath,
  });
}

class _PultHeaderFrameOption {
  final String id;
  final String title;
  final String assetPath;
  final bool isVideo;

  const _PultHeaderFrameOption({
    required this.id,
    required this.title,
    required this.assetPath,
    this.isVideo = false,
  });
}

class _BackgroundOptionPreview extends StatefulWidget {
  const _BackgroundOptionPreview({required this.option});

  final _PultHeaderBackgroundOption option;

  @override
  State<_BackgroundOptionPreview> createState() =>
      _BackgroundOptionPreviewState();
}

class _BackgroundOptionPreviewState extends State<_BackgroundOptionPreview> {
  static final Map<String, Uint8List> _thumbCache = <String, Uint8List>{};
  static final Map<String, Future<Uint8List?>> _thumbFutures =
      <String, Future<Uint8List?>>{};
  Uint8List? _videoThumb;

  String? get _previewPath =>
      widget.option.previewAssetPath ?? widget.option.assetPath;

  bool get _isVideoPreview =>
      _previewPath != null && _previewPath!.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();
    if (_isVideoPreview) {
      unawaited(_loadVideoThumbnail());
    }
  }

  @override
  void didUpdateWidget(covariant _BackgroundOptionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPreviewPath =
        oldWidget.option.previewAssetPath ?? oldWidget.option.assetPath;
    if (oldPreviewPath != _previewPath) {
      _videoThumb = null;
      if (_isVideoPreview) {
        unawaited(_loadVideoThumbnail());
      }
    }
  }

  Future<void> _loadVideoThumbnail() async {
    final path = _previewPath;
    if (path == null || !_isVideoPreview) return;
    final cached = _thumbCache[path];
    if (cached != null) {
      if (!mounted || _previewPath != path) return;
      setState(() {
        _videoThumb = cached;
      });
      return;
    }

    final future = _thumbFutures[path] ??= _buildThumbFromAsset(path);
    final bytes = await future;
    if (!mounted || _previewPath != path) return;
    setState(() {
      _videoThumb = bytes;
    });
  }

  static Future<Uint8List?> _buildThumbFromAsset(String assetPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final hash = base64UrlEncode(utf8.encode(assetPath));
      final sourceFile = File('${tempDir.path}/pult_thumb_$hash.mp4');
      if (!await sourceFile.exists()) {
        final bytes = await rootBundle.load(assetPath);
        await sourceFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      }
      final data = await VideoThumbnail.thumbnailData(
        video: sourceFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 240,
        quality: 55,
        timeMs: 0,
      );
      if (data != null) {
        _thumbCache[assetPath] = data;
      }
      return data;
    } catch (_) {
      return null;
    } finally {
      _thumbFutures.remove(assetPath);
    }
  }

  @override
  void dispose() => super.dispose();

  @override
  Widget build(BuildContext context) {
    final path = _previewPath;
    if (path == null) {
      return Icon(widget.option.icon);
    }
    if (_isVideoPreview) {
      final bytes = _videoThumb;
      if (bytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
        );
      }
      return const SizedBox(
        width: 44,
        height: 44,
        child: Icon(Icons.movie_creation_rounded),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        path,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(widget.option.icon);
        },
      ),
    );
  }
}

class PultScreen extends StatefulWidget {
  const PultScreen({super.key});

  @override
  State<PultScreen> createState() => _PultScreenState();
}

class _PultScreenState extends State<PultScreen> {
  late final AppDb db;
  late final PageController _pageController;
  bool _dbInited = false;
  List<PultTabEntry> _tabs = const <PultTabEntry>[];
  String? _activeClientId;
  final Map<String, GlobalKey> _tabKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    PultStore.revision.addListener(_reloadTabs);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dbInited) return;
    db = AppDbScope.of(context);
    _dbInited = true;
    _reloadTabs();
  }

  @override
  void dispose() {
    PultStore.revision.removeListener(_reloadTabs);
    _pageController.dispose();
    super.dispose();
  }

  int _activeTabIndexFor(List<PultTabEntry> tabs) {
    if (tabs.isEmpty) return 0;
    final index = tabs.indexWhere((item) => item.clientId == _activeClientId);
    return index >= 0 ? index : tabs.length - 1;
  }

  GlobalKey _tabKeyFor(String clientId) =>
      _tabKeys.putIfAbsent(clientId, GlobalKey.new);

  void _scrollActiveTabIntoView({bool animated = true}) {
    final activeClientId = _activeClientId;
    if (activeClientId == null) return;
    final context = _tabKeys[activeClientId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: animated ? const Duration(milliseconds: 220) : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _reloadTabs() async {
    final tabs = await PultStore.loadTabs();
    if (!mounted) return;
    setState(() {
      _tabs = tabs;
      _tabKeys.removeWhere((clientId, _) {
        return !_tabs.any((tab) => tab.clientId == clientId);
      });
      if (_tabs.isEmpty) {
        _activeClientId = null;
        return;
      }
      final hasActive =
          _activeClientId != null &&
          _tabs.any((item) => item.clientId == _activeClientId);
      _activeClientId = hasActive ? _activeClientId : _tabs.last.clientId;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || _tabs.isEmpty) return;
      final targetPage = _activeTabIndexFor(_tabs);
      if (_pageController.page?.round() == targetPage) return;
      _pageController.jumpToPage(targetPage);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabs.isEmpty) return;
      _scrollActiveTabIntoView(animated: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final activeTabIndex = _activeTabIndexFor(_tabs);
    final activeTab = _tabs.isEmpty ? null : _tabs[activeTabIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Пульт')),
      body: SafeArea(
        child: _tabs.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.dashboard_customize_rounded,
                        size: 46,
                        color: colors.primary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Пульт пока пуст',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Добавляй клиентов из календаря кнопкой «В Пульт», и они появятся здесь отдельными вкладками.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  Container(
                    height: 56,
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: 0.68,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final tab = _tabs[index];
                        final selected = index == activeTabIndex;
                        return KeyedSubtree(
                          key: _tabKeyFor(tab.clientId),
                          child: _PultClientTab(
                            title: tab.clientName,
                            selected: selected,
                            onTap: () {
                              if (index == activeTabIndex) return;
                              setState(() {
                                _activeClientId = tab.clientId;
                              });
                              if (_pageController.hasClients) {
                                _pageController.jumpToPage(index);
                              }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                _scrollActiveTabIntoView();
                              });
                            },
                            onClose: () => PultStore.removeTab(tab.clientId),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: activeTab == null
                        ? const SizedBox.shrink()
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: _tabs.length,
                            onPageChanged: (index) {
                              final nextClientId = _tabs[index].clientId;
                              if (nextClientId == _activeClientId) return;
                              setState(() {
                                _activeClientId = nextClientId;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                _scrollActiveTabIntoView();
                              });
                            },
                            itemBuilder: (context, index) {
                              final tab = _tabs[index];
                              return _PultWorkoutPage(
                                key: ValueKey(
                                  '${tab.clientId}_${tab.day.toIso8601String()}_${tab.absoluteIndex}_${tab.templateIdx}',
                                ),
                                db: db,
                                tab: tab,
                                onCompleted: () =>
                                    PultStore.removeTab(tab.clientId),
                                isActive: index == activeTabIndex,
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

class _PultWorkoutPage extends StatefulWidget {
  const _PultWorkoutPage({
    super.key,
    required this.db,
    required this.tab,
    required this.onCompleted,
    required this.isActive,
  });

  final AppDb db;
  final PultTabEntry tab;
  final Future<void> Function() onCompleted;
  final bool isActive;

  @override
  State<_PultWorkoutPage> createState() => _PultWorkoutPageState();
}

class _PultWorkoutPageState extends State<_PultWorkoutPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const String _attendanceMarker = '[attended]';
  static const String headerVideoAsset = 'assets/branding/pult_header.mp4';
  static const double _headerAvatarSize = 78;
  static const String _videoBackgroundId = 'video_fire';
  static const String _headerAssetsRoot = 'assets/pult_customization';
  static const List<_PultHeaderAvatarOption> _avatarOptions =
      <_PultHeaderAvatarOption>[
        _PultHeaderAvatarOption(
          id: 'default_avatar',
          title: 'Базовый аватар',
          assetPath: '$_headerAssetsRoot/avatars/avatar_default.png',
        ),
      ];
  static const List<_PultHeaderFrameOption> _frameOptions =
      <_PultHeaderFrameOption>[
        _PultHeaderFrameOption(
          id: 'default_frame',
          title: 'Базовая рамка',
          assetPath: '$_headerAssetsRoot/frames/frame_default.mp4',
          isVideo: true,
        ),
      ];
  static const List<_PultHeaderBackgroundOption> _defaultBackgroundOptions =
      <_PultHeaderBackgroundOption>[
        _PultHeaderBackgroundOption(
          id: _videoBackgroundId,
          title: 'Огненный',
          subtitle: 'Текущий анимированный фон',
          icon: Icons.local_fire_department_rounded,
        ),
        _PultHeaderBackgroundOption(
          id: 'default_media',
          title: 'Кастомный фон',
          subtitle: 'Из папки assets/pult_customization/backgrounds',
          assetPath: '$_headerAssetsRoot/backgrounds/background_default.mp4',
          icon: Icons.image_rounded,
        ),
      ];

  final Map<int, TextEditingController> _kgControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _nameControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _repsControllers =
      <int, TextEditingController>{};
  final Map<int, FocusNode> _kgFocusNodes = <int, FocusNode>{};
  final Map<int, FocusNode> _repsFocusNodes = <int, FocusNode>{};
  final Map<int, FocusNode> _nameFocusNodes = <int, FocusNode>{};
  final Map<int, Timer> _nameSaveDebounces = <int, Timer>{};
  final Set<int> _nameSaveInFlight = <int>{};
  final Map<int, String> _persistedExerciseNames = <int, String>{};
  final Map<int, GlobalKey> _exerciseKeys = <int, GlobalKey>{};
  final ScrollController _pageScrollController = ScrollController();

  _PultTabData? _data;
  Object? _error;
  bool _loading = true;
  bool _completing = false;
  Timer? _draftDebounce;

  late final AnimationController _headerGlowController;
  VideoPlayerController? _headerVideoController;
  VideoPlayerController? _backgroundAssetVideoController;
  VideoPlayerController? _frameAssetVideoController;
  String? _backgroundAssetVideoPath;
  String? _frameAssetVideoPath;
  bool _headerVideoFailed = false;
  bool _headerVisualReady = false;
  bool _isCustomizationSheetOpen = false;
  Timer? _videoDiagnosticsTimer;
  Duration? _lastFramePosition;
  Duration? _lastBackgroundPosition;
  List<_PultHeaderBackgroundOption> _backgroundOptions =
      _defaultBackgroundOptions;
  PultHeaderCustomization _headerCustomization =
      const PultHeaderCustomization();

  @override
  void initState() {
    super.initState();
    _headerGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    unawaited(_prepareHeaderVideo());
    unawaited(_loadHeaderCustomization());
    if (widget.isActive) {
      _startVideoDiagnostics();
    }
    unawaited(_loadBackgroundOptions());
    _load();
  }

  @override
  void didUpdateWidget(covariant _PultWorkoutPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      _startVideoDiagnostics();
      unawaited(_syncSelectedVideoAssets());
      unawaited(_nudgeActivePlayback());
    } else {
      _videoDiagnosticsTimer?.cancel();
      unawaited(_syncHeaderVideoPlayback());
    }
  }

  Future<void> _prepareHeaderVideo() async {
    await _PultHeaderVideoWarmup.ensureWarmedUp();
    if (!mounted) return;
    await _initHeaderVideo();
  }

  Future<void> _loadHeaderCustomization() async {
    final custom = await PultStore.loadHeaderCustomization(widget.tab.clientId);
    if (!mounted) return;
    setState(() {
      _headerCustomization = custom;
    });
    await _syncSelectedVideoAssets();
  }

  Future<void> _loadBackgroundOptions() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allPaths = manifest
          .listAssets()
          .where((path) => path.startsWith('$_headerAssetsRoot/backgrounds/'))
          .toList();

      String? defaultPath;
      for (final path in allPaths) {
        if (RegExp(r'background_default(\.[^/]+)?$').hasMatch(path)) {
          defaultPath = path;
          break;
        }
      }

      bool isSupportedBackgroundAsset(String path) {
        final lower = path.toLowerCase();
        return lower.endsWith('.mp4') ||
            lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp');
      }

      String fileName(String path) => path.split('/').last;

      int extractNumber(String path) {
        final match = RegExp(r'background_(\d+)').firstMatch(path);
        return int.tryParse(match?.group(1) ?? '') ?? -1;
      }

      String baseName(String path) {
        final file = fileName(path);
        final dot = file.lastIndexOf('.');
        return dot > 0 ? file.substring(0, dot) : file;
      }

      String sanitizeIdPart(String raw) {
        return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
      }

      bool isVideoAsset(String path) => path.toLowerCase().endsWith('.mp4');

      final paths =
          allPaths
              .where(
                (path) =>
                    path.startsWith('$_headerAssetsRoot/backgrounds/') &&
                    !RegExp(r'background_default(\.[^/]+)?$').hasMatch(path) &&
                    isSupportedBackgroundAsset(path),
              )
              .toList()
            ..sort((a, b) {
              final aNum = extractNumber(a);
              final bNum = extractNumber(b);
              if (aNum >= 0 && bNum >= 0) {
                if (aNum != bNum) return aNum.compareTo(bNum);
                return a.compareTo(b);
              }

              if (aNum >= 0) return -1;
              if (bNum >= 0) return 1;
              return a.compareTo(b);
            });

      final groupedByBase = <String, List<String>>{};
      for (final path in paths) {
        final key = baseName(path);
        groupedByBase.putIfAbsent(key, () => <String>[]).add(path);
      }

      final groupedKeys = groupedByBase.keys.toList()
        ..sort((a, b) {
          final aNum = extractNumber(a);
          final bNum = extractNumber(b);
          if (aNum >= 0 && bNum >= 0) {
            if (aNum != bNum) return aNum.compareTo(bNum);
            return a.compareTo(b);
          }
          if (aNum >= 0) return -1;
          if (bNum >= 0) return 1;
          return a.compareTo(b);
        });

      final generated = <_PultHeaderBackgroundOption>[
        _defaultBackgroundOptions.first,
      ];
      if (defaultPath != null) {
        generated.add(
          _PultHeaderBackgroundOption(
            id: 'default_media',
            title: 'Кастомный фон',
            subtitle: 'Из папки assets/pult_customization/backgrounds',
            previewAssetPath: defaultPath,
            assetPath: defaultPath,
            icon: Icons.image_rounded,
          ),
        );
      }
      final seenIds = <String>{
        _defaultBackgroundOptions.first.id,
        'default_media',
      };
      for (final groupKey in groupedKeys) {
        final groupPaths = groupedByBase[groupKey]!;
        String? primaryPath;
        String? previewPath;

        for (final item in groupPaths) {
          if (!isVideoAsset(item)) {
            previewPath = item;
            break;
          }
        }
        for (final item in groupPaths) {
          if (isVideoAsset(item)) {
            primaryPath = item;
            break;
          }
        }
        primaryPath ??= previewPath;
        previewPath ??= primaryPath;
        if (primaryPath == null) continue;

        final match = RegExp(r'background_(\d+)').firstMatch(groupKey);
        final idx = match?.group(1);
        final fallbackName = groupKey.replaceFirst('background_', '');
        final rawIdPart = sanitizeIdPart(idx ?? fallbackName);
        final id = 'background_$rawIdPart';
        if (seenIds.contains(id)) continue;
        seenIds.add(id);
        generated.add(
          _PultHeaderBackgroundOption(
            id: id,
            title: idx != null ? 'Фон $idx' : 'Фон $fallbackName',
            subtitle: idx != null
                ? 'Кастомный фон #$idx'
                : 'Кастомный фон: ${fileName(primaryPath)}',
            assetPath: primaryPath,
            previewAssetPath: previewPath,
            icon: Icons.image_rounded,
          ),
        );
      }

      if (generated.length == 1) {
        generated.addAll(_defaultBackgroundOptions.skip(1));
      }

      if (!mounted) return;
      setState(() {
        _backgroundOptions = generated;
      });
      if (_backgroundOptions.any(
        (item) => item.id == _headerCustomization.backgroundId,
      )) {
        return;
      }
      if (_headerCustomization.backgroundId == 'default_media') {
        String? firstCustomId;
        for (final item in _backgroundOptions) {
          if (item.id == _videoBackgroundId) continue;
          firstCustomId = item.id;
          break;
        }
        if (firstCustomId != null) {
          await _saveHeaderCustomization(
            _headerCustomization.copyWith(backgroundId: firstCustomId),
          );
        }
      }
    } catch (_) {
      // Fallback to default options if manifest parsing fails.
    }
  }

  Future<void> _saveHeaderCustomization(PultHeaderCustomization next) async {
    setState(() {
      _headerCustomization = next;
    });
    await _syncSelectedVideoAssets();
    await PultStore.saveHeaderCustomization(widget.tab.clientId, next);
  }

  Future<void> _initHeaderVideo() async {
    final controller = VideoPlayerController.asset(
      headerVideoAsset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _headerVideoController = controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await _syncHeaderVideoPlayback(restart: widget.isActive);
      unawaited(_nudgeActivePlayback());
      if (!mounted) return;
      setState(() {
        _headerVisualReady = true;
      });
    } catch (_) {
      await controller.dispose();
      _headerVideoController = null;
      if (!mounted) return;
      setState(() {
        _headerVisualReady = true;
        _headerVideoFailed = true;
      });
    }
  }

  Future<void> _ensureActiveControllersPlaying() async {
    if (!widget.isActive) return;
    final controllers = _visibleVideoControllers();

    await Future.wait(
      controllers.map((controller) async {
        if (!controller.value.isPlaying) {
          await controller.play();
        }
      }),
    );
  }

  Future<void> _nudgeActivePlayback() async {
    if (!widget.isActive) return;
    for (final delay in const [
      Duration(milliseconds: 120),
      Duration(milliseconds: 420),
    ]) {
      await Future.delayed(delay);
      if (!mounted || !widget.isActive) return;
      await _ensureActiveControllersPlaying();
    }
  }

  Future<void> _syncHeaderVideoPlayback({bool restart = false}) async {
    final allControllers = <VideoPlayerController>[
      if (_headerVideoController?.value.isInitialized == true)
        _headerVideoController!,
      if (_backgroundAssetVideoController?.value.isInitialized == true)
        _backgroundAssetVideoController!,
      if (_frameAssetVideoController?.value.isInitialized == true)
        _frameAssetVideoController!,
    ];
    final visibleControllers = _visibleVideoControllers();
    final hiddenControllers = allControllers
        .where((controller) => !visibleControllers.contains(controller))
        .toList();

    if (widget.isActive) {
      await Future.wait(
        visibleControllers.map((controller) async {
          if (restart) {
            await controller.seekTo(Duration.zero);
          }
          if (!controller.value.isPlaying) {
            await controller.play();
          }
        }),
      );
      await Future.wait(
        hiddenControllers.map(
          (controller) =>
              _pauseAndRewindOptionalController(controller, rewind: false),
        ),
      );
      _logVideoState('sync_active');
      return;
    }

    await Future.wait(
      allControllers.map(
        (controller) =>
            _pauseAndRewindOptionalController(controller, rewind: false),
      ),
    );
    _logVideoState('sync_inactive');
  }

  List<VideoPlayerController> _visibleVideoControllers() {
    final controllers = <VideoPlayerController>[];

    final selectedBackground = _selectedBackground;
    final selectedBackgroundPath = selectedBackground?.assetPath;
    final useCustomBackgroundVideo =
        selectedBackgroundPath != null &&
        _isVideoAssetPath(selectedBackgroundPath) &&
        _backgroundAssetVideoController?.value.isInitialized == true;

    if (useCustomBackgroundVideo) {
      controllers.add(_backgroundAssetVideoController!);
    } else if (_useVideoBackground &&
        _headerVideoController?.value.isInitialized == true) {
      controllers.add(_headerVideoController!);
    }

    if (_frameAssetVideoController?.value.isInitialized == true) {
      controllers.add(_frameAssetVideoController!);
    }

    return controllers;
  }

  Future<void> _pauseAndRewindOptionalController(
    VideoPlayerController? controller, {
    bool rewind = true,
  }) async {
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    }
    if (rewind) {
      await controller.seekTo(Duration.zero);
    }
  }

  bool _isVideoAssetPath(String assetPath) {
    return assetPath.toLowerCase().endsWith('.mp4');
  }

  void _startVideoDiagnostics() {
    if (!kDebugMode) return;
    if (!widget.isActive) return;
    _videoDiagnosticsTimer?.cancel();
    _videoDiagnosticsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_runVideoDiagnostics());
    });
  }

  Future<void> _runVideoDiagnostics() async {
    if (!mounted || !widget.isActive) return;
    if (!_isCustomVideoBackgroundActive()) return;

    final frame = _frameAssetVideoController;
    final bg = _backgroundAssetVideoController;
    if (frame == null ||
        bg == null ||
        !frame.value.isInitialized ||
        !bg.value.isInitialized) {
      return;
    }

    final framePos = frame.value.position;
    final bgPos = bg.value.position;

    final suspicious = frame.value.isPlaying != bg.value.isPlaying;
    if (suspicious) {
      _logVideoState('diagnostic_suspect');
      // Important: do not aggressively resume a paused stream here.
      // On some Android devices this creates ping-pong behavior where
      // frame/background steal playback from each other.
      return;
    }

    _lastFramePosition = framePos;
    _lastBackgroundPosition = bgPos;
  }

  bool _isCustomVideoBackgroundActive() {
    final path = _selectedBackground?.assetPath;
    return path != null &&
        _isVideoAssetPath(path) &&
        _backgroundAssetVideoController?.value.isInitialized == true;
  }

  void _logVideoState(String tag) {
    if (!kDebugMode) return;
    final header = _headerVideoController?.value;
    final bg = _backgroundAssetVideoController?.value;
    final frame = _frameAssetVideoController?.value;
    debugPrint(
      '[PULT_VIDEO][$tag] '
      'visible=${_visibleVideoControllers().length} '
      'header={init:${header?.isInitialized ?? false},play:${header?.isPlaying ?? false},pos:${header?.position.inMilliseconds ?? -1}} '
      'bg={init:${bg?.isInitialized ?? false},play:${bg?.isPlaying ?? false},pos:${bg?.position.inMilliseconds ?? -1}} '
      'frame={init:${frame?.isInitialized ?? false},play:${frame?.isPlaying ?? false},pos:${frame?.position.inMilliseconds ?? -1}} '
      'customBg=${_selectedBackground?.assetPath ?? 'none'}',
    );
  }

  Future<void> _syncSelectedVideoAssets() async {
    final backgroundPath = _selectedBackground?.assetPath;
    final backgroundChanged = backgroundPath != _backgroundAssetVideoPath;
    if (backgroundChanged) {
      await _backgroundAssetVideoController?.dispose();
      _backgroundAssetVideoController = null;
      _backgroundAssetVideoPath = null;
      if (backgroundPath != null && _isVideoAssetPath(backgroundPath)) {
        await _PultAssetVideoWarmup.warmUp(backgroundPath);
        final controller = VideoPlayerController.asset(
          backgroundPath,
          viewType: VideoViewType.textureView,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        try {
          await controller.initialize();
          await controller.setLooping(true);
          await controller.setVolume(0);
          _backgroundAssetVideoController = controller;
          _backgroundAssetVideoPath = backgroundPath;
        } catch (_) {
          await controller.dispose();
        }
      }
    }
    final frame = _selectedFrame;
    final framePath = frame?.assetPath;
    final shouldReloadFrame = framePath != _frameAssetVideoPath;
    if (shouldReloadFrame) {
      await _frameAssetVideoController?.dispose();
      _frameAssetVideoController = null;
      _frameAssetVideoPath = null;
      if (framePath != null &&
          frame?.isVideo == true &&
          _isVideoAssetPath(framePath)) {
        await _PultAssetVideoWarmup.warmUp(framePath);
        final controller = VideoPlayerController.asset(
          framePath,
          // On some Android GPUs, two texture views can freeze one stream.
          // Render frame via platform view to avoid texture contention.
          viewType: VideoViewType.platformView,
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        try {
          await controller.initialize();
          await controller.setLooping(true);
          await controller.setVolume(0);
          _frameAssetVideoController = controller;
          _frameAssetVideoPath = framePath;
        } catch (_) {
          await controller.dispose();
        }
      }
    }

    final assetsReloaded = backgroundChanged || shouldReloadFrame;
    if (!assetsReloaded) {
      await _syncHeaderVideoPlayback();
      return;
    }

    if (!mounted) return;
    _lastFramePosition = null;
    _lastBackgroundPosition = null;
    setState(() {});
    _logVideoState('assets_synced');
    await _syncHeaderVideoPlayback(restart: widget.isActive);
    unawaited(_nudgeActivePlayback());
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    _videoDiagnosticsTimer?.cancel();

    unawaited(_saveDrafts());
    for (final controller in [
      ..._kgControllers.values,
      ..._repsControllers.values,
    ]) {
      controller.dispose();
    }
    for (final node in [..._kgFocusNodes.values, ..._repsFocusNodes.values]) {
      node.dispose();
    }
    _headerVideoController?.dispose();
    _backgroundAssetVideoController?.dispose();
    _frameAssetVideoController?.dispose();
    _headerGlowController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final details = await widget.db.getWorkoutDetailsForClientProgramSlot(
        clientId: widget.tab.clientId,
        absoluteIndex: widget.tab.absoluteIndex,
        templateIdx: widget.tab.templateIdx,
      );
      final drafts = await widget.db.getWorkoutDraftResults(
        clientId: widget.tab.clientId,
        day: widget.tab.day,
        templateIdx: widget.tab.templateIdx,
        absoluteIndex: widget.tab.absoluteIndex,
      );

      final exercises = details.$3.map((e) {
        final draft = drafts[e.templateExerciseId];
        if (draft == null) return e;
        return WorkoutExerciseVm(
          templateExerciseId: e.templateExerciseId,
          templateId: e.templateId,
          orderIndex: e.orderIndex,
          name: e.name,
          lastWeightKg: draft.$1,
          lastReps: draft.$2,
          supersetGroup: e.supersetGroup,
        );
      }).toList();

      _disposeInputs();
      for (final e in exercises) {
        _exerciseKeys[e.templateExerciseId] = GlobalKey();
        _kgControllers[e.templateExerciseId] = TextEditingController(
          text: e.lastWeightKg == null ? '' : _fmtWeight(e.lastWeightKg!),
        )..addListener(_handleInputChanged);
        _repsControllers[e.templateExerciseId] = TextEditingController(
          text: e.lastReps?.toString() ?? '',
        )..addListener(_handleInputChanged);
        _nameControllers[e.templateExerciseId] =
            TextEditingController(text: e.name)..addListener(() {
              _scheduleExerciseNameSave(e.templateExerciseId);
            });
        _persistedExerciseNames[e.templateExerciseId] = e.name;

        _kgFocusNodes[e.templateExerciseId] = FocusNode()
          ..addListener(() {
            final node = _kgFocusNodes[e.templateExerciseId];
            final controller = _kgControllers[e.templateExerciseId];
            if (node?.hasFocus == true && controller != null) {
              _scheduleSelectAll(controller);
              _scheduleBringIntoView(e.templateExerciseId);
            }
          });
        _repsFocusNodes[e.templateExerciseId] = FocusNode()
          ..addListener(() {
            final node = _repsFocusNodes[e.templateExerciseId];
            final controller = _repsControllers[e.templateExerciseId];
            if (node?.hasFocus == true && controller != null) {
              _scheduleSelectAll(controller);
              _scheduleBringIntoView(e.templateExerciseId);
            }
          });
        _nameFocusNodes[e.templateExerciseId] = FocusNode()
          ..addListener(() {
            final node = _nameFocusNodes[e.templateExerciseId];
            final controller = _nameControllers[e.templateExerciseId];
            if (node?.hasFocus == true && controller != null) {
              _scheduleSelectAll(controller);
              _scheduleBringIntoView(e.templateExerciseId);
            } else {
              _scheduleExerciseNameSave(e.templateExerciseId, immediate: true);
            }
          });
      }

      if (!mounted) return;
      setState(() {
        _data = _PultTabData(
          clientName: widget.tab.clientName,
          exercises: exercises,
          day: widget.tab.day,
        );
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _disposeInputs() {
    for (final controller in [
      ..._kgControllers.values,
      ..._repsControllers.values,
      ..._nameControllers.values,
    ]) {
      controller.dispose();
    }
    for (final node in [
      ..._kgFocusNodes.values,
      ..._repsFocusNodes.values,
      ..._nameFocusNodes.values,
    ]) {
      node.dispose();
    }

    for (final timer in _nameSaveDebounces.values) {
      timer.cancel();
    }
    _kgControllers.clear();
    _repsControllers.clear();
    _kgFocusNodes.clear();
    _repsFocusNodes.clear();
    _nameFocusNodes.clear();
    _nameSaveDebounces.clear();
    _nameSaveInFlight.clear();
    _persistedExerciseNames.clear();
    _exerciseKeys.clear();
  }

  void _handleInputChanged() {
    if (!mounted) return;
    setState(() {});
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 260), () {
      unawaited(_saveDrafts());
    });
  }

  void _scheduleBringIntoView(int exerciseId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _exerciseKeys[exerciseId]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.08,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _saveDrafts() async {
    final data = _data;
    if (data == null) return;

    await widget.db.saveWorkoutDraftResults(
      clientId: widget.tab.clientId,
      day: widget.tab.day,
      templateIdx: widget.tab.templateIdx,
      absoluteIndex: widget.tab.absoluteIndex,
      resultsByTemplateExerciseId: {
        for (final e in data.exercises)
          e.templateExerciseId: (
            _parseWeight(_kgControllers[e.templateExerciseId]?.text ?? ''),
            _parseReps(_repsControllers[e.templateExerciseId]?.text ?? ''),
          ),
      },
    );
  }

  Future<String?> _showExerciseNameDialog({
    required String title,
    required String actionLabel,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final focusNode = FocusNode();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!focusNode.hasFocus) {
            focusNode.requestFocus();
          }
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        });

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: const InputDecoration(
              labelText: 'Название упражнения',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );

    focusNode.dispose();
    controller.dispose();
    return result;
  }

  Future<void> _addExercise({WorkoutExerciseVm? afterExercise}) async {
    final data = _data;
    if (data == null) return;

    await _saveDrafts();

    final name = await _showExerciseNameDialog(
      title: 'Новое упражнение',
      actionLabel: 'Добавить',
    );
    if (name == null || name.trim().isEmpty) return;

    int? templateId;
    if (data.exercises.isNotEmpty) {
      templateId = data.exercises.first.templateId;
    } else {
      templateId = await widget.db.getTemplateIdForClientTemplateIdx(
        clientId: widget.tab.clientId,
        templateIdx: widget.tab.templateIdx,
      );
    }
    if (templateId == null) return;

    await widget.db.addWorkoutExerciseForClient(
      clientId: widget.tab.clientId,
      templateId: templateId,
      name: name,
      insertAfterOrderIndex: afterExercise?.orderIndex,
    );

    if (!mounted) return;
    await _load();
  }

  Future<void> _deleteExercise(
    WorkoutExerciseVm exercise, {
    bool askConfirmation = true,
  }) async {
    if (askConfirmation) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить упражнение?'),
          content: Text(
            'Упражнение "${exercise.name}" будет удалено из этого дня программы.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    await _saveDrafts();

    await widget.db.deleteWorkoutExerciseForClient(
      clientId: widget.tab.clientId,
      templateExerciseId: exercise.templateExerciseId,
    );

    if (!mounted) return;
    await _load();
  }

  Future<void> _showExerciseActionsSheet(WorkoutExerciseVm exercise) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_circle_outline_rounded),
                title: const Text('Добавить упражнение ниже'),
                onTap: () => Navigator.of(context).pop('add'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Удалить это упражнение'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    if (result == 'add') {
      await _addExercise(afterExercise: exercise);
      return;
    }
    if (result == 'delete') {
      await _deleteExercise(exercise);
    }
  }

  Future<void> _completeDay() async {
    if (_completing || _data == null) return;

    setState(() => _completing = true);
    _draftDebounce?.cancel();

    try {
      final results = <int, (double? kg, int? reps)>{};
      for (final e in _data!.exercises) {
        results[e.templateExerciseId] = (
          _parseWeight(_kgControllers[e.templateExerciseId]?.text ?? ''),
          _parseReps(_repsControllers[e.templateExerciseId]?.text ?? ''),
        );
      }

      await widget.db.saveWorkoutResultsAndMarkDone(
        clientId: widget.tab.clientId,
        day: widget.tab.day,
        templateIdx: widget.tab.templateIdx,
        absoluteIndex: widget.tab.absoluteIndex,
        resultsByTemplateExerciseId: results,
      );

      final appointments = await widget.db.getAppointmentsForClientOnDay(
        clientId: widget.tab.clientId,
        day: widget.tab.day,
      );
      for (final appointment in appointments) {
        await widget.db.updateAppointmentNote(
          id: appointment.id,
          note: _withAttendanceMarker(appointment.note, true),
        );
      }

      await widget.onCompleted();
    } finally {
      if (mounted) {
        setState(() => _completing = false);
      }
    }
  }

  void _scheduleExerciseNameSave(
    int templateExerciseId, {
    bool immediate = false,
  }) {
    _nameSaveDebounces[templateExerciseId]?.cancel();
    if (immediate) {
      unawaited(_saveExerciseName(templateExerciseId));
      return;
    }
    _nameSaveDebounces[templateExerciseId] = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(_saveExerciseName(templateExerciseId)),
    );
  }

  Future<void> _saveExerciseName(int templateExerciseId) async {
    if (_nameSaveInFlight.contains(templateExerciseId)) return;
    final controller = _nameControllers[templateExerciseId];
    if (controller == null) return;

    final nextName = controller.text.trim();
    if (nextName.isEmpty) return;

    final persisted = _persistedExerciseNames[templateExerciseId];
    if (persisted == nextName) return;

    _nameSaveInFlight.add(templateExerciseId);
    try {
      await widget.db.renameWorkoutExerciseForClient(
        clientId: widget.tab.clientId,
        templateExerciseId: templateExerciseId,
        newName: nextName,
      );
      _persistedExerciseNames[templateExerciseId] = nextName;
    } finally {
      _nameSaveInFlight.remove(templateExerciseId);
      final current = controller.text.trim();
      if (current.isNotEmpty &&
          current != _persistedExerciseNames[templateExerciseId]) {
        _scheduleExerciseNameSave(templateExerciseId);
      }
    }
  }

  void _scheduleSelectAll(TextEditingController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  double? _parseWeight(String raw) {
    final s = raw.trim().replaceAll(',', '.');
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  int? _parseReps(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  String? _withAttendanceMarker(String? note, bool done) {
    final current = (note ?? '').replaceAll(_attendanceMarker, '').trim();
    if (!done) return current.isEmpty ? null : current;
    return current.isEmpty ? _attendanceMarker : '$current $_attendanceMarker';
  }

  String _fmtWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  InputDecoration _cellDecoration(
    BuildContext context,
    String label, {
    required bool highlighted,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      isDense: true,
      labelText: label,
      labelStyle: TextStyle(
        color: colors.onSurfaceVariant.withValues(alpha: 0.72),
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: colors.primary.withValues(alpha: 0.86),
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: highlighted
          ? colors.primaryContainer.withValues(alpha: 0.28)
          : colors.surface.withValues(alpha: 0.42),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: highlighted
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colors.primary.withValues(alpha: 0.38),
              ),
            )
          : OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: colors.primary.withValues(alpha: 0.72),
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildExerciseNameField({
    required BuildContext context,
    required WorkoutExerciseVm exercise,
    required ThemeData theme,
  }) {
    final controller = _nameControllers[exercise.templateExerciseId]!;
    final focusNode = _nameFocusNodes[exercise.templateExerciseId]!;
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      child: AnimatedBuilder(
        animation: Listenable.merge([controller, focusNode]),
        builder: (context, child) {
          final highlighted = controller.text.trim().isNotEmpty;
          final focused = focusNode.hasFocus;
          final fieldStyle = theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1,
            leadingDistribution: TextLeadingDistribution.even,
          );
          return LayoutBuilder(
            builder: (context, constraints) {
              final probeText = controller.text.trim().isEmpty
                  ? 'Название упражнения'
                  : controller.text;
              final probePainter = TextPainter(
                text: TextSpan(text: probeText, style: fieldStyle),
                maxLines: 1,
                textDirection: Directionality.of(context),
              )..layout(maxWidth: math.max(0, constraints.maxWidth - 24));
              final isSingleLine = !probePainter.didExceedMaxLines;
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: highlighted
                      ? colors.surfaceContainerHighest.withValues(alpha: 0.42)
                      : colors.surface.withValues(alpha: 0.38),
                  border: Border.all(
                    color: focused
                        ? colors.primary.withValues(alpha: 0.7)
                        : colors.outlineVariant.withValues(alpha: 0.26),
                    width: focused ? 1.4 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: 'Название упражнения',
                          hintStyle: TextStyle(
                            color: colors.onSurfaceVariant.withValues(
                              alpha: 0.58,
                            ),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => _scheduleSelectAll(controller),
                        minLines: 1,
                        maxLines: isSingleLine ? 1 : 2,
                        keyboardType: TextInputType.multiline,
                        textAlign: TextAlign.center,
                        style: fieldStyle,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool get _useVideoBackground =>
      _headerCustomization.backgroundId == _videoBackgroundId;

  _PultHeaderAvatarOption? get _selectedAvatar {
    final id = _headerCustomization.avatarId;
    if (id == null) return null;
    for (final item in _avatarOptions) {
      if (item.id == id) return item;
    }
    return null;
  }

  _PultHeaderFrameOption? get _selectedFrame {
    final id = _headerCustomization.avatarFrameId;
    if (id == null) return null;
    for (final item in _frameOptions) {
      if (item.id == id) return item;
    }
    return null;
  }

  _PultHeaderBackgroundOption? get _selectedBackground {
    if (_headerCustomization.backgroundId == 'default_media') {
      for (final item in _backgroundOptions) {
        if (item.id != _videoBackgroundId) return item;
      }
    }
    for (final item in _backgroundOptions) {
      if (item.id == _headerCustomization.backgroundId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _openHeaderCustomizationSheet() async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    setState(() {
      _isCustomizationSheetOpen = true;
    });
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: colors.surface,
        builder: (sheetContext) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.74,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildBackgroundTab(sheetContext),
              ),
            ),
          );
        },
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isCustomizationSheetOpen = false;
      });
    }
  }

  Widget _buildAvatarTab(BuildContext context) {
    if (_avatarOptions.isEmpty) {
      return const Center(child: Text('Аватары скоро появятся'));
    }
    return ListView.builder(
      itemCount: _avatarOptions.length,
      itemBuilder: (context, index) {
        final option = _avatarOptions[index];
        final selected = option.id == _headerCustomization.avatarId;
        return ListTile(
          leading: ClipOval(
            child: Image.asset(
              option.assetPath,
              width: 42,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const CircleAvatar(child: Icon(Icons.person_rounded));
              },
            ),
          ),
          title: Text(option.title),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: () => _saveHeaderCustomization(
            _headerCustomization.copyWith(avatarId: option.id),
          ),
        );
      },
    );
  }

  Widget _buildFrameTab(BuildContext context) {
    if (_frameOptions.isEmpty) {
      return const Center(child: Text('Рамки скоро появятся'));
    }
    return ListView.builder(
      itemCount: _frameOptions.length,
      itemBuilder: (context, index) {
        final option = _frameOptions[index];
        final selected = option.id == _headerCustomization.avatarFrameId;
        return ListTile(
          leading: SizedBox(
            width: 42,
            height: 42,
            child: option.isVideo
                ? const CircleAvatar(child: Icon(Icons.movie_creation_rounded))
                : Image.asset(
                    option.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const CircleAvatar(
                        child: Icon(Icons.crop_square_rounded),
                      );
                    },
                  ),
          ),
          title: Text(option.title),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: () => _saveHeaderCustomization(
            _headerCustomization.copyWith(avatarFrameId: option.id),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundTab(BuildContext context) {
    return ListView.builder(
      cacheExtent: 1200,
      itemCount: _backgroundOptions.length,
      itemBuilder: (context, index) {
        final option = _backgroundOptions[index];
        final selected = option.id == _headerCustomization.backgroundId;

        return ListTile(
          leading: _BackgroundOptionPreview(option: option),
          title: Text(option.title),
          subtitle: Text(option.subtitle),
          trailing: selected ? const Icon(Icons.check_circle) : null,
          onTap: () => _saveHeaderCustomization(
            _headerCustomization.copyWith(backgroundId: option.id),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAvatar(
    ColorScheme colors, {
    double size = 52,
    bool enableAnimatedFrame = true,
  }) {
    final avatar = _selectedAvatar;
    final frame = _selectedFrame;
    final avatarCore = avatar == null
        ? Container(
            width: size,
            height: size,
            color: colors.surface.withValues(alpha: 0.78),
            alignment: Alignment.center,
            child: Icon(Icons.fitness_center_rounded, color: colors.primary),
          )
        : Image.asset(
            avatar.assetPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: size,
                height: size,
                color: colors.surface.withValues(alpha: 0.78),
                alignment: Alignment.center,
                child: Icon(Icons.person_rounded, color: colors.primary),
              );
            },
          );

    if (frame == null) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(child: avatarCore),
      );
    }

    final avatarInset = size * 0.12;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!enableAnimatedFrame)
            _buildStaticFrameFallback(size)
          else
            _buildFrameLayer(frame, size),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(avatarInset),
              child: ClipOval(child: avatarCore),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrameLayer(_PultHeaderFrameOption frame, double size) {
    if (frame.isVideo) {
      final controller = _frameAssetVideoController;
      if (controller != null && controller.value.isInitialized) {
        return IgnorePointer(
          child: SizedBox(
            width: size,
            height: size,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(
                  controller,
                  key: ValueKey<String>(
                    'pult_header_frame_${_frameAssetVideoPath ?? 'none'}',
                  ),
                ),
              ),
            ),
          ),
        );
      }
      return SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.movie_creation_rounded, color: Colors.white70),
      );
    }
    return Image.asset(
      frame.assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStaticFrameFallback(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white70, width: 2),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeaderGradient(
    ColorScheme colors,
    double t,
    double wave,
    double wave2,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.lerp(
              colors.primary.withValues(alpha: 0.55),
              colors.tertiary.withValues(alpha: 0.62),
              t,
            )!,
            Color.lerp(
              colors.primaryContainer.withValues(alpha: 0.92),
              colors.tertiaryContainer.withValues(alpha: 0.94),
              t,
            )!,
            Color.lerp(
              colors.surfaceContainerHighest.withValues(alpha: 0.92),
              colors.primary.withValues(alpha: 0.50),
              t,
            )!,
          ],
          transform: GradientRotation((math.pi * 2) * t),
          stops: [0, 0.5 + (0.18 * wave), 1],
          begin: Alignment(-1.2 + (1.2 * t), -1.15 + (0.25 * wave)),
          end: Alignment(1.15 - (1.0 * t), 1.1 - (0.34 * wave2)),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Не удалось загрузить данные Пульта:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return const Center(child: Text('Нет данных'));
    }

    return ListView(
      controller: _pageScrollController,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 16),
      children: [
        AnimatedBuilder(
          animation: _headerGlowController,
          builder: (context, _) {
            final t = _headerGlowController.value;
            final wave = math.sin(t * math.pi * 2);
            final wave2 = math.sin((t * math.pi * 2) + (math.pi / 2));

            final video = _headerVideoController;
            final shouldRenderHeaderVideos = !_isCustomizationSheetOpen;
            final hasVideo =
                shouldRenderHeaderVideos &&
                _useVideoBackground &&
                video != null &&
                video.value.isInitialized;
            final backgroundAssetPath = _selectedBackground?.assetPath;
            final hasBackgroundAssetVideo =
                shouldRenderHeaderVideos &&
                backgroundAssetPath != null &&
                _isVideoAssetPath(backgroundAssetPath) &&
                _backgroundAssetVideoController != null &&
                _backgroundAssetVideoController!.value.isInitialized;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: colors.surfaceContainerHighest,
                border: Border.all(
                  color: Color.lerp(
                    colors.primary.withValues(alpha: 0.42),
                    colors.tertiary.withValues(alpha: 0.45),
                    t,
                  )!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(
                      colors.primary.withValues(alpha: 0.22),
                      colors.tertiary.withValues(alpha: 0.34),
                      t,
                    )!,
                    blurRadius: 24 + (t * 20),
                    spreadRadius: 1 + (2 * wave.abs()),
                    offset: Offset(0, 10 + (4 * wave.abs())),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: _openHeaderCustomizationSheet,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: hasVideo
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: video.value.size.width,
                                    height: video.value.size.height,
                                    child: VideoPlayer(
                                      video,
                                      key: const ValueKey<String>(
                                        'pult_header_builtin_video',
                                      ),
                                    ),
                                  ),
                                )
                              : backgroundAssetPath != null
                              ? hasBackgroundAssetVideo
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width:
                                              _backgroundAssetVideoController!
                                                  .value
                                                  .size
                                                  .width,
                                          height:
                                              _backgroundAssetVideoController!
                                                  .value
                                                  .size
                                                  .height,
                                          child: VideoPlayer(
                                            _backgroundAssetVideoController!,
                                            key: ValueKey<String>(
                                              'pult_header_bg_${_backgroundAssetVideoPath ?? 'none'}',
                                            ),
                                          ),
                                        ),
                                      )
                                    : _isVideoAssetPath(backgroundAssetPath)
                                    ? _buildAnimatedHeaderGradient(
                                        colors,
                                        t,
                                        wave,
                                        wave2,
                                      )
                                    : Image.asset(
                                        backgroundAssetPath,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return _buildAnimatedHeaderGradient(
                                                colors,
                                                t,
                                                wave,
                                                wave2,
                                              );
                                            },
                                      )
                              : !_headerVisualReady && widget.isActive
                              ? ColoredBox(
                                  color: colors.surfaceContainerHighest,
                                )
                              : _buildAnimatedHeaderGradient(
                                  colors,
                                  t,
                                  wave,
                                  wave2,
                                ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(
                                    alpha: hasVideo ? 0.16 : 0.05,
                                  ),
                                  Colors.black.withValues(
                                    alpha: hasVideo ? 0.08 : 0.0,
                                  ),
                                  Colors.black.withValues(
                                    alpha: hasVideo ? 0.28 : 0.08,
                                  ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_headerVideoFailed &&
                                        _useVideoBackground &&
                                        _selectedBackground?.assetPath == null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          'Видео-фон не найден, включён анимированный градиент',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: colors.onSurface
                                                    .withValues(alpha: 0.78),
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.surface.withValues(
                                            alpha: 0.54,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          DateFormat(
                                            'dd.MM.yyyy',
                                            'ru_RU',
                                          ).format(data.day),
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Colors.black.withValues(
                                              alpha: 0.42,
                                            ),
                                            Colors.black.withValues(
                                              alpha: 0.18,
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        data.clientName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.1,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                colors.surface.withValues(alpha: 0.985),
                colors.surfaceContainerHighest.withValues(alpha: 0.96),
                colors.primary.withValues(alpha: 0.08),
                colors.tertiary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.36),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.34),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Упражнение',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Вес',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Повт.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (data.exercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'На ${DateFormat('dd.MM.yyyy', 'ru_RU').format(data.day)} для этого клиента пока нет упражнений.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                for (var i = 0; i < data.exercises.length; i++)
                  Builder(
                    builder: (context) {
                      final exercise = data.exercises[i];
                      final kgController =
                          _kgControllers[exercise.templateExerciseId]!;
                      final repsController =
                          _repsControllers[exercise.templateExerciseId]!;
                      final hasKg = kgController.text.trim().isNotEmpty;
                      final hasReps = repsController.text.trim().isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                        child: GestureDetector(
                          key: ValueKey(
                            'exercise-${exercise.templateExerciseId}',
                          ),
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () =>
                              _showExerciseActionsSheet(exercise),
                          child: Container(
                            key: _exerciseKeys[exercise.templateExerciseId],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(
                                alpha: i.isEven ? 0.4 : 0.28,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.26,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colors.primaryContainer
                                              .withValues(alpha: 0.45),
                                          border: Border.all(
                                            color: colors.primary.withValues(
                                              alpha: 0.14,
                                            ),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${i + 1}',
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildExerciseNameField(
                                          context: context,
                                          exercise: exercise,
                                          theme: theme,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: kgController,
                                    focusNode:
                                        _kgFocusNodes[exercise
                                            .templateExerciseId],
                                    decoration: _cellDecoration(
                                      context,
                                      'Вес',
                                      highlighted: hasKg,
                                    ),
                                    onTap: () =>
                                        _scheduleSelectAll(kgController),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.1,
                                        ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: repsController,
                                    focusNode:
                                        _repsFocusNodes[exercise
                                            .templateExerciseId],
                                    decoration: _cellDecoration(
                                      context,
                                      'Пов',
                                      highlighted: hasReps,
                                    ),
                                    onTap: () =>
                                        _scheduleSelectAll(repsController),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.1,
                                        ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [colors.primaryContainer, colors.tertiaryContainer],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton.icon(
            onPressed: _completing ? null : _completeDay,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              backgroundColor: Colors.transparent,
              foregroundColor: colors.onPrimaryContainer,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: _completing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(
              _completing
                  ? 'Закрываем тренировочный день…'
                  : 'Закрыть тренировочный день',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PultClientTab extends StatelessWidget {
  const _PultClientTab({
    required this.title,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const animationDuration = Duration(milliseconds: 220);
    const tabRadius = 10.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(tabRadius),
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(end: selected ? 1 : 0),
          duration: animationDuration,
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) {
            final backgroundColor = Color.lerp(
              colors.surface.withValues(alpha: 0.58),
              colors.primaryContainer.withValues(alpha: 0.88),
              t,
            )!;
            final borderColor = Color.lerp(
              colors.outlineVariant.withValues(alpha: 0.22),
              colors.primary.withValues(alpha: 0.34),
              t,
            )!;
            final shadowColor = Color.lerp(
              colors.shadow.withValues(alpha: 0.02),
              colors.primary.withValues(alpha: 0.12),
              t,
            )!;
            final textColor = Color.lerp(
              colors.onSurface,
              colors.onPrimaryContainer,
              t,
            )!;
            final iconColor = Color.lerp(
              colors.onSurfaceVariant,
              colors.onPrimaryContainer,
              t,
            )!;
            return Container(
              padding: const EdgeInsets.only(left: 12, right: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(tabRadius),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 4 + (8 * t),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ) ??
                          TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                    iconSize: 16,
                    splashRadius: 16,
                    tooltip: 'Закрыть вкладку',
                    color: iconColor,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PultTabData {
  final String clientName;
  final DateTime day;
  final List<WorkoutExerciseVm> exercises;

  const _PultTabData({
    required this.clientName,
    required this.day,
    required this.exercises,
  });
}
