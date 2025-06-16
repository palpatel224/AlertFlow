import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../providers/alert_provider.dart';

class AlertDetailScreen extends StatelessWidget {
  final AlertModel alert;

  const AlertDetailScreen({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(alert.disasterType.toUpperCase()),
        backgroundColor: alert.severityColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareAlert(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildLocationCard(context),
            const SizedBox(height: 16),
            _buildTimeCard(),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildSafetyCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alert.disasterIcon,
                  size: 32,
                  color: alert.severityColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.disasterType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              alert.location,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (alert.magnitude != 'Unknown') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Magnitude: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    alert.magnitude,
                    style: TextStyle(
                      fontSize: 16,
                      color: alert.severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    final alertProvider = context.read<AlertProvider>();
    final distance = alertProvider.getDistanceToAlert(alert);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Location Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Location', alert.location),
            if (alert.latitude != null && alert.longitude != null) ...[
              _buildInfoRow(
                'Coordinates',
                '${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}',
              ),
            ],
            if (distance != null) ...[
              _buildInfoRow(
                'Distance from you',
                '${distance.toStringAsFixed(1)} km',
              ),
            ],
            const SizedBox(height: 12),
            if (alert.latitude != null && alert.longitude != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openInMaps(context),
                  icon: const Icon(Icons.map),
                  label: const Text('View on Map'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Time Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Date', alert.date),
            _buildInfoRow('Time', alert.time),
            _buildInfoRow(
              'Reported',
              DateFormat('MMM dd, yyyy - HH:mm').format(alert.createdAt),
            ),
            _buildInfoRow(
              'Expires',
              DateFormat('MMM dd, yyyy - HH:mm').format(alert.expiresAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Alert Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Alert ID', alert.id),
            _buildInfoRow('Source', alert.source),
            _buildInfoRow('Status', alert.isActive ? 'Active' : 'Inactive'),
            _buildInfoRow(
              'Notification Sent',
              alert.notificationSent ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  'Safety Guidelines',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._getSafetyGuidelines().map((guideline) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          guideline,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  List<String> _getSafetyGuidelines() {
    switch (alert.disasterType.toLowerCase()) {
      case 'earthquake':
        return [
          'Drop, Cover, and Hold On if shaking starts',
          'Stay away from windows and heavy objects',
          'If outdoors, stay away from buildings and power lines',
          'After shaking stops, check for injuries and hazards',
          'Be prepared for aftershocks',
        ];
      case 'cyclone':
      case 'hurricane':
        return [
          'Stay indoors and away from windows',
          'Have emergency supplies ready',
          'Follow evacuation orders if issued',
          'Avoid driving through flood waters',
          'Stay informed through official channels',
        ];
      case 'flood':
        return [
          'Move to higher ground immediately',
          'Avoid walking or driving through flood waters',
          'Stay away from downed power lines',
          'Listen to emergency broadcasts',
          'Do not return until authorities say it\'s safe',
        ];
      default:
        return [
          'Follow instructions from local authorities',
          'Stay informed through official sources',
          'Have emergency supplies ready',
          'Avoid the affected area',
          'Help others if safe to do so',
        ];
    }
  }

  void _shareAlert(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _openInMaps(BuildContext context) {
    // TODO: Implement open in maps functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map functionality coming soon')),
    );
  }
}
