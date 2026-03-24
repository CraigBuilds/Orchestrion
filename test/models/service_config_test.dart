import 'package:flutter_test/flutter_test.dart';

import 'package:orchestrion/models/service_config.dart';

void main() {
  group('ServiceConfig', () {
    test('creates from map with command', () {
      final config = ServiceConfig.fromMap({
        'name': 'Test Service',
        'system': 'test-system',
        'service_type': 'processing',
        'start_all': true,
        'command': 'python3 /opt/test.py',
      });

      expect(config.name, 'Test Service');
      expect(config.system, 'test-system');
      expect(config.serviceType, 'processing');
      expect(config.startAll, true);
      expect(config.command, 'python3 /opt/test.py');
      expect(config.effectiveCommand, 'python3 /opt/test.py');
    });

    test('creates from map with ROS shorthand', () {
      final config = ServiceConfig.fromMap({
        'name': 'ROS Node',
        'system': 'perception',
        'service_type': 'sensor',
        'ros': {
          'package': 'camera_pkg',
          'executable': 'camera_node',
          'args': '--frequency 30',
        },
      });

      expect(config.rosPackage, 'camera_pkg');
      expect(config.rosExecutable, 'camera_node');
      expect(config.rosArgs, '--frequency 30');
      expect(
        config.effectiveCommand,
        'ros2 run camera_pkg camera_node --frequency 30',
      );
    });

    test('ROS shorthand without args', () {
      final config = ServiceConfig.fromMap({
        'name': 'Simple ROS',
        'system': 'nav',
        'service_type': 'processing',
        'ros': {
          'package': 'nav_pkg',
          'executable': 'planner',
        },
      });

      expect(config.effectiveCommand, 'ros2 run nav_pkg planner');
    });

    test('start_all defaults to true', () {
      final config = ServiceConfig.fromMap({
        'name': 'Defaults',
        'system': 'sys',
        'service_type': 'type',
        'command': 'echo hello',
      });

      expect(config.startAll, true);
    });

    test('start_all can be set to false', () {
      final config = ServiceConfig.fromMap({
        'name': 'Optional',
        'system': 'sys',
        'service_type': 'type',
        'command': 'echo hello',
        'start_all': false,
      });

      expect(config.startAll, false);
    });

    test('throws if neither command nor ros package is provided', () {
      expect(
        () => ServiceConfig(
          name: 'Bad',
          system: 'sys',
          serviceType: 'type',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('unitName is derived from service name', () {
      final config = ServiceConfig.fromMap({
        'name': 'Camera Driver',
        'system': 'perception',
        'service_type': 'sensor',
        'command': 'test',
      });

      expect(config.unitName, 'orchestrion-camera-driver.service');
    });

    test('toMap round-trips with command', () {
      final original = ServiceConfig.fromMap({
        'name': 'Test',
        'system': 'sys',
        'service_type': 'type',
        'start_all': true,
        'command': 'echo hello',
      });

      final map = original.toMap();
      final restored = ServiceConfig.fromMap(map);

      expect(restored.name, original.name);
      expect(restored.system, original.system);
      expect(restored.serviceType, original.serviceType);
      expect(restored.startAll, original.startAll);
      expect(restored.command, original.command);
    });

    test('toMap round-trips with ROS shorthand', () {
      final original = ServiceConfig.fromMap({
        'name': 'ROS',
        'system': 'sys',
        'service_type': 'type',
        'ros': {
          'package': 'pkg',
          'executable': 'exe',
          'args': '--arg1',
        },
      });

      final map = original.toMap();
      final restored = ServiceConfig.fromMap(map);

      expect(restored.rosPackage, original.rosPackage);
      expect(restored.rosExecutable, original.rosExecutable);
      expect(restored.rosArgs, original.rosArgs);
    });

    test('throws if ROS shorthand is missing executable', () {
      expect(
        () => ServiceConfig.fromMap({
          'name': 'Bad ROS',
          'system': 'sys',
          'service_type': 'type',
          'ros': {
            'package': 'pkg',
          },
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('handles YamlMap-style ros map (dynamic keys)', () {
      // Simulate what YAML parsing produces: Map<dynamic, dynamic>
      final yamlLikeMap = <dynamic, dynamic>{
        'package': 'cam_pkg',
        'executable': 'cam_node',
      };
      final config = ServiceConfig.fromMap({
        'name': 'YAML ROS',
        'system': 'sys',
        'service_type': 'type',
        'ros': yamlLikeMap,
      });
      expect(config.rosPackage, 'cam_pkg');
      expect(config.rosExecutable, 'cam_node');
    });
  });
}
