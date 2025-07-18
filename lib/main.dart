import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your app name',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Your Title here'),
        ),
        body: Center(
          child: Text('Hello World, of course'),
        ),
      ),
    );
  }
}