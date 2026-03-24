import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'services/config_loader.dart';
import 'services/service_manager.dart';
import 'services/service_manager_factory.dart'
    if (dart.library.io) 'services/service_manager_factory_io.dart';

const _demoConfig = '''
services:
  - name: Camera Driver
    system: perception
    service_type: sensor
    start_all: true
    command: "python3 /opt/drivers/camera_driver.py"
  - name: Lidar Driver
    system: perception
    service_type: sensor
    start_all: true
    ros:
      package: lidar_driver
      executable: lidar_node
      args: "--frequency 10"
  - name: Object Detector
    system: perception
    service_type: processing
    start_all: true
    command: "python3 /opt/perception/detector.py --model yolov8"
  - name: Localisation
    system: navigation
    service_type: processing
    start_all: true
    ros:
      package: nav_stack
      executable: localisation_node
  - name: Path Planner
    system: navigation
    service_type: processing
    start_all: true
    ros:
      package: nav_stack
      executable: planner_node
      args: "--global"
  - name: Motor Controller
    system: navigation
    service_type: actuator
    start_all: true
    command: "/opt/drivers/motor_controller --can-bus can0"
  - name: Health Monitor
    system: monitoring
    service_type: monitoring
    start_all: true
    command: "python3 /opt/monitoring/health_check.py"
  - name: Log Aggregator
    system: monitoring
    service_type: monitoring
    start_all: false
    command: "python3 /opt/monitoring/log_aggregator.py"
''';

void main() {
  runApp(OrchestrionApp(serviceManager: createServiceManager()));
}

class OrchestrionApp extends StatelessWidget {
  final ServiceManager serviceManager;

  const OrchestrionApp({super.key, required this.serviceManager});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = AppState(serviceManager);
        if (kIsWeb) {
          Future.microtask(
            () => state.loadConfigs(ConfigLoader.parseYaml(_demoConfig)),
          );
        }
        return state;
      },
      child: MaterialApp(
        title: 'Orchestrion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
