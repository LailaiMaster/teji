import 'dart:convert';

import 'package:http/http.dart' as http;

typedef JsonMap = Map<String, dynamic>;

class TejiApi {
  TejiApi(String baseUrl)
    : baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

  final String baseUrl;

  Future<JsonMap> health() => _getMap('/health');

  Future<List<JsonMap>> cars() async {
    final data = await _get('/api/cars');
    return _asList(data);
  }

  Future<JsonMap> overview() => _getMap('/api/overview');

  Future<List<JsonMap>> drives({int limit = 50, int? carId}) async {
    final query = {'limit': '$limit', if (carId != null) 'car_id': '$carId'};
    final data = await _get('/api/drives', query);
    return _asList(data);
  }

  Future<JsonMap> driveDetail(int driveId) => _getMap('/api/drives/$driveId');

  Future<List<JsonMap>> chargingProcesses({int limit = 50, int? carId}) async {
    final query = {'limit': '$limit', if (carId != null) 'car_id': '$carId'};
    final data = await _get('/api/charging-processes', query);
    return _asList(data);
  }

  Future<JsonMap> _getMap(String path, [Map<String, String>? query]) async {
    final data = await _get(path, query);
    if (data is JsonMap) return data;
    throw ApiException('接口返回格式不正确');
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    late http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 30));
    } on Object catch (error) {
      throw ApiException('连接失败：$error');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('接口错误 ${response.statusCode}：${response.body}');
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on Object catch (error) {
      throw ApiException('JSON 解析失败：$error');
    }
  }

  List<JsonMap> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<JsonMap>().toList(growable: false);
    }
    throw ApiException('接口返回格式不正确');
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
