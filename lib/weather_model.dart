import 'package:flutter/material.dart';

class WeatherData {
  const WeatherData({
    required this.city,
    required this.temperature,
    required this.description,
    required this.conditionId,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
  });

  final String city;
  final double temperature;
  final String description;
  final int conditionId;
  final double feelsLike;
  final int humidity;
  final double windSpeed;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>?;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    return WeatherData(
      city: json['name'] as String,
      temperature: (main['temp'] as num).toDouble(),
      description: weather['description'] as String,
      conditionId: weather['id'] as int,
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: main['humidity'] as int,
      windSpeed: (wind?['speed'] as num?)?.toDouble() ?? 0,
    );
  }

  IconData get icon {
    if (conditionId < 300) return Icons.thunderstorm_rounded;
    if (conditionId < 600) return Icons.grain_rounded;
    if (conditionId < 700) return Icons.ac_unit_rounded;
    if (conditionId < 800) return Icons.foggy;
    if (conditionId == 800) return Icons.wb_sunny_rounded;
    return Icons.cloud_rounded;
  }
}
