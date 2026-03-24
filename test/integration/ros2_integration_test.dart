import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:orchestrion/models/service_config.dart';
import 'package:orchestrion/models/service_state.dart';
import 'package:orchestrion/services/systemd_service_manager.dart';

/// Returns the full path to the ros2 binary if it is on PATH, or null.
String? _findRos2() {
  try {
    final result = Process.runSync('which', ['ros2']);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
  } catch (_) {}
  return null;
}

/// Polls [getStatus] until the service reaches [expected] or [timeout] elapses.
///
/// Returns the final observed [ServiceStatus].
Future<ServiceStatus> _waitForStatus(
  SystemdServiceManager manager,
  String serviceName,
  ServiceStatus expected, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 500),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final status = await manager.getStatus(serviceName);
    if (status == expected) return status;
    await Future.delayed(interval);
  }
  return manager.getStatus(serviceName);
}

/// Polls [getLogs] until at least one line is returned or [timeout] elapses.
///
/// Returns the collected log lines (may be empty on timeout).
Future<List<String>> _waitForLogs(
  SystemdServiceManager manager,
  String serviceName, {
  Duration timeout = const Duration(seconds: 10),
  Duration interval = const Duration(milliseconds: 500),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    final logs = await manager.getLogs(serviceName);
    if (logs.isNotEmpty) return logs;
    await Future.delayed(interval);
  }
  return manager.getLogs(serviceName);
}

void main() {
  // Locate ros2 once so we can build configs and skip gracefully.
  final ros2Path = _findRos2();
  final skipReason =
      ros2Path == null ? 'ros2 binary not found on PATH – skipping ROS2 tests' : null;

  group('ROS2 systemd integration', skip: skipReason, () {
    late SystemdServiceManager manager;
    late ServiceConfig talkerConfig;

    setUpAll(() {
      // demo_nodes_cpp/talker is a standard ROS2 demo node that ships with
      // every ROS2 desktop installation. It continuously publishes
      // "Hello World: N" messages, making it easy to verify logs.
      talkerConfig = ServiceConfig.fromMap({
        'name': 'Demo Talker',
        'system': 'demo',
        'service_type': 'publisher',
        // Use the resolved full path so systemd can find ros2 without
        // requiring PATH manipulation inside the unit environment.
        'command': '${ros2Path ?? 'ros2'} run demo_nodes_cpp talker',
      });
    });

    setUp(() {
      manager = SystemdServiceManager();
    });

    tearDown(() async {
      // Best-effort stop so later tests start cleanly.
      try {
        await manager.stop('Demo Talker');
      } catch (_) {}

      // Remove the installed unit file and reload the daemon.
      final home = Platform.environment['HOME'];
      if (home != null) {
        final unitFile = File(
          '$home/.config/systemd/user/${talkerConfig.unitName}',
        );
        if (unitFile.existsSync()) {
          await unitFile.delete();
        }
      }
      await Process.run('systemctl', ['--user', 'daemon-reload']);

      manager.dispose();
    });

    test('install creates a systemd unit file for the ROS2 node', () async {
      await manager.install(talkerConfig);

      final home = Platform.environment['HOME'];
      expect(home, isNotNull);
      final unitFile = File(
        '$home/.config/systemd/user/${talkerConfig.unitName}',
      );
      expect(await unitFile.exists(), isTrue);

      final content = await unitFile.readAsString();
      expect(content, contains('[Unit]'));
      expect(content, contains('[Service]'));
      expect(content, contains('ExecStart='));
      expect(content, contains('demo_nodes_cpp'));
      expect(content, contains('talker'));
    });

    test('start transitions the ROS2 node to running', () async {
      await manager.install(talkerConfig);
      await manager.start('Demo Talker');

      final status = await _waitForStatus(
        manager,
        'Demo Talker',
        ServiceStatus.running,
      );
      expect(status, ServiceStatus.running);
    });

    test('getLogs returns output produced by the running ROS2 node', () async {
      await manager.install(talkerConfig);
      await manager.start('Demo Talker');

      final logs = await _waitForLogs(manager, 'Demo Talker');
      expect(logs, isNotEmpty);
    });

    test('stop transitions the ROS2 node to stopped', () async {
      await manager.install(talkerConfig);
      await manager.start('Demo Talker');
      await _waitForStatus(manager, 'Demo Talker', ServiceStatus.running);

      await manager.stop('Demo Talker');

      final status = await _waitForStatus(
        manager,
        'Demo Talker',
        ServiceStatus.stopped,
      );
      expect(status, ServiceStatus.stopped);
    });
  });
}
