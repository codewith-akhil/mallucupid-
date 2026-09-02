import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

/// GeoHelper
///
/// Lightweight replacement for the abandoned `geoflutterfire` package.
///
/// It writes/reads the EXACT same Firestore data format that geoflutterfire
/// used, so existing database data stays compatible:
///
/// ```json
/// {
///   "geohash": "<geohash string>",
///   "geopoint": <Firestore GeoPoint>
/// }
/// ```
class GeoHelper {
  GeoHelper._();

  /// Characters used by the geohash base32 encoding.
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  /// Encode a lat/lng pair into a geohash string.
  ///
  /// [precision] 9 (~4.8m x 4.8m cells) matches what geoflutterfire used.
  static String encodeGeohash(double latitude, double longitude,
      {int precision = 9}) {
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    final StringBuffer hash = StringBuffer();
    bool isEvenBit = true;
    int bit = 0;
    int chIndex = 0;

    while (hash.length < precision) {
      if (isEvenBit) {
        final double mid = (lngMin + lngMax) / 2;
        if (longitude >= mid) {
          chIndex = (chIndex << 1) | 1;
          lngMin = mid;
        } else {
          chIndex = chIndex << 1;
          lngMax = mid;
        }
      } else {
        final double mid = (latMin + latMax) / 2;
        if (latitude >= mid) {
          chIndex = (chIndex << 1) | 1;
          latMin = mid;
        } else {
          chIndex = chIndex << 1;
          latMax = mid;
        }
      }
      isEvenBit = !isEvenBit;

      bit++;
      if (bit == 5) {
        hash.write(_base32[chIndex]);
        bit = 0;
        chIndex = 0;
      }
    }

    return hash.toString();
  }

  /// Build the geoflutterfire-compatible map stored in the USER_GEO_POINT
  /// field of the Users collection.
  static Map<String, dynamic> buildGeoPointData(double latitude,
      double longitude) {
    return <String, dynamic>{
      'geohash': encodeGeohash(latitude, longitude),
      'geopoint': GeoPoint(latitude, longitude),
    };
  }

  /// Great-circle distance between two coordinates (Haversine formula).
  /// Returns the distance in KILOMETERS.
  static double haversineDistanceKm(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLng = _degToRad(lng2 - lng1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Distance (KM) between two Firestore GeoPoints.
  static double distanceBetweenGeoPoints(GeoPoint a, GeoPoint b) {
    return haversineDistanceKm(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  /// Nearby filtering helper.
  ///
  /// Filters a list of user [DocumentSnapshot]s to the ones located within
  /// [radiusKm] of [center]. Every doc must contain the USER_GEO_POINT field
  /// (geoflutterfire format: geohash + geopoint).
  static List<DocumentSnapshot> filterNearbyUsers({
    required List<DocumentSnapshot> users,
    required GeoPoint center,
    required double radiusKm,
  }) {
    return users.where((userDoc) {
      final dynamic data = userDoc.data();
      if (data is! Map<String, dynamic>) return false;
      final dynamic geoField = data['user_geo_point'];
      if (geoField is! Map<String, dynamic>) return false;
      final dynamic geoPoint = geoField['geopoint'];
      if (geoPoint is! GeoPoint) return false;

      return haversineDistanceKm(
              center.latitude, center.longitude, geoPoint.latitude,
              geoPoint.longitude) <=
          radiusKm;
    }).toList();
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
}
