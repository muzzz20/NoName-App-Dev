import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';

/// Interactive map for the Submit Report screen.
///
/// Behavior:
/// - Shows a Maroon pin at [point] (if non-null).
/// - Tapping anywhere on the tiles moves the pin and calls [onChanged].
/// - Defaults the viewport to UTM JB campus when [point] is null.
/// - Uses OpenStreetMap raster tiles — no API key required.
///
/// Width fills parent; height is fixed at 220pt (good balance for
/// portrait phones without crowding other form fields).
class MapPicker extends StatefulWidget {
  final GeoPoint? point;
  final ValueChanged<GeoPoint> onChanged;

  const MapPicker({super.key, required this.point, required this.onChanged});

  /// UTM JB main campus — used as default viewport center.
  static const LatLng utmCampus = LatLng(1.5599, 103.6418);

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  final _controller = MapController();

  LatLng get _center => widget.point == null
      ? MapPicker.utmCampus
      : LatLng(widget.point!.latitude, widget.point!.longitude);

  @override
  void didUpdateWidget(MapPicker old) {
    super.didUpdateWidget(old);
    // If parent updates point externally (e.g. GPS detect), recenter the map.
    if (widget.point != null && widget.point != old.point) {
      _controller.move(_center, _controller.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              minZoom: 12,
              maxZoom: 19,
              onTap: (tapPos, latLng) {
                widget.onChanged(GeoPoint(latLng.latitude, latLng.longitude));
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.doubleTapDragZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'my.utm.strayfriends',
                maxNativeZoom: 19,
              ),
              if (widget.point != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.point == null
              ? 'Tap anywhere on the map to set the location.'
              : 'Tap to refine. Pin is at '
                  '${widget.point!.latitude.toStringAsFixed(5)}, '
                  '${widget.point!.longitude.toStringAsFixed(5)}.',
          style: AppText.labelCaps.copyWith(color: AppColors.outline),
        ),
      ],
    );
  }
}
