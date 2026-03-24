import 'package:flutter_test/flutter_test.dart';

import 'package:orchestrion/models/service_config.dart';
import 'package:orchestrion/models/service_state.dart';
import 'package:orchestrion/services/mock_service_manager.dart';

void main() {
  group('MockServiceManager', () {
    late MockServiceManager manager;

    setUp(() {
      manager = MockServiceManager();
    });

    tearDown(() {
      manager.dispose();
    });

    ServiceConfig _makeConfig(String name) {
      return ServiceConfig.fromMap({
        'name': name,
        'system': 'test',
        'service_type': 'test',
        'command': 'echo $name',
      });
    }

    test('install sets status to stopped', () async {
      await manager.install(_makeConfig('svc1'));
      final status = await manager.getStatus('svc1');
      expect(status, ServiceStatus.stopped);
    });

    test('start transitions to running', () async {
      await manager.install(_makeConfig('svc1'));
      await manager.start('svc1');
      final status = await manager.getStatus('svc1');
      expect(status, ServiceStatus.running);
    });

    test('stop transitions to stopped', () async {
      await manager.install(_makeConfig('svc1'));
      await manager.start('svc1');
      await manager.stop('svc1');
      final status = await manager.getStatus('svc1');
      expect(status, ServiceStatus.stopped);
    });

    test('restart results in running', () async {
      await manager.install(_makeConfig('svc1'));
      await manager.restart('svc1');
      final status = await manager.getStatus('svc1');
      expect(status, ServiceStatus.running);
    });

    test('getLogs returns logged messages', () async {
      await manager.install(_makeConfig('svc1'));
      await manager.start('svc1');
      final logs = await manager.getLogs('svc1');
      expect(logs, isNotEmpty);
      expect(logs.any((l) => l.contains('started')), true);
    });

    test('streamLogs emits log lines', () async {
      await manager.install(_makeConfig('svc1'));
      final stream = manager.streamLogs('svc1');

      final lines = <String>[];
      final subscription = stream.listen(lines.add);

      await manager.start('svc1');
      await Future.delayed(const Duration(milliseconds: 100));

      expect(lines, isNotEmpty);

      await subscription.cancel();
    });

    test('unknown service returns unknown status', () async {
      final status = await manager.getStatus('nonexistent');
      expect(status, ServiceStatus.unknown);
    });

    test('multiple services are independent', () async {
      await manager.install(_makeConfig('svc1'));
      await manager.install(_makeConfig('svc2'));
      await manager.start('svc1');

      expect(await manager.getStatus('svc1'), ServiceStatus.running);
      expect(await manager.getStatus('svc2'), ServiceStatus.stopped);
    });
  });
}
