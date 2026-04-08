import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class WeatherData {
  final double temperature; // °C
  final double humidity; // %
  final double windSpeed; // km/h
  final int weatherCode;
  final String description;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.description,
  });
}

class WeatherService {
  static Future<WeatherData?> getCurrentWeather(LatLng position) async {
    final url = 'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final current = data['current'];

      final code = current['weather_code'] as int;

      return WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        humidity: (current['relative_humidity_2m'] as num).toDouble(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        weatherCode: code,
        description: _describeWeather(code),
      );
    } catch (_) {
      return null;
    }
  }

  static String _describeWeather(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Cloudy';
    if (code <= 49) return 'Fog';
    if (code <= 59) return 'Drizzle';
    if (code <= 69) return 'Rain';
    if (code <= 79) return 'Snow';
    if (code <= 84) return 'Showers';
    if (code <= 99) return 'Storm';
    return 'Unknown';
  }
}
