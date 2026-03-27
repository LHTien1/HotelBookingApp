import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ cần thêm

class LocationMap extends StatefulWidget {
  final GeoPoint location;
  final String hotelName;

  /// true = cho zoom/drag trên map; false = map tĩnh (đỡ kẹt scroll)
  final bool interactive;

  /// chiều cao map
  final double height;

  const LocationMap({
    super.key,
    required this.location,
    required this.hotelName,
    this.interactive = false,
    this.height = 250,
  });

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  GoogleMapController? _mapController;

  LatLng get _center => LatLng(widget.location.latitude, widget.location.longitude);

  Set<Marker> get _markers => {
    Marker(
      markerId: MarkerId(widget.hotelName),
      position: _center,
      infoWindow: InfoWindow(title: widget.hotelName),
    ),
  };

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _openInGoogleMaps() async {
    final lat = widget.location.latitude;
    final lng = widget.location.longitude;

    // Android/iOS đều dùng được
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở Google Maps')),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              markers: _markers,

              // ✅ chống kẹt scroll khi nằm trong ListView/SingleChildScrollView
              scrollGesturesEnabled: widget.interactive,
              zoomGesturesEnabled: widget.interactive,
              rotateGesturesEnabled: widget.interactive,
              tiltGesturesEnabled: widget.interactive,

              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),

            // ✅ nút mở Google Maps (chuẩn mobile)
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: cs.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _openInGoogleMaps,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions, size: 18, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Mở bản đồ',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
