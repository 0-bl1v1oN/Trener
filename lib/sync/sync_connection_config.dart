class SyncConnectionConfig {
  const SyncConnectionConfig({
    required this.endpoint,
    required this.token,
    this.timeout = const Duration(seconds: 12),
  });

  factory SyncConnectionConfig.fromEnvironment() {
    return const SyncConnectionConfig(
      endpoint: String.fromEnvironment(
        'SYNC_INGEST_ENDPOINT',
        defaultValue: 'https://training.viro35.ru/api/ingest',
      ),
      token: String.fromEnvironment('SYNC_INGEST_TOKEN'),
    );
  }

  final String endpoint;
  final String token;
  final Duration timeout;

  Uri? get endpointUri {
    final value = Uri.tryParse(endpoint.trim());
    if (value == null || value.scheme != 'https' || value.host.isEmpty) {
      return null;
    }
    return value;
  }

  bool get isConfigured => endpointUri != null && token.trim().isNotEmpty;
}
