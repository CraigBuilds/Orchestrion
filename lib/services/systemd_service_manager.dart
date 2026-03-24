import 'dart:async';
import 'dart:io';

import '../models/service_config.dart';
import '../models/service_state.dart';
import 'service_exporter.dart';
import 'service_manager.dart';

/// Real systemd-based implementation of [ServiceManager].
///
/// Creates systemd user services and uses systemctl/journalctl to manage them.
class SystemdServiceManager implements ServiceManager {
  final Map<String, Process> _logProcesses = {};

  @override
  Future<void> install(ServiceConfig config) async {
    final homeDir = Platform.environment['HOME'];
    if (homeDir == null || homeDir.isEmpty) {
      throw StateError(
        'Cannot install systemd user service: HOME environment variable is not set.',
      );
    }
    final unitDir = '$homeDir/.config/systemd/user';
    await Directory(unitDir).create(recursive: true);

    final unitContent = ServiceExporter.generateUnitContent(config);
    final unitPath = '$unitDir/${config.unitName}';
    await File(unitPath).writeAsString(unitContent);
    await _runSystemctl(['daemon-reload']);
  }

  @override
  Future<void> exportServices(
    List<ServiceConfig> configs,
    String outputDir,
  ) async {
    await ServiceExporter.exportServices(configs, outputDir);
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

    () async {
      try {
        final process = await Process.start(
          'journalctl',
          ['--user', '-u', unitName, '-f', '--no-pager'],
        );
        _logProcesses[serviceName] = process;

        // Forward stdout lines to the stream.
        process.stdout.transform(const SystemEncoding().decoder).listen(
          (data) {
            for (final line in data.split('\n')) {
              if (line.isNotEmpty) controller.add(line);
            }
          },
          onDone: () => controller.close(),
          onError: (e, st) => controller.addError(e, st),
        );

        // Forward stderr as errors for easier debugging.
        process.stderr.transform(const SystemEncoding().decoder).listen(
          (data) {
            final errorOutput = data.trim();
            if (errorOutput.isNotEmpty) {
              controller.addError(
                ProcessException(
                  'journalctl',
                  ['--user', '-u', unitName, '-f', '--no-pager'],
                  errorOutput,
                ),
              );
            }
          },
        );
      } catch (e, st) {
        // Handle failures from Process.start so the stream does not hang.
        controller.addError(e, st);
        await controller.close();
      }
    }();
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
