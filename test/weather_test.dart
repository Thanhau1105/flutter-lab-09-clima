import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lab_09/main.dart';
import 'package:lab_09/services/location.dart';
import 'package:lab_09/services/networking.dart';
import 'package:lab_09/weather_model.dart';

const sample = WeatherData(
  city: 'Hà Nội',
  temperature: 28.4,
  description: 'mây rải rác',
  conditionId: 802,
  feelsLike: 31.0,
  humidity: 72,
  windSpeed: 2.5,
);

class FakeWeather implements WeatherRepository {
  String? searchedCity;
  Coordinates? searchedCoordinates;
  WeatherFailure? failure;

  @override
  bool get isConfigured => true;

  @override
  Future<WeatherData> byCity(String city) async {
    searchedCity = city;
    if (failure != null) throw failure!;
    return sample;
  }

  @override
  Future<WeatherData> byCoordinates(double latitude, double longitude) async {
    searchedCoordinates = Coordinates(latitude, longitude);
    return sample;
  }
}

class FakeLocation implements LocationRepository {
  @override
  Future<Coordinates> current() async => const Coordinates(21.03, 105.85);
}

class MemoryBundle extends CachingAssetBundle {
  MemoryBundle(this.contents);

  final String contents;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(contents)));
}

void main() {
  test('reads local key and skips comments', () async {
    expect(
      await loadApiKey(bundle: MemoryBundle('# ghi chú\n\n  test-key  \n')),
      'test-key',
    );
    expect(await loadApiKey(bundle: MemoryBundle('# chưa có key\n')), isEmpty);
  });

  test('parses OpenWeatherMap JSON and maps condition to icon', () {
    final data = WeatherData.fromJson({
      'name': 'Hà Nội',
      'main': {'temp': 28.4, 'feels_like': 31.0, 'humidity': 72},
      'weather': [
        {'id': 802, 'description': 'mây rải rác'},
      ],
      'wind': {'speed': 2.5},
    });
    expect(data.city, 'Hà Nội');
    expect(data.temperature, 28.4);
    expect(data.icon, Icons.cloud_rounded);
  });

  test('city request encodes query, metric units, language and key', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/data/2.5/weather');
      expect(request.url.queryParameters['q'], 'Hà Nội');
      expect(request.url.queryParameters['appid'], 'test-key');
      expect(request.url.queryParameters['units'], 'metric');
      expect(request.url.queryParameters['lang'], 'vi');
      return http.Response.bytes(
        utf8.encode(
          '{"name":"Hà Nội","main":{"temp":28.4,"feels_like":31,"humidity":72},"weather":[{"id":802,"description":"mây rải rác"}],"wind":{"speed":2.5}}',
        ),
        200,
      );
    });
    final result = await OpenWeatherRepository(
      client: client,
      apiKey: 'test-key',
    ).byCity(' Hà Nội ');
    expect(result.temperature, 28.4);
  });

  test('missing key and unknown city show useful errors', () async {
    final noKey = OpenWeatherRepository(
      client: MockClient((_) async => http.Response('', 200)),
      apiKey: '',
    );
    expect(() => noKey.byCity('Hà Nội'), throwsA(isA<WeatherFailure>()));

    final notFound = OpenWeatherRepository(
      client: MockClient((_) async => http.Response('', 404)),
      apiKey: 'test-key',
    );
    await expectLater(
      notFound.byCity('Unknown'),
      throwsA(isA<WeatherFailure>()),
    );
  });

  testWidgets('search and location update the weather screen', (tester) async {
    final weather = FakeWeather();
    await tester.pumpWidget(
      ClimaApp(weather: weather, location: FakeLocation()),
    );
    expect(find.text('Bầu trời của bạn đang chờ'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('city-field')), 'Hà Nội');
    await tester.tap(find.byKey(const Key('search-button')));
    await tester.pumpAndSettle();
    expect(weather.searchedCity, 'Hà Nội');
    expect(find.byKey(const Key('weather-city')), findsOneWidget);
    expect(find.text('28°'), findsOneWidget);

    await tester.tap(find.byKey(const Key('location-button')));
    await tester.pumpAndSettle();
    expect(weather.searchedCoordinates?.latitude, 21.03);
    expect(weather.searchedCoordinates?.longitude, 105.85);
  });

  testWidgets('API error is shown without crashing', (tester) async {
    final weather = FakeWeather()
      ..failure = const WeatherFailure('Không tìm thấy thành phố này.');
    await tester.pumpWidget(
      ClimaApp(weather: weather, location: FakeLocation()),
    );
    await tester.enterText(find.byKey(const Key('city-field')), 'Unknown');
    await tester.tap(find.byKey(const Key('search-button')));
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy thành phố này.'), findsOneWidget);
  });
}
