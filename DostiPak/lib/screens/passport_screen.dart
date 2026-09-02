import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rishtpak/datas/passport_location.dart';
import 'package:rishtpak/helpers/app_localizations.dart';

/// PassportScreen
///
/// Travel to any country or city and match with people there.
///
/// The search is done fully ON-DEVICE with the `geocoding` package
/// (forward geocoding of the search text) - no Google Maps API key required.
///
/// geocoding 3.x notes:
///  - [locationFromAddress] returns [Location] results (lat/lng),
///  - [Placemark] has no position anymore, therefore the results are kept as
///    two lists paired BY INDEX: [Location] <-> [Placemark].
///    [_selectPlace] uses the Location lat/lng for the PassportLocation result.
class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  // Variables
  final TextEditingController _searchController = TextEditingController();

  /// Search results: Location and Placemark lists are PAIRED BY INDEX.
  final List<Location> _locations = <Location>[];
  final List<Placemark> _placemarks = <Placemark>[];

  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;

  late AppLocalizations _i18n;

  /// Forward geocode the search text (on-device platform channel call).
  Future<void> _searchPlaces(String searchText) async {
    final String query = searchText.trim();
    if (query.length < 3) {
      if (mounted) {
        setState(() {
          _error = 'Type at least 3 characters to search.';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
        _error = null;
        _hasSearched = false;
        _locations.clear();
        _placemarks.clear();
      });
    }

    try {
      /// 1.) Forward geocoding: search text -> List<Location>
      final List<Location> locations = await locationFromAddress(query);

      /// 2.) Reverse geocode every Location to get its Placemark.
      ///     Keep both lists paired by index.
      final List<Location> validLocations = <Location>[];
      final List<Placemark> validPlacemarks = <Placemark>[];

      for (final Location location in locations.take(10)) {
        final double? lat = location.latitude;
        final double? lng = location.longitude;
        if (lat == null || lng == null) continue;

        try {
          final List<Placemark> marks =
              await placemarkFromCoordinates(lat, lng);
          validLocations.add(location);
          validPlacemarks
              .add(marks.isNotEmpty ? marks.first : Placemark());
        } catch (_) {
          // Keep the location even if reverse geocoding fails.
          validLocations.add(location);
          validPlacemarks.add(Placemark());
        }
      }

      if (mounted) {
        setState(() {
          _locations.addAll(validLocations);
          _placemarks.addAll(validPlacemarks);
          _isSearching = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _hasSearched = true;
          _error = 'No results found. Please try a different search.';
        });
      }
    }
  }

  /// Select a result row - the Location lat/lng is used for the result.
  void _selectPlace(int index) {
    final Location location = _locations[index];
    final Placemark place = _placemarks[index];

    final double? lat = location.latitude;
    final double? lng = location.longitude;
    if (lat == null || lng == null) return;

    final String country = place.country ?? '';
    final String locality = (place.locality != null && place.locality!.isNotEmpty)
        ? place.locality!
        : (place.administrativeArea ?? place.subAdministrativeArea ?? '');

    final PassportLocation result = PassportLocation(
      country: country,
      locality: locality,
      latitude: lat,
      longitude: lng,
    );

    // Return the selected place to the caller (settings screen).
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_i18n.translate('travel_to_any_country_or_city')),
      ),
      body: Column(
        children: [
          /// Search box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _searchPlaces,
              decoration: InputDecoration(
                hintText: 'Search for a country or city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.flight_takeoff),
                  onPressed: () => _searchPlaces(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),

          /// Search state
          Expanded(
            child: _buildResultList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Finding place...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    if (_locations.isEmpty) {
      return Center(
        child: Text(
          _hasSearched
              ? 'No results found.'
              : 'Search for any country or city\nand travel there for free.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      itemCount: _locations.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final Placemark place = _placemarks[index];
        final String title = _placeTitle(place, index);
        final String subtitle = _placeSubtitle(place);

        return ListTile(
          leading: const Icon(Icons.location_on_outlined),
          title: Text(title),
          subtitle: subtitle.isEmpty ? null : Text(subtitle),
          trailing: const Icon(Icons.check_circle_outline),
          onTap: () => _selectPlace(index),
        );
      },
    );
  }

  String _placeTitle(Placemark place, int index) {
    final String locality =
        place.locality ?? place.administrativeArea ?? place.subAdministrativeArea ?? '';
    if (locality.isNotEmpty) return locality;
    if ((place.country ?? '').isNotEmpty) return place.country!;
    return 'Unnamed location ${index + 1}';
  }

  String _placeSubtitle(Placemark place) {
    final List<String> parts = <String>[
      place.administrativeArea ?? '',
      place.country ?? '',
    ];
    return parts.where((String part) => part.isNotEmpty).join(', ');
  }
}
