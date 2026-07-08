import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:women_safety_health_app/app_theme.dart';

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({super.key});

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _loading = true;
  String _status = 'Getting your location...';
  Set<Marker> _markers = {};
  final List<_NearbyPlace> _nearbyPlaces = [];
  bool _showingPlaces = false;
  String _activeFilter = 'All';

  final _db = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

  // Hardcoded nearby places in Solapur, Maharashtra
  static final List<_NearbyPlace> _solapurPlaces = [
    _NearbyPlace(
      name: 'Civil Hospital Solapur',
      type: 'hospital',
      emoji: '🏥',
      lat: 17.6869,
      lng: 75.9009,
      address: 'Solapur Central, Solapur, MH',
      phone: '0217-2726600',
    ),
    _NearbyPlace(
      name: 'Siddhivinayak Hospital',
      type: 'hospital',
      emoji: '🏥',
      lat: 17.6900,
      lng: 75.9100,
      address: 'Siddhivinayak Nagar, Solapur',
      phone: '0217-2345678',
    ),
    _NearbyPlace(
      name: 'Deenanath Mangeshkar Hospital',
      type: 'hospital',
      emoji: '🏥',
      lat: 17.6820,
      lng: 75.8950,
      address: 'Mangeshkar Rd, Solapur',
      phone: '0217-2345000',
    ),
    _NearbyPlace(
      name: 'Solapur City Police HQ',
      type: 'police',
      emoji: '🚔',
      lat: 17.6854,
      lng: 75.9064,
      address: 'Police HQ, Solapur City, MH',
      phone: '100',
    ),
    _NearbyPlace(
      name: 'Solapur Rural Police Station',
      type: 'police',
      emoji: '🚔',
      lat: 17.6780,
      lng: 75.9130,
      address: 'Rural Police Station, Solapur',
      phone: '100',
    ),
    _NearbyPlace(
      name: 'Women Police Station',
      type: 'police',
      emoji: '👮',
      lat: 17.6910,
      lng: 75.8990,
      address: 'Women PS, Gandhi Nagar, Solapur',
      phone: '1091',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() { _loading = true; _status = 'Requesting permission...'; });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _loading = false;
            _status = 'Location permission denied';
          });
          return;
        }
      }

      setState(() => _status = 'Getting GPS fix...');

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = pos;
        _loading = false;
        _status = 'Location found ✓';
        _markers = {
          Marker(
            markerId: const MarkerId('me'),
            position: LatLng(pos.latitude, pos.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRose),
            infoWindow: const InfoWindow(title: 'You are here 📍'),
          ),
        };
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(pos.latitude, pos.longitude), 14),
      );

      // Save to Firestore
      await _db.collection('users').doc(_uid)
          .collection('location').doc('current').set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      setState(() {
        _loading = false;
        _status = 'Error: $e';
      });
    }
  }

  void _showNearbyPlaces(String filter) {
    setState(() {
      _activeFilter = filter;
      _nearbyPlaces.clear();
      _showingPlaces = true;
    });

    final filtered = filter == 'All'
        ? _solapurPlaces
        : _solapurPlaces.where((p) => p.type == filter.toLowerCase()).toList();

    final Set<Marker> newMarkers = {
      if (_currentPosition != null)
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(
              _currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRose),
          infoWindow: const InfoWindow(title: 'You 📍'),
        ),
    };

    for (final place in filtered) {
      // Calculate distance
      double dist = 0;
      if (_currentPosition != null) {
        dist = _calcDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          place.lat,
          place.lng,
        );
      }

      final p = _NearbyPlace(
        name: place.name,
        type: place.type,
        emoji: place.emoji,
        lat: place.lat,
        lng: place.lng,
        address: place.address,
        phone: place.phone,
        distanceKm: dist,
      );

      _nearbyPlaces.add(p);

      newMarkers.add(Marker(
        markerId: MarkerId(place.name),
        position: LatLng(place.lat, place.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          place.type == 'hospital'
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueBlue,
        ),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: '${dist.toStringAsFixed(1)} km away',
        ),
      ));
    }

    _nearbyPlaces.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    setState(() => _markers = newMarkers);

    if (filtered.isNotEmpty) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
            LatLng(filtered[0].lat, filtered[0].lng), 13),
      );
    }
  }

  double _calcDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          _currentPosition != null
              ? GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentPosition!.latitude,
                  _currentPosition!.longitude),
              zoom: 14,
            ),
            markers: _markers,
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          )
              : Container(
            color: AppTheme.blush,
            child: Center(
              child: _loading
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: AppTheme.rose),
                  const SizedBox(height: 16),
                  Text(_status, style: AppTheme.body(14)),
                ],
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📍',
                      style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(_status, style: AppTheme.body(15)),
                  const SizedBox(height: 20),
                  HerButton(
                    label: 'Retry',
                    onTap: _getCurrentLocation,
                    fullWidth: false,
                  ),
                ],
              ),
            ),
          ),

          // Top bar
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const Spacer(),
                _buildBottomSheet(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppTheme.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppTheme.rose, size: 16),
                  const SizedBox(width: 6),
                  Text('Solapur, Maharashtra',
                      style: AppTheme.label(13, color: AppTheme.textDark)),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: AppTheme.rose, strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF3CC98A), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.roseGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow(AppTheme.rose),
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1AE8587A),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.rosePale,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Find Nearby',
                    style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                const SizedBox(height: 12),
                // Filter buttons
                Row(
                  children: [
                    _FilterBtn(
                      label: '🏥 Hospitals',
                      active: _activeFilter == 'Hospital',
                      onTap: () => _showNearbyPlaces('Hospital'),
                    ),
                    const SizedBox(width: 10),
                    _FilterBtn(
                      label: '🚔 Police',
                      active: _activeFilter == 'Police',
                      onTap: () => _showNearbyPlaces('Police'),
                    ),
                    const SizedBox(width: 10),
                    _FilterBtn(
                      label: '📍 All',
                      active: _activeFilter == 'All' && _showingPlaces,
                      onTap: () => _showNearbyPlaces('All'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_showingPlaces && _nearbyPlaces.isNotEmpty)
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _nearbyPlaces.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) =>
                          _PlaceCard(place: _nearbyPlaces[i]),
                    ),
                  )
                else if (!_showingPlaces)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                          'Tap above to find nearby hospitals & police stations',
                          style: AppTheme.body(13),
                          textAlign: TextAlign.center),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.roseGradient : null,
          color: active ? null : AppTheme.blush,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppTheme.rose : AppTheme.rosePale,
          ),
        ),
        child: Text(label,
            style: AppTheme.label(12,
                color: active ? Colors.white : AppTheme.textMid)),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final _NearbyPlace place;
  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: AppTheme.cardDecoration(radius: 18),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(place.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(place.name,
                    style: AppTheme.label(12, color: AppTheme.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(place.address,
              style: AppTheme.body(10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.rosePale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${place.distanceKm.toStringAsFixed(1)} km',
                  style: AppTheme.label(10, color: AppTheme.rose),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('tel:${place.phone}')),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.roseGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.call_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NearbyPlace {
  final String name;
  final String type;
  final String emoji;
  final double lat;
  final double lng;
  final String address;
  final String phone;
  final double distanceKm;

  const _NearbyPlace({
    required this.name,
    required this.type,
    required this.emoji,
    required this.lat,
    required this.lng,
    required this.address,
    required this.phone,
    this.distanceKm = 0,
  });
}