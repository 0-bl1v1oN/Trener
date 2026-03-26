import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PultTabEntry {
  final String clientId;
  final String clientName;
  final DateTime day;
  final int templateIdx;
  final int absoluteIndex;

  const PultTabEntry({
    required this.clientId,
    required this.clientName,
    required this.day,
    required this.templateIdx,
    required this.absoluteIndex,
  });

  Map<String, Object?> toJson() => {
    'clientId': clientId,
    'clientName': clientName,
    'day': DateTime(day.year, day.month, day.day).toIso8601String(),
    'templateIdx': templateIdx,
    'absoluteIndex': absoluteIndex,
  };

  factory PultTabEntry.fromJson(Map<String, dynamic> json) {
    final rawDay = DateTime.tryParse(json['day'] as String? ?? '');
    final day = rawDay == null
        ? DateTime.now()
        : DateTime(rawDay.year, rawDay.month, rawDay.day);
    return PultTabEntry(
      clientId: json['clientId'] as String? ?? '',
      clientName: json['clientName'] as String? ?? 'Клиент',
      day: day,
      templateIdx: (json['templateIdx'] as num?)?.toInt() ?? 0,
      absoluteIndex: (json['absoluteIndex'] as num?)?.toInt() ?? 0,
    );
  }
}

enum PultAddResult { added, updated, exists }

class PultHeaderCustomization {
  final String? avatarId;
  final String? avatarFrameId;
  final String backgroundId;

  const PultHeaderCustomization({
    this.avatarId,
    this.avatarFrameId,
    this.backgroundId = 'video_fire',
  });

  Map<String, Object?> toJson() => {
    'avatarId': avatarId,
    'avatarFrameId': avatarFrameId,
    'backgroundId': backgroundId,
  };

  factory PultHeaderCustomization.fromJson(Map<String, dynamic> json) {
    return PultHeaderCustomization(
      avatarId: json['avatarId'] as String?,
      avatarFrameId: json['avatarFrameId'] as String?,
      backgroundId: json['backgroundId'] as String? ?? 'video_fire',
    );
  }

  PultHeaderCustomization copyWith({
    String? avatarId,
    String? avatarFrameId,
    String? backgroundId,
  }) {
    return PultHeaderCustomization(
      avatarId: avatarId,
      avatarFrameId: avatarFrameId,
      backgroundId: backgroundId ?? this.backgroundId,
    );
  }
}

class PultStore {
  static const String _tabsKey = 'pult_tabs_v1';
  static const String _headerCustomizationKeyPrefix =
      'pult_header_customization_v1_';
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<List<PultTabEntry>> loadTabs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_tabsKey) ?? const <String>[];
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is! Map<String, dynamic>) return null;
            final tab = PultTabEntry.fromJson(decoded);
            return tab.clientId.isEmpty ? null : tab;
          } catch (_) {
            return null;
          }
        })
        .whereType<PultTabEntry>()
        .toList();
  }

  static Future<PultAddResult> addOrUpdateTab(PultTabEntry tab) async {
    final prefs = await SharedPreferences.getInstance();
    final tabs = await loadTabs();
    final index = tabs.indexWhere((item) => item.clientId == tab.clientId);
    late final PultAddResult result;

    if (index == -1) {
      tabs.add(tab);
      result = PultAddResult.added;
    } else {
      final current = tabs[index];
      final same =
          current.clientName == tab.clientName &&
          current.day.year == tab.day.year &&
          current.day.month == tab.day.month &&
          current.day.day == tab.day.day &&
          current.templateIdx == tab.templateIdx &&
          current.absoluteIndex == tab.absoluteIndex;
      if (same) {
        result = PultAddResult.exists;
      } else {
        tabs[index] = tab;
        result = PultAddResult.updated;
      }
    }

    await prefs.setStringList(
      _tabsKey,
      tabs.map((item) => jsonEncode(item.toJson())).toList(),
    );
    revision.value++;
    return result;
  }

  static Future<void> removeTab(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final tabs = await loadTabs();
    tabs.removeWhere((item) => item.clientId == clientId);
    await prefs.setStringList(
      _tabsKey,
      tabs.map((item) => jsonEncode(item.toJson())).toList(),
    );
    revision.value++;
  }
}

static Future<PultHeaderCustomization> loadHeaderCustomization(
    String clientId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_headerCustomizationKeyPrefix$clientId');
    if (raw == null || raw.isEmpty) {
      return const PultHeaderCustomization();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return PultHeaderCustomization.fromJson(decoded);
      }
    } catch (_) {
      // ignore malformed customization values
    }
    return const PultHeaderCustomization();
  }

  static Future<void> saveHeaderCustomization(
    String clientId,
    PultHeaderCustomization customization,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_headerCustomizationKeyPrefix$clientId',
      jsonEncode(customization.toJson()),
    );
  }
