import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'services/vehicle_info_provider.dart';
import 'features/vin_lookup/vin_input_screen.dart';

// Add this global navigator key for use with the barcode scanner
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Initialize logging
  Logger.root.level = Level.ALL; // Set this to Level.OFF in production
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => VehicleInfoProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIN Information App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Add the navigator key to the MaterialApp
      navigatorKey: navigatorKey,
      home: const VinInputScreen(),
    );
  }
}