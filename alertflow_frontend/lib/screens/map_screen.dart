import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';
import '../screens/alert_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);

    // Get user location
    if (alertProvider.userLatitude != null &&
        alertProvider.userLongitude != null) {
      _userLocation =
          LatLng(alertProvider.userLatitude!, alertProvider.userLongitude!);
    }

    _updateMarkers();
  }

  void _updateMarkers() {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    final alerts = alertProvider.alerts;

    Set<Marker> markers = {};
    Set<Circle> circles = {};

    // Add user location marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
        ),
      );

      // Add user radius circle
      circles.add(
        Circle(
          circleId: const CircleId('user_radius'),
          center: _userLocation!,
          radius: alertProvider.alertRadius * 1000, // Convert km to meters
          fillColor: Colors.blue.withValues(alpha: 0.1),
          strokeColor: Colors.blue.withValues(alpha: 0.5),
          strokeWidth: 2,
        ),
      );
    }

    // Add alert markers
    for (final alert in alerts) {
      if (alert.latitude != null && alert.longitude != null) {
        final alertPosition = LatLng(alert.latitude!, alert.longitude!);

        markers.add(
          Marker(
            markerId: MarkerId(alert.id),
            position: alertPosition,
            icon: _getMarkerIcon(alert.severity),
            infoWindow: InfoWindow(
              title: alert.disasterType,
              snippet: '\${alert.severity.toUpperCase()} - \${alert.location}',
            ),
            onTap: () => _showAlertBottomSheet(alert),
          ),
        );

        // Add alert radius circle
        circles.add(
          Circle(
            circleId: CircleId('alert_\${alert.id}'),
            center: alertPosition,
            radius:
                _getAlertRadius(alert.severity) * 1000, // Convert km to meters
            fillColor: alert.severityColor.withValues(alpha: 0.1),
            strokeColor: alert.severityColor.withValues(alpha: 0.5),
            strokeWidth: 2,
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
      _circles = circles;
    });
  }

  BitmapDescriptor _getMarkerIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      case 'moderate':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange);
      case 'major':
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      case 'critical':
        return BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet);
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }

  double _getAlertRadius(String severity) {
    switch (severity.toLowerCase()) {
      case 'minor':
        return 10.0;
      case 'moderate':
        return 25.0;
      case 'major':
        return 50.0;
      case 'critical':
        return 100.0;
      default:
        return 20.0;
    }
  }

  void _showAlertBottomSheet(AlertModel alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Alert preview
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: alert.severityColor,
                              borderRadius: BorderRadius.circular(16),
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
                          const SizedBox(width: 12),
                          Icon(alert.disasterIcon, color: alert.severityColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.disasterType,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              alert.location,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Description
                      Text(
                        alert.description ?? 'No description available',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AlertDetailScreen(alert: alert),
                                  ),
                                );
                              },
                              child: const Text('View Details'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;

    // Move camera to user location or default location
    if (_userLocation != null) {
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 10.0),
      );
    } else {
      // Default to center of US
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(const LatLng(39.8283, -98.5795), 4.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, child) {
          // Update markers when alerts change
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMarkers();
          });

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _userLocation ?? const LatLng(39.8283, -98.5795),
                  zoom: _userLocation != null ? 10.0 : 4.0,
                ),
                markers: _markers,
                circles: _circles,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
              ),

              // Legend
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Alert Severity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildLegendItem('Minor', Colors.blue),
                      _buildLegendItem('Moderate', Colors.orange),
                      _buildLegendItem('Major', Colors.red),
                      _buildLegendItem('Critical', Colors.purple),
                    ],
                  ),
                ),
              ),

              // Statistics overlay
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total Alerts',
                        alertProvider.alerts.length.toString(),
                        Icons.notifications,
                        Colors.grey[600]!,
                      ),
                      _buildStatItem(
                        'Nearby',
                        alertProvider.nearbyAlerts.length.toString(),
                        Icons.location_on,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'Critical',
                        alertProvider.criticalAlerts.length.toString(),
                        Icons.warning,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
