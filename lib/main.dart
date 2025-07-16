import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'dart:async';

void main() {
  runApp(const HealthAppDemo());
}

class HealthAppDemo extends StatelessWidget {
  const HealthAppDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Package Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const HealthDataScreen(),
    );
  }
}

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  _HealthDataScreenState createState() => _HealthDataScreenState();
}

enum AppState {
  // Initial state, no data fetched.
  IDLE,
  // Authorization has not been granted by the user.
  AUTH_NOT_GRANTED,
  // Fetching data from the health service.
  FETCHING_DATA,
  // Data has been successfully fetched.
  DATA_READY,
  // An error occurred during the process.
  ERROR,
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.IDLE;

  // Create a Health instance for interacting with the health data.
  final Health _health = Health();

  /// Define the types of data we want to fetch.
  static const types = [
    HealthDataType.STEPS,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.WORKOUT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];

  /// Define the permissions that are required to access the data.
  final permissions = types.map((e) => HealthDataAccess.READ).toList();

  /// Request authorization from the user to access the health data.
  Future<void> authorize() async {
    setState(() => _state = AppState.FETCHING_DATA);

    try {
      // Check if we have permission already.
      bool? hasPermissions = await _health.hasPermissions(types, permissions: permissions);

      // If not, request authorization.
      if (hasPermissions == false) {
        bool requested = await _health.requestAuthorization(types, permissions: permissions);
        if (!requested) {
          setState(() => _state = AppState.AUTH_NOT_GRANTED);
          return;
        }
      }
      // If we have permissions, fetch the data.
      fetchData();
    } catch (e) {
      debugPrint("Exception in authorize: $e");
      setState(() => _state = AppState.ERROR);
    }
  }

  /// Fetch health data for the last 24 hours.
  Future<void> fetchData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    // Clear any previous data.
    _healthDataList.clear();

    try {
      // Fetch health data from the platform using named parameters.
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
          startTime: yesterday, endTime: now, types: types);

      // Filter out duplicates and data points with no value.
      _healthDataList.addAll((healthData.isEmpty)
          ? []
          : Health().removeDuplicates(healthData));
    } catch (error) {
      debugPrint("Exception in getHealthDataFromTypes: $error");
      setState(() => _state = AppState.ERROR);
      return;
    }

    // Update the UI to reflect that the data is ready.
    setState(() {
      _state = _healthDataList.isEmpty ? AppState.IDLE : AppState.DATA_READY;
    });
  }

  Widget _buildAuthButton() {
    return ElevatedButton(
      onPressed: authorize,
      child: const Text('Authorize and Fetch Data'),
    );
  }

  Widget _buildDataList() {
    if (_healthDataList.isEmpty) {
      return const Text('No data available for the last 24 hours.');
    }
    return ListView.builder(
      itemCount: _healthDataList.length,
      itemBuilder: (_, index) {
        HealthDataPoint p = _healthDataList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 2,
          child: ListTile(
            title: Text("${p.typeString}: ${p.value}", style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text(p.unitString ?? ''),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
          ),
        );
      },
    );
  }

  Widget _buildUI() {
    switch (_state) {
      case AppState.IDLE:
        return _buildAuthButton();
      case AppState.AUTH_NOT_GRANTED:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Authorization not granted. Please grant permissions to use this feature.'),
            const SizedBox(height: 16),
            _buildAuthButton(),
          ],
        );
      case AppState.FETCHING_DATA:
        return const Center(child: CircularProgressIndicator());
      case AppState.DATA_READY:
        return Column(
          children: [
            const Text('Data from the last 24 hours:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(child: _buildDataList()),
          ],
        );
      case AppState.ERROR:
        return const Center(child: Text('An error occurred. Please try again.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Package Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _buildUI(),
        ),
      ),
    );
  }
}
