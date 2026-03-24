import 'package:flutter_test/flutter_test.dart';

import 'package:orchestrion/services/config_loader.dart';

void main() {
  group('ConfigLoader', () {
    test('parses valid YAML with command-based services', () {
      const yaml = '''
services:
  - name: Test Service
    system: test-system
    service_type: processing
    command: "python3 /opt/test.py"
  - name: Another Service
    system: test-system
    service_type: sensor
    command: "echo hello"
    start_all: false
''';

      final configs = ConfigLoader.parseYaml(yaml);
      expect(configs.length, 2);
      expect(configs[0].name, 'Test Service');
      expect(configs[0].system, 'test-system');
      expect(configs[0].serviceType, 'processing');
      expect(configs[0].command, 'python3 /opt/test.py');
      expect(configs[0].startAll, true);

      expect(configs[1].name, 'Another Service');
      expect(configs[1].startAll, false);
    });

    test('parses YAML with ROS shorthand', () {
      const yaml = '''
services:
  - name: Camera Node
    system: perception
    service_type: sensor
    ros:
      package: camera_pkg
      executable: camera_node
      args: "--frequency 30"
''';

      final configs = ConfigLoader.parseYaml(yaml);
      expect(configs.length, 1);
      expect(configs[0].rosPackage, 'camera_pkg');
      expect(configs[0].rosExecutable, 'camera_node');
      expect(configs[0].rosArgs, '--frequency 30');
      expect(
        configs[0].effectiveCommand,
        'ros2 run camera_pkg camera_node --frequency 30',
      );
    });

    test('parses mixed command and ROS services', () {
      const yaml = '''
services:
  - name: Generic Service
    system: sys
    service_type: type
    command: "/usr/bin/my-daemon"
  - name: ROS Service
    system: sys
    service_type: type
    ros:
      package: my_pkg
      executable: my_node
''';

      final configs = ConfigLoader.parseYaml(yaml);
      expect(configs.length, 2);
      expect(configs[0].command, '/usr/bin/my-daemon');
      expect(configs[1].rosPackage, 'my_pkg');
    });

    test('throws on invalid YAML structure (not a map)', () {
      const yaml = 'just a string';
      expect(
        () => ConfigLoader.parseYaml(yaml),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on missing services key', () {
      const yaml = '''
other_key:
  - something
''';
      expect(
        () => ConfigLoader.parseYaml(yaml),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws on invalid service entry (not a map)', () {
      const yaml = '''
services:
  - just a string
''';
      expect(
        () => ConfigLoader.parseYaml(yaml),
        throwsA(isA<FormatException>()),
      );
    });

    test('parses the example config file format', () {
      const yaml = '''
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

      final configs = ConfigLoader.parseYaml(yaml);
      expect(configs.length, 4);

      // Check systems
      final systems = configs.map((c) => c.system).toSet();
      expect(systems, {'perception', 'monitoring'});

      // Check service types
      final types = configs.map((c) => c.serviceType).toSet();
      expect(types, {'sensor', 'monitoring'});

      // Check start_all filtering
      final startAll = configs.where((c) => c.startAll).toList();
      expect(startAll.length, 3);
      expect(startAll.every((c) => c.name != 'Log Aggregator'), true);
    });
  });
}
