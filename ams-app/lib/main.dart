import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(AMSApp());

class AMSApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMS',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 28),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          bodyLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
          bodySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: MainDashboard(),
    );
  }
}

// Maintenance Categories [file:52]
const List<String> maintenanceCategories =
['Repair & renovation', 'Painting', 'Plumbing', 'Electrical',
  'Common area cleaning', 'Sewage tank cleaning', 'Water charges',
  'Generator fuel & maintenance', 'Lift/elevator]