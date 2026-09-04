enum BackupAppVersionRelation { legacy, older, same, newer }

const supportedBackupFormatVersion = 1;

class BackupHeader {
  const BackupHeader({
    required this.schemaVersion,
    required this.exportedAt,
    required this.formatVersion,
    required this.appVersion,
    required this.buildNumber,
  });

  factory BackupHeader.fromPayload(Map<String, dynamic> payload) {
    final rawMeta = payload['backupMeta'];
    final meta = rawMeta is Map ? rawMeta : const <String, dynamic>{};

    return BackupHeader(
      schemaVersion: _readInt(payload['schemaVersion']),
      exportedAt: _readString(payload['exportedAt']),
      formatVersion: _readInt(meta['formatVersion']),
      appVersion: _readString(meta['appVersion']),
      buildNumber: _readString(meta['buildNumber']),
    );
  }

  final int? schemaVersion;
  final String? exportedAt;
  final int? formatVersion;
  final String? appVersion;
  final String? buildNumber;
}

class BackupCompatibility {
  const BackupCompatibility({
    required this.appVersionRelation,
    required this.hasNewerFormat,
    required this.hasNewerSchema,
  });

  final BackupAppVersionRelation appVersionRelation;
  final bool hasNewerFormat;
  final bool hasNewerSchema;
}

BackupCompatibility classifyBackupCompatibility({
  required BackupHeader header,
  required String currentAppVersion,
  required int currentSchemaVersion,
}) {
  final formatVersion = header.formatVersion;
  final backupAppVersion = header.appVersion;
  final comparison = backupAppVersion == null
      ? null
      : compareSemanticVersions(backupAppVersion, currentAppVersion);

  final relation = formatVersion == null || comparison == null
      ? BackupAppVersionRelation.legacy
      : comparison < 0
      ? BackupAppVersionRelation.older
      : comparison > 0
      ? BackupAppVersionRelation.newer
      : BackupAppVersionRelation.same;

  return BackupCompatibility(
    appVersionRelation: relation,
    hasNewerFormat:
        formatVersion != null && formatVersion > supportedBackupFormatVersion,
    hasNewerSchema:
        header.schemaVersion != null &&
        header.schemaVersion! > currentSchemaVersion,
  );
}

int? compareSemanticVersions(String left, String right) {
  final leftVersion = _SemanticVersion.tryParse(left);
  final rightVersion = _SemanticVersion.tryParse(right);
  if (leftVersion == null || rightVersion == null) return null;
  return leftVersion.compareTo(rightVersion);
}

String buildBackupFileName({
  required String appVersion,
  required DateTime createdAt,
}) {
  final safeVersion = appVersion
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  final version = safeVersion.isEmpty ? 'unknown' : safeVersion;
  final timestamp =
      '${createdAt.year.toString().padLeft(4, '0')}-'
      '${createdAt.month.toString().padLeft(2, '0')}-'
      '${createdAt.day.toString().padLeft(2, '0')}_'
      '${createdAt.hour.toString().padLeft(2, '0')}'
      '${createdAt.minute.toString().padLeft(2, '0')}'
      '${createdAt.second.toString().padLeft(2, '0')}';
  return 'Trener_backup_v${version}_$timestamp.json';
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  return null;
}

String? _readString(dynamic value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

class _SemanticVersion implements Comparable<_SemanticVersion> {
  const _SemanticVersion(this.core, this.preRelease);

  static _SemanticVersion? tryParse(String value) {
    final withoutBuild = value.trim().split('+').first;
    final separator = withoutBuild.indexOf('-');
    final coreText = separator < 0
        ? withoutBuild
        : withoutBuild.substring(0, separator);
    final preReleaseText = separator < 0
        ? null
        : withoutBuild.substring(separator + 1);
    final coreParts = coreText.split('.');
    if (coreParts.isEmpty ||
        coreParts.any((part) => !RegExp(r'^\d+$').hasMatch(part))) {
      return null;
    }
    final core = coreParts.map(int.parse).toList(growable: false);
    final preRelease = preReleaseText == null
        ? const <String>[]
        : preReleaseText.split('.');
    if (preRelease.any((part) => part.isEmpty)) return null;
    return _SemanticVersion(core, preRelease);
  }

  final List<int> core;
  final List<String> preRelease;

  @override
  int compareTo(_SemanticVersion other) {
    final coreLength = core.length > other.core.length
        ? core.length
        : other.core.length;
    for (var index = 0; index < coreLength; index++) {
      final left = index < core.length ? core[index] : 0;
      final right = index < other.core.length ? other.core[index] : 0;
      if (left != right) return left.compareTo(right);
    }

    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;

    final preReleaseLength = preRelease.length > other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var index = 0; index < preReleaseLength; index++) {
      if (index >= preRelease.length) return -1;
      if (index >= other.preRelease.length) return 1;
      final left = preRelease[index];
      final right = other.preRelease[index];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      if (leftNumber != null && rightNumber != null) {
        if (leftNumber != rightNumber) return leftNumber.compareTo(rightNumber);
      } else if (leftNumber != null) {
        return -1;
      } else if (rightNumber != null) {
        return 1;
      } else {
        final comparison = left.compareTo(right);
        if (comparison != 0) return comparison;
      }
    }
    return 0;
  }
}
