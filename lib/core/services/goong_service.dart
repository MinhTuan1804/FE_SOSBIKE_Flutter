import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoongRouteData {
  const GoongRouteData({
    required this.points,
    required this.distanceKm,
    required this.durationMins,
  });

  final List<LatLng> points;
  final double distanceKm;
  final int durationMins;

  static const empty = GoongRouteData(
    points: [],
    distanceKm: 0.0,
    durationMins: 0,
  );
}

class GoongService {
  final Dio _dio = Dio();

  String get _apiKey {
    try {
      if (dotenv.isInitialized) {
        final key = dotenv.env['GOONG_API_KEY'];
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (_) {}
    return 'J7uk8GJZvzozpZ8p631cnxMVXUNVz0O0juQCSAJq';
  }

  /// Calculates route polyline, distance, and duration between origin and destination coordinates.
  Future<GoongRouteData> getRouteData({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final key = _apiKey;
    if (key.isEmpty) {
      debugPrint('Goong API Key is missing or empty.');
      return GoongRouteData.empty;
    }

    const url = 'https://rsapi.goong.io/Direction';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        url,
        queryParameters: {
          'origin': '$originLat,$originLng',
          'destination': '$destLat,$destLng',
          'vehicle': 'bike',
          'api_key': key,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          
          // Parse polyline points
          final polylineObj = firstRoute['overview_polyline'] as Map<String, dynamic>?;
          final encodedPoints = polylineObj?['points'] as String?;
          List<LatLng> decodedPoints = const [];
          if (encodedPoints != null && encodedPoints.isNotEmpty) {
            decodedPoints = _decodePolyline(encodedPoints);
          }

          // Parse distance and duration
          final legs = firstRoute['legs'] as List?;
          double distanceKm = 0.0;
          int durationMins = 0;

          if (legs != null && legs.isNotEmpty) {
            final firstLeg = legs[0] as Map<String, dynamic>;
            final distanceObj = firstLeg['distance'] as Map<String, dynamic>?;
            final durationObj = firstLeg['duration'] as Map<String, dynamic>?;

            final distanceVal = distanceObj?['value'] as num?; // distance in meters
            final durationVal = durationObj?['value'] as num?; // duration in seconds

            if (distanceVal != null) {
              distanceKm = distanceVal.toDouble() / 1000.0;
            }
            if (durationVal != null) {
              durationMins = (durationVal.toDouble() / 60.0).round();
            }
          }

          return GoongRouteData(
            points: decodedPoints,
            distanceKm: distanceKm,
            durationMins: durationMins,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching Goong Direction: $e');
    }

    return GoongRouteData.empty;
  }

  /// Polyline decoding algorithm for standard encoded polyline representation.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
