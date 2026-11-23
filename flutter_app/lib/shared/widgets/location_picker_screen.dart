import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/models/order.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/maps_service.dart';

/// Full-screen location picker.
/// Returns a [GeoPointLocation] when the user confirms, or null if cancelled.
class LocationPickerScreen extends ConsumerStatefulWidget {
  final String title;
  final GeoPointLocation? initial;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initial,
  });

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  Timer? _debounce;

  LatLng _pin = const LatLng(-17.8292, 31.0522); // default: Harare
  String _address = 'Harare, Zimbabwe';
  bool _reverseGeocoding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _pin = LatLng(widget.initial!.lat, widget.initial!.lng);
      _address = widget.initial!.address;
      _searchCtrl.text = _address;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Search autocomplete ────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final maps = ref.read(mapsServiceProvider);
      final results = await maps.autocompletePlaces(query);
      if (mounted) setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _searchFocus.unfocus();
    setState(() {
      _suggestions = [];
      _isSearching = true;
      _searchCtrl.text = suggestion.description;
    });

    final maps = ref.read(mapsServiceProvider);
    final place = await maps.getPlaceDetails(suggestion.placeId);
    if (!mounted) return;

    if (place != null) {
      final latLng = LatLng(place.lat, place.lng);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 14),
      );
      setState(() {
        _pin = latLng;
        _address = place.address;
        _searchCtrl.text = place.address;
        _isSearching = false;
      });
    } else {
      setState(() => _isSearching = false);
    }
  }

  // ── Map interactions ───────────────────────────────────────────────────────

  Future<void> _onMapTap(LatLng pos) async {
    setState(() {
      _pin = pos;
      _reverseGeocoding = true;
      _suggestions = [];
    });
    _searchFocus.unfocus();

    // Try reverse geocode via Place Details isn't available from lat/lng directly;
    // use Geocoding API if key present, otherwise format coordinates
    final maps = ref.read(mapsServiceProvider);
    if (maps.hasApiKey) {
      try {
        final uri = Uri.https(
          'maps.googleapis.com',
          '/maps/api/geocode/json',
          {
            'latlng': '${pos.latitude},${pos.longitude}',
            'key': MapsService.apiKey,
          },
        );
        final res = await maps.httpGet(uri);
        if (res != null && mounted) {
          setState(() {
            _address = res;
            _searchCtrl.text = res;
          });
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        if (_address == _address) {
          _address =
              '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
          _searchCtrl.text = _address;
        }
        _reverseGeocoding = false;
      });
    }
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return;
    }
    if (perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    final latLng = LatLng(pos.latitude, pos.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    await _onMapTap(latLng);
  }

  void _confirm() {
    Navigator.of(context).pop(
      GeoPointLocation(
        address: _address,
        lat: _pin.latitude,
        lng: _pin.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _pin, zoom: 12),
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('pin'),
                position: _pin,
                draggable: true,
                onDragEnd: _onMapTap,
              ),
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // ── Top search bar ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(14),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search location…',
                        prefixIcon: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _suggestions = []);
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  // Suggestions dropdown
                  if (_suggestions.isNotEmpty)
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final s = _suggestions[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined,
                                size: 20),
                            title: Text(s.description,
                                style: const TextStyle(fontSize: 13)),
                            onTap: () => _selectSuggestion(s),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── My location FAB ───────────────────────────────────────────
          Positioned(
            right: 12,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'my_loc',
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // ── Bottom confirm bar ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _reverseGeocoding
                            ? const Text('Getting address…',
                                style: TextStyle(color: Colors.grey))
                            : Text(
                                _address,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _reverseGeocoding ? null : _confirm,
                      icon: const Icon(Icons.check),
                      label: Text('Confirm – ${widget.title}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
