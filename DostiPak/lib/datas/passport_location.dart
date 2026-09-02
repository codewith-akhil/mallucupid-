/// PassportLocation
///
/// Simple value object returned by the PassportScreen (on-device geocoding
/// search, no Google Maps API key required). It replaces the old
/// `place_picker` LocationResult object.
class PassportLocation {
  final String country;
  final String locality;
  final double latitude;
  final double longitude;

  const PassportLocation({
    required this.country,
    required this.locality,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'country': country,
      'locality': locality,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() =>
      'PassportLocation(country: $country, locality: $locality, '
      'lat: $latitude, lng: $longitude)';
}
