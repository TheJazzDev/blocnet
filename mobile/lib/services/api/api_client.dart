import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blocnet/app/config.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.responseBody});

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() {
    return 'ApiException(statusCode: $statusCode, message: $message, responseBody: $responseBody)';
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
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      final token = _authToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (fields != null && fields.isNotEmpty) {
        request.fields.addAll(fields);
      }

      request.files
          .add(await http.MultipartFile.fromPath(fieldName, file.path));
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
        'Unable to reach API at ${AppConfig.apiBaseUrl}. Check API_BASE_URL and backend server.',
      );
    } on HttpException {
      throw ApiException(
        'Network error while connecting to ${AppConfig.apiBaseUrl}.',
      );
    } on FormatException {
      throw ApiException('Received malformed response from API.');
    } on TimeoutException {
      throw ApiException(
        'Request timed out after ${_requestTimeout.inSeconds}s. Check API_BASE_URL and backend availability.',
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
        'Unable to reach API at ${AppConfig.apiBaseUrl}. Check API_BASE_URL and backend server.',
      );
    } on HttpException {
      throw ApiException(
        'Network error while connecting to ${AppConfig.apiBaseUrl}.',
      );
    } on FormatException {
      throw ApiException('Received malformed response from API.');
    } on TimeoutException {
      throw ApiException(
        'Request timed out after ${_requestTimeout.inSeconds}s. Check API_BASE_URL and backend availability.',
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
      throw ApiException(
        'Request failed',
        statusCode: response.statusCode,
        responseBody: body,
      );
    }

    if (body.isEmpty) {
      return null;
    }

    return jsonDecode(body);
  }
}
