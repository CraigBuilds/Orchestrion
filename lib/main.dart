import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'services/service_manager.dart';
import 'services/service_manager_factory.dart'
    if (dart.library.io) 'services/service_manager_factory_io.dart';

void main() {
  runApp(OrchestrionApp(serviceManager: createServiceManager()));
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
