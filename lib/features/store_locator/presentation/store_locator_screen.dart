import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'store_data.dart';

class StoreLocatorScreen extends StatefulWidget {
  const StoreLocatorScreen({super.key});

  @override
  State<StoreLocatorScreen> createState() => _StoreLocatorScreenState();
}

class _StoreLocatorScreenState extends State<StoreLocatorScreen> {
  double _radiusKm = 5;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    const initial = LatLng(-6.200000, 106.816666);
    final filtered = stores.where((s) {
      final inRadius = _distanceKm(initial.latitude, initial.longitude, s.lat, s.lng) <= _radiusKm;
      final matchQuery = _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase());
      return inRadius && matchQuery;
    }).toList();

    final markers = filtered
        .map(
          (s) => Marker(
            markerId: MarkerId(s.id),
            position: LatLng(s.lat, s.lng),
            infoWindow: InfoWindow(title: s.name),
          ),
        )
        .toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Store Locator')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(target: initial, zoom: 14),
              markers: markers,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search store...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                Text('Radius ${_radiusKm.toStringAsFixed(0)} km'),
                Slider(
                  value: _radiusKm,
                  min: 2,
                  max: 10,
                  divisions: 4,
                  label: '${_radiusKm.toStringAsFixed(0)} km',
                  onChanged: (v) => setState(() => _radiusKm = v),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: filtered.isEmpty
                  ? const [
                      ListTile(
                        title: Text('No stores in range'),
                        subtitle: Text('Try increasing the radius'),
                      ),
                    ]
                  : filtered
                  .map(
                    (s) => ListTile(
                      title: Text(s.name),
                      subtitle: Text(s.address),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/stores/${s.id}'),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earth * c;
}

double _deg2rad(double deg) => deg * (3.1415926535897932 / 180);
