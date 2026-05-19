import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Static (non-interactive) map for the Report Detail screen.
///
/// Renders a single pin at [point]. Pinch / drag / tap are disabled —
/// this is read-only context, not an editor. Caller can pass an optional
/// [height] override (default 160pt).
class StaticMap extends StatelessWidget {
  final GeoPoint point;
  final double height;

  const StaticMap({super.key, required this.point, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final latLng = LatLng(point.latitude, point.longitude);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: latLng,
          initialZoom: 16,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'my.utm.strayfriends',
            maxNativeZoom: 19,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: latLng,
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
    );
  }
}
