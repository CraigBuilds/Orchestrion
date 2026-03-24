import 'dart:async';
import 'dart:math';

import '../models/service_config.dart';
import '../models/service_state.dart';
import 'service_manager.dart';

/// Mock implementation of [ServiceManager] for web builds and testing.
///
/// Simulates service lifecycle and generates fake log output.
class MockServiceManager implements ServiceManager {
  final Map<String, ServiceStatus> _statuses = {};
  final Map<String, List<String>> _logs = {};
  final Map<String, StreamController<String>> _logStreams = {};
  final Map<String, Timer> _logTimers = {};
  final _random = Random();

  /// Records of each [exportServices] call for test assertions.
  final List<({List<ServiceConfig> configs, String outputDir})> exportCalls = [];

  /// When true, [exportServices] throws an exception.
  bool throwOnExport = false;

  @override
  Future<void> install(ServiceConfig config) async {
    _statuses[config.name] = ServiceStatus.stopped;
    _logs[config.name] = [];
    _addLog(config.name, '[mock] Service unit installed: ${config.unitName}');
  }

  @override
  Future<void> start(String serviceName) async {
    _statuses[serviceName] = ServiceStatus.starting;
    _addLog(serviceName, '[mock] Starting service...');
    await Future.delayed(const Duration(milliseconds: 500));
    _statuses[serviceName] = ServiceStatus.running;
    _addLog(serviceName, '[mock] Service started successfully.');
    _startLogGeneration(serviceName);
  }

  @override
  Future<void> stop(String serviceName) async {
    _stopLogGeneration(serviceName);
    _statuses[serviceName] = ServiceStatus.stopping;
    _addLog(serviceName, '[mock] Stopping service...');
    await Future.delayed(const Duration(milliseconds: 300));
    _statuses[serviceName] = ServiceStatus.stopped;
    _addLog(serviceName, '[mock] Service stopped.');
  }

  @override
  Future<void> restart(String serviceName) async {
    await stop(serviceName);
    await start(serviceName);
  }

  @override
  Future<ServiceStatus> getStatus(String serviceName) async {
    return _statuses[serviceName] ?? ServiceStatus.unknown;
  }

  @override
  Future<List<String>> getLogs(String serviceName, {int lines = 50}) async {
    final logs = _logs[serviceName] ?? [];
    if (logs.length <= lines) return List.from(logs);
    return logs.sublist(logs.length - lines);
  }

  @override
  Stream<String> streamLogs(String serviceName) {
    _logStreams[serviceName] ??= StreamController<String>.broadcast();
    return _logStreams[serviceName]!.stream;
  }

  @override
  Future<void> exportServices(
    List<ServiceConfig> configs,
    String outputDir,
  ) async {
    if (throwOnExport) throw Exception('mock export failure');
    exportCalls.add((configs: List.unmodifiable(configs), outputDir: outputDir));
  }

  @override
  void dispose() {
    for (final timer in _logTimers.values) {
      timer.cancel();
    }
    for (final controller in _logStreams.values) {
      controller.close();
    }
    _logTimers.clear();
    _logStreams.clear();
  }

  void _addLog(String serviceName, String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final line = '[$timestamp] $message';
    _logs.putIfAbsent(serviceName, () => []);
    _logs[serviceName]!.add(line);
    // Keep max 500 lines
    if (_logs[serviceName]!.length > 500) {
      _logs[serviceName]!.removeAt(0);
    }
    _logStreams[serviceName]?.add(line);
  }

  void _startLogGeneration(String serviceName) {
    _stopLogGeneration(serviceName);
    _logTimers[serviceName] = Timer.periodic(
      Duration(seconds: 2 + _random.nextInt(4)),
      (_) {
        if (_statuses[serviceName] == ServiceStatus.running) {
          final messages = [
            'Processing request...',
            'Heartbeat OK',
            'Received data packet',
            'Task completed in ${_random.nextInt(100)}ms',
            'Connection active',
            'Queue depth: ${_random.nextInt(10)}',
            'Memory usage: ${50 + _random.nextInt(50)}MB',
          ];
          _addLog(serviceName, messages[_random.nextInt(messages.length)]);
        }
      },
    );
  }

  void _stopLogGeneration(String serviceName) {
    _logTimers[serviceName]?.cancel();
    _logTimers.remove(serviceName);
  }
}
