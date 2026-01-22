import 'api_constants.dart';

/// Ensures that a URL is absolute by prepending the base URL if needed
String ensureAbsoluteUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  // If already absolute (starts with http:// or https://), return as is
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  // If it's a relative path, prepend the base URL
  // Remove leading slash if present to avoid double slashes
  final path = url.startsWith('/') ? url.substring(1) : url;
  return '${ApiConstants.baseUrl}/$path';
}
