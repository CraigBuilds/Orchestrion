import 'dart:async';
import 'dart:io';

import '../models/service_config.dart';
import '../models/service_state.dart';
import 'service_manager.dart';

/// Real systemd-based implementation of [ServiceManager].
///
/// Creates systemd user services and uses systemctl/journalctl to manage them.
class SystemdServiceManager implements ServiceManager {
  final Map<String, Process> _logProcesses = {};

  @override
  Future<void> install(ServiceConfig config) async {
    final unitDir = '${Platform.environment['HOME']}/.config/systemd/user';
    await Directory(unitDir).create(recursive: true);

    final unitContent = '''
[Unit]
Description=Orchestrion: ${config.name}

[Service]
Type=simple
ExecStart=${config.effectiveCommand}
Restart=no

[Install]
WantedBy=default.target
''';

    final unitPath = '$unitDir/${config.unitName}';
    await File(unitPath).writeAsString(unitContent);
    await _runSystemctl(['daemon-reload']);
  }

  @override
  Future<void> start(String serviceName) async {
    final unitName = _toUnitName(serviceName);
    await _runSystemctl(['start', unitName]);
  }

  @override
  Future<void> stop(String serviceName) async {
    final unitName = _toUnitName(serviceName);
    await _runSystemctl(['stop', unitName]);
  }

  @override
  Future<void> restart(String serviceName) async {
    final unitName = _toUnitName(serviceName);
    await _runSystemctl(['restart', unitName]);
  }

  @override
  Future<ServiceStatus> getStatus(String serviceName) async {
    final unitName = _toUnitName(serviceName);
    final result = await Process.run(
      'systemctl',
      ['--user', 'is-active', unitName],
    );
    final output = (result.stdout as String).trim();
    switch (output) {
      case 'active':
        return ServiceStatus.running;
      case 'inactive':
        return ServiceStatus.stopped;
      case 'failed':
        return ServiceStatus.failed;
      case 'activating':
        return ServiceStatus.starting;
      case 'deactivating':
        return ServiceStatus.stopping;
      default:
        return ServiceStatus.unknown;
    }
  }

  @override
  Future<List<String>> getLogs(String serviceName, {int lines = 50}) async {
    final unitName = _toUnitName(serviceName);
    final result = await Process.run(
      'journalctl',
      ['--user', '-u', unitName, '-n', '$lines', '--no-pager'],
    );
    return (result.stdout as String)
        .split('\n')
        .where((line) => line.isNotEmpty)
        .toList();
  }

  @override
  Stream<String> streamLogs(String serviceName) {
    final unitName = _toUnitName(serviceName);
    final controller = StreamController<String>();

    Process.start(
      'journalctl',
      ['--user', '-u', unitName, '-f', '--no-pager'],
    ).then((process) {
      _logProcesses[serviceName] = process;
      process.stdout.transform(const SystemEncoding().decoder).listen(
        (data) {
          for (final line in data.split('\n')) {
            if (line.isNotEmpty) controller.add(line);
          }
        },
        onDone: () => controller.close(),
        onError: (e) => controller.addError(e),
      );
    });

    controller.onCancel = () {
      _logProcesses[serviceName]?.kill();
      _logProcesses.remove(serviceName);
    };

    return controller.stream;
  }

  @override
  void dispose() {
    for (final process in _logProcesses.values) {
      process.kill();
    }
    _logProcesses.clear();
  }

  Future<void> _runSystemctl(List<String> args) async {
    final result = await Process.run('systemctl', ['--user', ...args]);
    if (result.exitCode != 0) {
      throw Exception(
        'systemctl ${args.join(' ')} failed: ${result.stderr}',
      );
    }
  }

  String _toUnitName(String serviceName) {
    return 'orchestrion-${serviceName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-')}.service';
  }
}
