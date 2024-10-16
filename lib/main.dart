import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'services/vehicle_info_provider.dart';
import 'features/vin_lookup/vin_input_screen.dart';

void main() {
  Logger.root.level = Level.ALL; // Set this to Level.OFF in production
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => VehicleInfoProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIN Information App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VinInputScreen(),
    );
  }
}