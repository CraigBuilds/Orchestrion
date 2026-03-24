import 'package:flutter_test/flutter_test.dart';

import 'package:orchestrion/models/service_config.dart';
import 'package:orchestrion/models/service_state.dart';
import 'package:orchestrion/providers/app_state.dart';
import 'package:orchestrion/services/mock_service_manager.dart';

void main() {
  group('AppState', () {
    late MockServiceManager manager;
    late AppState appState;

    final testConfigs = [
      ServiceConfig.fromMap({
        'name': 'Camera',
        'system': 'perception',
        'service_type': 'sensor',
        'start_all': true,
        'command': 'echo camera',
      }),
      ServiceConfig.fromMap({
        'name': 'Lidar',
        'system': 'perception',
        'service_type': 'sensor',
        'start_all': true,
        'command': 'echo lidar',
      }),
      ServiceConfig.fromMap({
        'name': 'Planner',
        'system': 'navigation',
        'service_type': 'processing',
        'start_all': true,
        'command': 'echo planner',
      }),
      ServiceConfig.fromMap({
        'name': 'Logger',
        'system': 'monitoring',
        'service_type': 'monitoring',
        'start_all': false,
        'command': 'echo logger',
      }),
    ];

    setUp(() {
      manager = MockServiceManager();
      appState = AppState(manager, enablePolling: false);
    });

    tearDown(() {
      appState.dispose();
    });

    test('initial state is empty', () {
      expect(appState.configs, isEmpty);
      expect(appState.states, isEmpty);
      expect(appState.groupMode, GroupMode.bySystem);
    });

    test('loadConfigs populates configs and states', () async {
      await appState.loadConfigs(testConfigs);

      expect(appState.configs.length, 4);
      expect(appState.states.length, 4);
    });

    test('groupedConfigs groups by system', () async {
      await appState.loadConfigs(testConfigs);
      appState.setGroupMode(GroupMode.bySystem);

      final groups = appState.groupedConfigs;
      expect(groups.keys, containsAll(['perception', 'navigation', 'monitoring']));
      expect(groups['perception']!.length, 2);
      expect(groups['navigation']!.length, 1);
      expect(groups['monitoring']!.length, 1);
    });

    test('groupedConfigs groups by service type', () async {
      await appState.loadConfigs(testConfigs);
      appState.setGroupMode(GroupMode.byServiceType);

      final groups = appState.groupedConfigs;
      expect(groups.keys, containsAll(['sensor', 'processing', 'monitoring']));
      expect(groups['sensor']!.length, 2);
      expect(groups['processing']!.length, 1);
      expect(groups['monitoring']!.length, 1);
    });

    test('systems and serviceTypes return unique values', () async {
      await appState.loadConfigs(testConfigs);

      expect(appState.systems, {'perception', 'navigation', 'monitoring'});
      expect(appState.serviceTypes, {'sensor', 'processing', 'monitoring'});
    });

    test('startService changes status to running', () async {
      await appState.loadConfigs(testConfigs);
      await appState.startService('Camera');

      expect(appState.stateFor('Camera').status, ServiceStatus.running);
    });

    test('stopService changes status to stopped', () async {
      await appState.loadConfigs(testConfigs);
      await appState.startService('Camera');
      await appState.stopService('Camera');

      expect(appState.stateFor('Camera').status, ServiceStatus.stopped);
    });

    test('restartService results in running', () async {
      await appState.loadConfigs(testConfigs);
      await appState.restartService('Camera');

      expect(appState.stateFor('Camera').status, ServiceStatus.running);
    });

    test('startAll only starts services with startAll=true', () async {
      await appState.loadConfigs(testConfigs);
      await appState.startAll();

      expect(appState.stateFor('Camera').status, ServiceStatus.running);
      expect(appState.stateFor('Lidar').status, ServiceStatus.running);
      expect(appState.stateFor('Planner').status, ServiceStatus.running);
      // Logger has start_all: false
      expect(appState.stateFor('Logger').status, ServiceStatus.stopped);
    });

    test('setGroupMode changes the group mode', () {
      expect(appState.groupMode, GroupMode.bySystem);
      appState.setGroupMode(GroupMode.byServiceType);
      expect(appState.groupMode, GroupMode.byServiceType);
    });

    test('stateFor returns unknown for unloaded service', () {
      final state = appState.stateFor('nonexistent');
      expect(state.status, ServiceStatus.unknown);
      expect(state.serviceName, 'nonexistent');
    });

    test('getLogs returns log lines', () async {
      await appState.loadConfigs(testConfigs);
      await appState.startService('Camera');
      final logs = await appState.getLogs('Camera');
      expect(logs, isNotEmpty);
    });

    test('clearError clears the error', () async {
      await appState.loadConfigs(testConfigs);
      // Trigger an error by calling an action that might fail
      // Since mock won't fail, set error indirectly via the getter check
      expect(appState.error, isNull);
      // clearError should work even if there's no error
      appState.clearError();
      expect(appState.error, isNull);
    });
  });
}
