import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

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
  // A new state to indicate when no data is found.
  NO_DATA,
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
  bool _isInitializing = false; // Flag to prevent re-entrant calls

  @override
  void initState() {
    super.initState();
    // Kick off the initialization process
    _initAndFetch();
  }

  /// Combined initialization method.
  Future<void> _initAndFetch() async {
    // Prevent this function from running multiple times simultaneously.
    if (_isInitializing) {
      debugPrint("Initialization already in progress, skipping.");
      return;
    }

    setState(() {
      _isInitializing = true;
    });

    try {
      await requestPermissions();
      // Authorize and fetch data if authorization is successful.
      final isAuthorized = await authorize();
      if (isAuthorized) {
        await fetchData();
      }
    } finally {
      // Ensure the flag is reset, even if an error occurs.
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  /// Request standard Android runtime permissions.
  Future<void> requestPermissions() async {
    await Permission.activityRecognition.request();
    // Add other permissions from permission_handler if needed
  }

  // Create a Health instance for interacting with the health data.
  final Health _health = Health();

  /// Define the types of data we want to fetch.
  static const types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
  ];

  /// Define the permissions that are required to access the data.
  final permissions = types.map((e) => HealthDataAccess.READ).toList();

  /// Request authorization from the user to access the health data.
  /// Returns true if successful, false otherwise.
  Future<bool> authorize() async {
    setState(() => _state = AppState.FETCHING_DATA);

    try {
      debugPrint("1. Checking for Health Connect permissions...");
      bool? hasPermissions = await _health.hasPermissions(types, permissions: permissions);
      debugPrint("2. hasPermissions check returned: $hasPermissions");

      if (hasPermissions == false) {
        debugPrint("3. Permissions not found, requesting Health Connect authorization...");
        bool requested = await _health.requestAuthorization(types, permissions: permissions);
        debugPrint("4. Authorization request returned: $requested");
        if (!requested) {
          debugPrint("5. Authorization not granted by user.");
          setState(() => _state = AppState.AUTH_NOT_GRANTED);
          return false;
        }
      }
      debugPrint("6. Permissions appear to be granted.");
      return true;
    } catch (e) {
      debugPrint("Exception in authorize: $e");
      setState(() => _state = AppState.ERROR);
      return false;
    }
  }

  /// Fetch health data for the current month.
  Future<void> fetchData() async {
    debugPrint("7. Fetching data...");
    setState(() => _state = AppState.FETCHING_DATA);

    final now = DateTime.now();
    // Calculate the first day of the current month.
    final startOfMonth = DateTime(now.year, now.month, 1);

    _healthDataList.clear();

    try {
      // Fetch health data for each type individually for the current month.
      for (HealthDataType type in types) {
        try {
          List<HealthDataPoint> healthData =
          await _health.getHealthDataFromTypes(
              startTime: startOfMonth, endTime: now, types: [type]);
          _healthDataList.addAll(healthData);
        } catch (error) {
          debugPrint("Caught exception in getHealthDataFromTypes for type $type: $error");
        }
      }

      // Use the instance method removeDuplicates to filter out duplicate data points.
      _healthDataList = _health.removeDuplicates(_healthDataList);

    } catch (error) {
      debugPrint("Exception in fetchData: $error");
      setState(() => _state = AppState.ERROR);
      return;
    }

    // Update the state based on whether data was found
    setState(() {
      _state = _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
    });
  }

  Widget _buildTryAgainButton() {
    return ElevatedButton(
      onPressed: _isInitializing ? null : _initAndFetch, // Disable button while initializing
      child: const Text('Authorize and Fetch Data'),
    );
  }

  Widget _buildDataList() {
    return ListView.builder(
      itemCount: _healthDataList.length,
      itemBuilder: (_, index) {
        HealthDataPoint p = _healthDataList[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 2,
          child: ListTile(
            title: Text("${p.typeString}: ${p.value.toString()}", style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${p.dateFrom}'),
                Text('Source: ${p.sourceName}'),
              ],
            ),
            trailing: Text(p.unitString ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildUI() {
    switch (_state) {
      case AppState.IDLE:
      // Show a loading indicator on initial startup
        return const Center(child: CircularProgressIndicator());
      case AppState.NO_DATA:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No health data found for this month.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initAndFetch,
                child: const Text('Try Again'),
              )
            ],
          ),
        );
      case AppState.AUTH_NOT_GRANTED:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Authorization not granted. Please grant permissions to use this feature.'),
              const SizedBox(height: 16),
              _buildTryAgainButton(),
            ],
          ),
        );
      case AppState.FETCHING_DATA:
        return const Center(child: CircularProgressIndicator());
      case AppState.DATA_READY:
        return Column(
          children: [
            const Text('Data for this month:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        child: _buildUI(),
      ),
    );
  }
}
