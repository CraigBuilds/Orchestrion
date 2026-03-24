import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'services/mock_service_manager.dart';
import 'services/service_manager.dart';

void main() {
  final ServiceManager serviceManager;

  if (kIsWeb) {
    // Always use mock on web
    serviceManager = MockServiceManager();
  } else {
    // On desktop, use mock for now; swap to SystemdServiceManager when ready
    serviceManager = MockServiceManager();
  }

  runApp(OrchestrionApp(serviceManager: serviceManager));
}

class OrchestrionApp extends StatelessWidget {
  final ServiceManager serviceManager;

  const OrchestrionApp({super.key, required this.serviceManager});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(serviceManager),
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
