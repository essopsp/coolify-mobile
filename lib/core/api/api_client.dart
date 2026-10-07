import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/coolify_instance.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(CoolifyInstance instance)
      : _baseUrl = instance.baseUrl,
        _token = instance.token,
        _dio = Dio(BaseOptions(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer $_token';
          handler.next(options);
        },
        onError: (e, handler) {
          handler.next(e);
        },
      ),
    );
  }

  ApiClient.unauthenticated()
      : _baseUrl = '',
        _token = '',
        _dio = Dio();

  final String _baseUrl;
  final String _token;
  final Dio _dio;

  String get baseUrl => _baseUrl;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _request('GET', path, query: query);

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) =>
      _request('POST', path, query: query, body: body);

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) =>
      _request('PATCH', path, query: query, body: body);

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) =>
      _request('PUT', path, query: query, body: body);

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) =>
      _request('DELETE', path, query: query, body: body);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    if (_token.isEmpty) {
      throw const ApiException(
        ApiErrorKind.unauthenticated,
        'No Coolify connection selected. Add an instance first.',
      );
    }
    try {
      final options = Options(
        method: method,
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );
      Response<dynamic> response;
      switch (method) {
        case 'GET':
          response = await _dio.get(
            '$_baseUrl$path',
            queryParameters: query,
            options: options,
          );
          break;
        case 'DELETE':
          response = await _dio.delete(
            '$_baseUrl$path',
            queryParameters: query,
            data: body,
            options: options,
          );
          break;
        default:
          response = await _dio.request(
            '$_baseUrl$path',
            data: body,
            queryParameters: query,
            options: options,
          );
          break;
      }
      return response.data;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout ||
            DioExceptionType.sendTimeout ||
            DioExceptionType.receiveTimeout:
        return const ApiException(
          ApiErrorKind.network,
          'Connection timed out. Check the instance URL and your network.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          ApiErrorKind.network,
          'Cannot reach the Coolify instance. Check the URL, network, '
              'and that API access is enabled on self-hosted instances.',
        );
      default:
        break;
    }
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final bodyStr = body == null ? '' : (body is String ? body : _stringify(body));
    if (status != null) {
      return ApiException.fromStatus(status, bodyStr);
    }
    return ApiException(
      ApiErrorKind.network,
      e.message ?? 'Network error occurred.',
    );
  }

  String _stringify(dynamic body) {
    try {
      return const JsonEncoder.withIndent(null).convert(body);
    } catch (_) {
      return body.toString();
    }
  }
}