import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blocnet/app/config.dart';
import 'package:blocnet/services/core/startup_metrics_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.responseBody});

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() {
    if (statusCode != null) {
      return '$message (code $statusCode)';
    }
    return message;
  }
}

class ApiClient {
  ApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static const Duration _requestTimeout = Duration(seconds: 15);

  static String? _authToken;
  static Future<String?> Function()? _tokenRefresher;
  static Future<String?>? _inFlightTokenRefresh;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static void setAuthTokenRefresher(Future<String?> Function()? refresher) {
    _tokenRefresher = refresher;
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = _buildUri(path, query);
    final response =
        await _request(() => _httpClient.get(uri, headers: _headers()));
    return _parseResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await _request(
      () => _httpClient.post(
        uri,
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _parseResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await _request(
      () => _httpClient.put(
        uri,
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _parseResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(path);
    final response = await _request(
      () => _httpClient.patch(
        uri,
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _parseResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    final response =
        await _request(() => _httpClient.delete(uri, headers: _headers()));
    return _parseResponse(response);
  }

  Future<dynamic> postMultipartFile(
    String path, {
    required String fieldName,
    required File file,
    Map<String, String>? fields,
  }) async {
    final uri = _buildUri(path);

    Future<http.StreamedResponse> send() async {
      StartupMetricsService.recordApiCall();
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      final token = _authToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (fields != null && fields.isNotEmpty) {
        request.fields.addAll(fields);
      }

      final contentType = _inferMediaTypeForFile(file.path);
      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          await file.readAsBytes(),
          filename: file.uri.pathSegments.isNotEmpty
              ? file.uri.pathSegments.last
              : 'upload.bin',
          contentType: contentType,
        ),
      );
      return request.send().timeout(_requestTimeout);
    }

    try {
      var streamed = await send();
      if (streamed.statusCode == 401) {
        final refreshedToken = await _refreshAuthToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          streamed = await send();
        }
      }

      final response = await http.Response.fromStream(streamed);
      return _parseResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect right now. Please check your internet and try again.',
      );
    } on HttpException {
      throw ApiException(
        'Network error. Please try again in a moment.',
      );
    } on FormatException {
      throw ApiException('Received malformed response from API.');
    } on TimeoutException {
      throw ApiException(
        'Request timed out. Please try again.',
      );
    }
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse(AppConfig.apiBaseUrl);
    final nextPath = '${base.path}$normalizedPath'.replaceAll('//', '/');

    return base.replace(
      path: nextPath,
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> _request(Future<http.Response> Function() call) async {
    try {
      StartupMetricsService.recordApiCall();
      final response = await call().timeout(_requestTimeout);
      if (response.statusCode == 401) {
        final refreshedToken = await _refreshAuthToken();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          final retryResponse = await call().timeout(_requestTimeout);
          return retryResponse;
        }
      }

      return response;
    } on SocketException {
      throw ApiException(
        'Unable to connect right now. Please check your internet and try again.',
      );
    } on HttpException {
      throw ApiException(
        'Network error. Please try again in a moment.',
      );
    } on FormatException {
      throw ApiException('Received malformed response from API.');
    } on TimeoutException {
      throw ApiException(
        'Request timed out. Please try again.',
      );
    }
  }

  Future<String?> _refreshAuthToken() async {
    final refresher = _tokenRefresher;
    if (refresher == null) {
      return null;
    }

    final pending = _inFlightTokenRefresh;
    if (pending != null) {
      return pending;
    }

    final refreshFuture = refresher();
    _inFlightTokenRefresh = refreshFuture;
    try {
      final token = await refreshFuture;
      if (token != null && token.isNotEmpty) {
        _authToken = token;
      }
      return token;
    } catch (_) {
      return null;
    } finally {
      if (identical(_inFlightTokenRefresh, refreshFuture)) {
        _inFlightTokenRefresh = null;
      }
    }
  }

  dynamic _parseResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    final body = response.body.trim();

    if (!isSuccess) {
      final parsedMessage = _extractErrorMessage(body);
      throw ApiException(
        parsedMessage ?? _fallbackStatusMessage(response.statusCode),
        statusCode: response.statusCode,
        responseBody: body,
      );
    }

    if (body.isEmpty) {
      return null;
    }

    return jsonDecode(body);
  }

  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
        final error = decoded['error']?.toString().trim();
        if (error != null && error.isNotEmpty) return error;
      }
    } catch (_) {
      // Ignore parse failure and use status-based fallback.
    }
    return null;
  }

  String _fallbackStatusMessage(int statusCode) {
    if (statusCode == 401) return 'Session expired. Please sign in again.';
    if (statusCode == 403) return 'You are not allowed to perform this action.';
    if (statusCode == 404) return 'Requested data was not found.';
    if (statusCode == 409) {
      return 'Action could not be completed due to a conflict.';
    }
    if (statusCode >= 500) return 'Server error. Please try again shortly.';
    return 'Request failed. Please try again.';
  }

  MediaType? _inferMediaTypeForFile(String path) {
    final normalizedPath = path.toLowerCase();
    if (normalizedPath.endsWith('.jpg') || normalizedPath.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (normalizedPath.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (normalizedPath.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    if (normalizedPath.endsWith('.heic')) {
      return MediaType('image', 'heic');
    }
    if (normalizedPath.endsWith('.heif')) {
      return MediaType('image', 'heif');
    }
    return null;
  }
}
