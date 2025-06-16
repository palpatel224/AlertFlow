import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../models/alert_model.dart';
import '../widgets/alert_card.dart';
import 'alert_detail_screen.dart';
import 'settings_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Schedule initialization after the current build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeProviders();
      });
      _initialized = true;
    }
  }

  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);

    // Set current user in alert provider
    if (authProvider.userProfile != null) {
      alertProvider.setCurrentUser(authProvider.userProfile);
    }

    // Initialize alert provider if not already done
    if (!alertProvider.isLoading && alertProvider.alerts.isEmpty) {
      await alertProvider.initialize();
    }

    // Initialize location and FCM with context for permission dialogs
    if (authProvider.userProfile != null && mounted) {
      await authProvider.initializeLocationAndFCM(context: context);
    }
  }

  Future<void> _requestLocationPermission() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userProfile != null) {
      await authProvider.initializeLocationAndFCM(context: context);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AlertFlow',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.warning), text: 'All Alerts'),
            Tab(icon: Icon(Icons.near_me), text: 'Nearby'),
            Tab(icon: Icon(Icons.priority_high), text: 'Critical'),
          ],
        ),
      ),
      body: Consumer<AlertProvider>(
        builder: (context, alertProvider, child) {
          return Column(
            children: [
              // Location permission banner
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.userProfile != null &&
                      (authProvider.userProfile!.latitude == null ||
                          authProvider.userProfile!.longitude == null)) {
                    return Container(
                      width: double.infinity,
                      color: Colors.orange.shade100,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.location_off,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enable location to get nearby alerts',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                          TextButton(
                            onPressed: _requestLocationPermission,
                            child: const Text('Enable'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Main content
              Expanded(
                child: _buildMainContent(alertProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<AlertProvider>().refreshAlerts();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildMainContent(AlertProvider alertProvider) {
    if (alertProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading alerts...'),
          ],
        ),
      );
    }

    if (alertProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${alertProvider.error}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                alertProvider.refreshAlerts();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildAlertsList(alertProvider.alerts, 'all'),
        _buildAlertsList(alertProvider.nearbyAlerts, 'nearby'),
        _buildAlertsList(alertProvider.criticalAlerts, 'critical'),
      ],
    );
  }

  Widget _buildAlertsList(List<AlertModel> alerts, String type) {
    if (alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'critical'
                  ? Icons.shield_outlined
                  : type == 'nearby'
                      ? Icons.near_me_outlined
                      : Icons.notifications_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              type == 'critical'
                  ? 'No critical alerts'
                  : type == 'nearby'
                      ? 'No nearby alerts'
                      : 'No alerts available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'critical'
                  ? 'Great! No critical emergencies in your area.'
                  : type == 'nearby'
                      ? 'Enable location to see nearby alerts.'
                      : 'All clear! No active disaster alerts.',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final alertProvider =
            Provider.of<AlertProvider>(context, listen: false);
        await alertProvider.refreshAlerts();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return AlertCard(
            alert: alert,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlertDetailScreen(alert: alert),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
