import 'package:url_launcher/url_launcher.dart';

typedef CanLaunchUriFn = Future<bool> Function(Uri uri);
typedef LaunchExternalUriFn = Future<bool> Function(Uri uri);

final RegExp _xHandlePattern = RegExp(r'^[A-Za-z0-9_]{1,15}$');
const Set<String> _xReservedSegments = {
  'home',
  'explore',
  'search',
  'i',
  'intent',
  'settings',
  'messages',
  'notifications',
  'compose',
  'login',
  'signup',
};

bool _isXHost(String host) {
  final normalized = host.toLowerCase();
  return normalized == 'x.com' ||
      normalized == 'www.x.com' ||
      normalized == 'twitter.com' ||
      normalized == 'www.twitter.com';
}

String? _extractXHandle(Uri uri) {
  if (!_isXHost(uri.host)) return null;
  if (uri.pathSegments.isEmpty) return null;
  final first = uri.pathSegments.first.trim();
  if (first.isEmpty) return null;

  final candidate = first.startsWith('@') ? first.substring(1) : first;
  if (candidate.isEmpty) return null;
  if (_xReservedSegments.contains(candidate.toLowerCase())) return null;
  if (!_xHandlePattern.hasMatch(candidate)) return null;
  return candidate;
}

List<Uri> preferredNativeAppUris(Uri uri) {
  if (!_isXHost(uri.host)) return const <Uri>[];

  final candidates = <Uri>[];
  final handle = _extractXHandle(uri);
  if (handle != null) {
    candidates.add(Uri.parse('twitter://user?screen_name=$handle'));
  }

  if (uri.pathSegments.length >= 3 &&
      uri.pathSegments[1].toLowerCase() == 'status') {
    final statusId = uri.pathSegments[2].trim();
    if (statusId.isNotEmpty) {
      candidates.add(Uri.parse('twitter://status?id=$statusId'));
    }
  }

  candidates.add(Uri.parse('twitter://'));
  return candidates;
}

Uri? parseExternalUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;
  var uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  if (!uri.hasScheme) {
    uri = Uri.tryParse('https://$trimmed');
  }
  return uri;
}

Future<bool> launchExternalUrlWithAppFallback(
  String rawUrl, {
  CanLaunchUriFn? canLaunchUri,
  LaunchExternalUriFn? launchExternalUri,
}) async {
  final uri = parseExternalUrl(rawUrl);
  if (uri == null) return false;

  final canLaunch = canLaunchUri ?? canLaunchUrl;
  final launch = launchExternalUri ??
      (candidate) => launchUrl(candidate, mode: LaunchMode.externalApplication);

  for (final nativeUri in preferredNativeAppUris(uri)) {
    try {
      if (await canLaunch(nativeUri)) {
        final opened = await launch(nativeUri);
        if (opened) return true;
      }
    } catch (_) {
      // Fall through to web URL.
    }
  }

  try {
    return await launch(uri);
  } catch (_) {
    return false;
  }
}
