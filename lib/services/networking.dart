import 'dart:convert';

import 'package:http/http.dart' as http;

import '../weather_model.dart';

abstract class WeatherRepository {
  bool get isConfigured;

  Future<WeatherData> byCity(String city);

  Future<WeatherData> byCoordinates(double latitude, double longitude);
}

class WeatherFailure implements Exception {
  const WeatherFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class OpenWeatherRepository implements WeatherRepository {
  OpenWeatherRepository({http.Client? client, required this.apiKey})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;

  @override
  bool get isConfigured => apiKey.trim().isNotEmpty;

  @override
  Future<WeatherData> byCity(String city) async {
    final name = city.trim();
    if (name.isEmpty) throw const WeatherFailure('Hãy nhập tên thành phố.');
    return _fetch({'q': name});
  }

  @override
  Future<WeatherData> byCoordinates(double latitude, double longitude) =>
      _fetch({'lat': '$latitude', 'lon': '$longitude'});

  Future<WeatherData> _fetch(Map<String, String> location) async {
    if (!isConfigured) {
      throw const WeatherFailure(
        'Chưa có OpenWeatherMap API key. Dán key vào config/api_key.txt rồi chạy lại.',
      );
    }

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      ...location,
      'appid': apiKey,
      'units': 'metric',
      'lang': 'vi',
    });

    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 404) {
        throw const WeatherFailure('Không tìm thấy thành phố này.');
      }
      if (response.statusCode == 401) {
        throw const WeatherFailure(
          'API key không hợp lệ hoặc chưa được kích hoạt.',
        );
      }
      if (response.statusCode != 200) {
        throw WeatherFailure(
          'Không tải được thời tiết (mã ${response.statusCode}). Thử lại sau.',
        );
      }
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) {
        throw const WeatherFailure('Dữ liệu thời tiết không đúng định dạng.');
      }
      return WeatherData.fromJson(json);
    } on WeatherFailure {
      rethrow;
    } on FormatException {
      throw const WeatherFailure('Dữ liệu thời tiết không đúng định dạng.');
    } on Exception {
      throw const WeatherFailure(
        'Không thể kết nối. Kiểm tra Internet và thử lại.',
      );
    }
  }
}
