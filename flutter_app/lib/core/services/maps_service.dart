import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../models/order.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
}

class MapsService {
  static const String apiKey = 'AIzaSyCMUyGsOG9mXLX-mBIhvuMJjrkpIkQKPSA';

  bool get hasApiKey => apiKey.isNotEmpty;

  Future<List<PlaceSuggestion>> autocompletePlaces(String query) async {
    if (!hasApiKey || query.trim().length < 2) return [];
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': query.trim(),
        'key': apiKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final predictions = (json['predictions'] as List<dynamic>? ?? []);
    return predictions.map((item) {
      final map = item as Map<String, dynamic>;
      return PlaceSuggestion(
        placeId: map['place_id'] as String? ?? '',
        description: map['description'] as String? ?? '',
      );
    }).toList();
  }

  Future<GeoPointLocation?> getPlaceDetails(String placeId) async {
    if (!hasApiKey || placeId.isEmpty) return null;
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'formatted_address,geometry',
        'key': apiKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final result = json['result'] as Map<String, dynamic>?;
    if (result == null) return null;
    final loc = result['geometry']?['location'] as Map<String, dynamic>?;
    if (loc == null) return null;
    return GeoPointLocation(
      address: result['formatted_address'] as String? ?? '',
      lat: (loc['lat'] as num).toDouble(),
      lng: (loc['lng'] as num).toDouble(),
    );
  }

  /// Fetches driving distance in km via Google Distance Matrix API.
  /// Falls back to 1.22x Haversine road estimate if offline or API key is absent.
  Future<double> calculateDrivingDistanceKm({
    required GeoPointLocation pickup,
    required GeoPointLocation dropoff,
  }) async {
    if (hasApiKey) {
      try {
        final uri = Uri.https(
          'maps.googleapis.com',
          '/maps/api/distancematrix/json',
          {
            'origins': '${pickup.lat},${pickup.lng}',
            'destinations': '${dropoff.lat},${dropoff.lng}',
            'units': 'metric',
            'key': apiKey,
          },
        );
        final res = await http.get(uri);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final rows = data['rows'] as List<dynamic>? ?? [];
          if (rows.isNotEmpty) {
            final elements = rows.first['elements'] as List<dynamic>? ?? [];
            if (elements.isNotEmpty && elements.first['status'] == 'OK') {
              final meters = (elements.first['distance']['value'] as num).toDouble();
              return double.parse((meters / 1000.0).toStringAsFixed(1));
            }
          }
        }
      } catch (_) {
        // Fall through to offline Haversine estimate
      }
    }

    return estimateRoadKmHaversine(pickup, dropoff);
  }

  double estimateRoadKmHaversine(GeoPointLocation a, GeoPointLocation b) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(b.lat - a.lat);
    final dLng = _degToRad(b.lng - a.lng);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final h = sinLat * sinLat +
        math.cos(_degToRad(a.lat)) *
            math.cos(_degToRad(b.lat)) *
            sinLng *
            sinLng;
    final straightKm = 2 * earthRadiusKm * math.asin(math.sqrt(h));
    // Apply 1.22x road winding factor for realistic highway distance
    return double.parse((straightKm * 1.22).toStringAsFixed(1));
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Reverse geocode a lat/lng to a human-readable address.
  /// Returns null if the API key is absent or the request fails.
  Future<String?> httpGet(Uri uri) async {
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final results = json['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      return (results.first as Map<String, dynamic>)['formatted_address']
          as String?;
    } catch (_) {
      return null;
    }
  }
}
