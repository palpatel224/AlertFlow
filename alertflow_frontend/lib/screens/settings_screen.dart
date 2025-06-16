import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  double _alertRadius = 50.0;
  final List<String> _availableDisasterTypes = [
    'earthquake',
    'cyclone',
    'hurricane',
    'flood',
    'fire',
    'tsunami',
  ];
  List<String> _selectedDisasterTypes = [];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() {
    final alertProvider = context.read<AlertProvider>();
    final user = alertProvider.currentUser;

    if (user != null) {
      setState(() {
        _notificationsEnabled = user.notificationsEnabled;
        _alertRadius = user.alertRadius;
        _selectedDisasterTypes = List.from(user.disasterTypes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoCard(alertProvider),
                const SizedBox(height: 16),
                _buildNotificationSettingsCard(),
                const SizedBox(height: 16),
                _buildDisasterTypesCard(),
                const SizedBox(height: 16),
                _buildLocationSettingsCard(),
                const SizedBox(height: 16),
                _buildAppInfoCard(),
                const SizedBox(height: 32),
                _buildSaveButton(alertProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(AlertProvider alertProvider) {
    final user = alertProvider.currentUser;
    final position = alertProvider.currentPosition;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (user != null) ...[
              _buildInfoRow('User ID', user.id),
              if (user.name != null) _buildInfoRow('Name', user.name!),
              if (user.email != null) _buildInfoRow('Email', user.email!),
              _buildInfoRow(
                'Last Seen',
                '${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year} '
                    '${user.lastSeen.hour}:${user.lastSeen.minute.toString().padLeft(2, '0')}',
              ),
            ],
            if (position != null) ...[
              _buildInfoRow(
                'Current Location',
                '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
              ),
              _buildInfoRow(
                'Location Accuracy',
                '±${position.accuracy.toStringAsFixed(1)}m',
              ),
            ] else ...[
              const Text(
                'Location not available',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: const Text('Receive alerts for disasters in your area'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisasterTypesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Alert Types',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the types of disasters you want to be notified about:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._availableDisasterTypes.map((type) => CheckboxListTile(
                  title: Text(type.toUpperCase()),
                  value: _selectedDisasterTypes.contains(type),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedDisasterTypes.add(type);
                      } else {
                        _selectedDisasterTypes.remove(type);
                      }
                    });
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Location Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Alert Radius: ${_alertRadius.toInt()} km',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _alertRadius,
              min: 10,
              max: 200,
              divisions: 19,
              label: '${_alertRadius.toInt()} km',
              onChanged: (value) {
                setState(() {
                  _alertRadius = value;
                });
              },
            ),
            const Text(
              'You will receive alerts for disasters within this radius of your location.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'App Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Data Source', 'USGS & Local Authorities'),
            _buildInfoRow('Last Updated', 'June 5, 2025'),
            const SizedBox(height: 16),
            const Text(
              'AlertFlow provides real-time disaster alerts to keep you safe. '
              'Location data is used only to send relevant alerts and is not shared with third parties.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(AlertProvider alertProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _saveSettings(alertProvider),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Save Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Future<void> _saveSettings(AlertProvider alertProvider) async {
    try {
      await alertProvider.updateNotificationPreferences(
        notificationsEnabled: _notificationsEnabled,
        disasterTypes: _selectedDisasterTypes,
        alertRadius: _alertRadius,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
