import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'screens/weather_page.dart';
import 'services/location.dart';
import 'services/networking.dart';

Future<String> loadApiKey({AssetBundle? bundle}) async {
  const fromRun = String.fromEnvironment('OPENWEATHER_API_KEY');
  try {
    final contents = await (bundle ?? rootBundle).loadString(
      'config/api_key.txt',
    );
    for (final line in contents.split(RegExp(r'\r?\n'))) {
      final key = line.trim();
      if (key.isNotEmpty && !key.startsWith('#')) {
        return key;
      }
    }
  } catch (_) {
    // A fresh checkout can run without the ignored local key file.
  }
  return fromRun.trim();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiKey = await loadApiKey();
  runApp(
    ClimaApp(
      weather: OpenWeatherRepository(client: http.Client(), apiKey: apiKey),
      location: DeviceLocationRepository(),
    ),
  );
}

class ClimaApp extends StatelessWidget {
  const ClimaApp({super.key, required this.weather, required this.location});

  final WeatherRepository weather;
  final LocationRepository location;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Clima',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF79C8F8),
        brightness: Brightness.dark,
      ),
      fontFamily: 'Roboto',
    ),
    home: WeatherPage(weather: weather, location: location),
  );
}
