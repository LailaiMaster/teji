const defaultApiBaseUrl = String.fromEnvironment('TEJI_API_BASE_URL');
const apiBaseUrlKey = 'api_base_url';

String normalizeApiBaseUrl(String? value) {
  if (value == null || value.trim().isEmpty) return defaultApiBaseUrl;
  final normalized = value.trim().replaceAll(RegExp(r'/+$'), '');
  return normalized;
}
