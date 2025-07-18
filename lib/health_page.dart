import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  _StepCounterScreenState createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  List<HealthDataPoint> _stepData = [];
  final Health _health = Health();

  @override
  void initState() {
    super.initState();
    _fetchStepData();
  }

  Future<void> _fetchStepData() async {
    try {
      List<HealthDataType> types = [HealthDataType.STEPS];
      DateTime now = DateTime.now();
      DateTime start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: start,
        endTime: now,
      );
      setState(() {
        _stepData = healthData;
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Step Counter')),
      body: ListView.builder(
        itemCount: _stepData.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Steps: ${_stepData[index].value}'),
            subtitle: Text('Date: ${_stepData[index].dateFrom}'),
          );
        },
      ),
    );
  }
}
