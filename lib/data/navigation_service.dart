import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteStep {
  final String instruction;
  final double distance; // meters
  final double duration; // seconds
  final String maneuver; // 'turn-left', 'turn-right', 'straight', etc
  final LatLng location;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.location,
  });
}

class NavigationRoute {
  final List<LatLng> polyline;
  final List<RouteStep> steps;
  final double totalDistance; // meters
  final double totalDuration; // seconds
  final String summary;

  NavigationRoute({
    required this.polyline,
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
    required this.summary,
  });
}

class SearchResult {
  final String name;
  final String displayName;
  final LatLng location;

  SearchResult({required this.name, required this.displayName, required this.location});
}

class NavigationService {
  // OSRM free routing API
  static Future<NavigationRoute?> getRoute(LatLng from, LatLng to) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson&steps=true';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data['routes'] == null || (data['routes'] as List).isEmpty) return null;

      final route = data['routes'][0];
      final geometry = route['geometry']['coordinates'] as List;
      final polyline = geometry.map<LatLng>((coord) =>
        LatLng(coord[1].toDouble(), coord[0].toDouble())
      ).toList();

      final legs = route['legs'] as List;
      final steps = <RouteStep>[];

      for (final leg in legs) {
        for (final step in leg['steps']) {
          final maneuverData = step['maneuver'];
          final location = maneuverData['location'];
          String maneuverType = maneuverData['type'] ?? 'straight';
          String modifier = maneuverData['modifier'] ?? '';

          String instruction = step['name'] ?? '';
          if (instruction.isEmpty) instruction = maneuverType;

          String maneuver = 'straight';
          if (maneuverType == 'turn') {
            maneuver = 'turn-$modifier';
          } else if (maneuverType == 'end of road') {
            maneuver = 'turn-$modifier';
          } else if (maneuverType == 'fork' || maneuverType == 'ramp') {
            maneuver = modifier.contains('left') ? 'slight-left' : 'slight-right';
          } else if (maneuverType == 'roundabout') {
            maneuver = 'roundabout';
          } else if (maneuverType == 'arrive') {
            maneuver = 'arrive';
          }

          steps.add(RouteStep(
            instruction: instruction,
            distance: (step['distance'] as num).toDouble(),
            duration: (step['duration'] as num).toDouble(),
            maneuver: maneuver,
            location: LatLng(location[1].toDouble(), location[0].toDouble()),
          ));
        }
      }

      return NavigationRoute(
        polyline: polyline,
        steps: steps,
        totalDistance: (route['distance'] as num).toDouble(),
        totalDuration: (route['duration'] as num).toDouble(),
        summary: route['legs'][0]['summary'] ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  // Nominatim free geocoding/search API
  static Future<List<SearchResult>> searchPlace(String query) async {
    final url = 'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&addressdetails=1';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'TeslaDashboard/1.0'},
      );
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      return data.map((item) => SearchResult(
        name: item['name'] ?? item['display_name'].split(',')[0],
        displayName: item['display_name'],
        location: LatLng(
          double.parse(item['lat']),
          double.parse(item['lon']),
        ),
      )).toList();
    } catch (e) {
      return [];
    }
  }
}
