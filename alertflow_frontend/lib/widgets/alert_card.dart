import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../screens/alert_detail_screen.dart';

class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final double? userLatitude;
  final double? userLongitude;
  final double? distance;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.alert,
    this.userLatitude,
    this.userLongitude,
    this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final calculatedDistance = distance ??
        ((userLatitude != null && userLongitude != null)
            ? alert.calculateDistance(userLatitude!, userLongitude!)
            : null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlertDetailScreen(alert: alert),
                ),
              );
            },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with severity indicator and disaster type
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: alert.severityColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert.severity.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    alert.disasterIcon,
                    color: alert.severityColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.disasterType,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (calculatedDistance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${calculatedDistance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Location and magnitude/intensity
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      alert.location,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (alert.magnitude.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.waves, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Magnitude ${alert.magnitude}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],

              if (alert.depth != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.vertical_align_bottom,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Depth: ${alert.depth} km',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Description
              if (alert.description?.isNotEmpty == true)
                Text(
                  alert.description!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        alert.formattedTime,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
