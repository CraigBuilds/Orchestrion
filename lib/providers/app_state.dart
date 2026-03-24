import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/service_config.dart';
import '../models/service_state.dart';
import '../services/service_manager.dart';

/// How to group services in the UI.
enum GroupMode { bySystem, byServiceType }

/// Central state provider for the Orchestrion app.
///
/// Manages service configs, states, and interactions with the [ServiceManager].
class AppState extends ChangeNotifier {
  final ServiceManager _serviceManager;
  final bool enablePolling;

  List<ServiceConfig> _configs = [];
  final Map<String, ServiceState> _states = {};
  GroupMode _groupMode = GroupMode.bySystem;
  Timer? _pollTimer;
  String? _error;
  bool _refreshing = false;

  AppState(this._serviceManager, {this.enablePolling = true});

  // -- Getters --

  List<ServiceConfig> get configs => List.unmodifiable(_configs);
  Map<String, ServiceState> get states => Map.unmodifiable(_states);
  GroupMode get groupMode => _groupMode;
  String? get error => _error;

  ServiceState stateFor(String serviceName) {
    return _states[serviceName] ??
        ServiceState(serviceName: serviceName);
  }

  /// Returns configs grouped by the current [groupMode].
  Map<String, List<ServiceConfig>> get groupedConfigs {
    final map = <String, List<ServiceConfig>>{};
    for (final config in _configs) {
      final key = _groupMode == GroupMode.bySystem
          ? config.system
          : config.serviceType;
      map.putIfAbsent(key, () => []).add(config);
    }
    // Sort groups by name
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  /// All unique system names.
  Set<String> get systems => _configs.map((c) => c.system).toSet();

  /// All unique service types.
  Set<String> get serviceTypes => _configs.map((c) => c.serviceType).toSet();

  /// Clear the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // -- Actions --

  void setGroupMode(GroupMode mode) {
    _groupMode = mode;
    notifyListeners();
  }

  /// Load configs and install services.
  Future<void> loadConfigs(List<ServiceConfig> configs) async {
    // Reset any existing polling before loading new configs.
    _pollTimer?.cancel();
    _pollTimer = null;

    _configs = configs;
    _error = null;
    // Clear existing states to avoid exposing stale entries for removed services.
    _states.clear();
    for (final config in configs) {
      _states[config.name] = ServiceState(serviceName: config.name);
      try {
        await _serviceManager.install(config);
      } catch (e) {
        _error = 'Failed to install ${config.name}: $e';
      }
    }
    notifyListeners();
    await refreshAll();
    _startPolling();
  }

  /// Refresh the status of all services.
  Future<void> refreshAll() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      for (final config in _configs) {
        await _refreshStatus(config.name);
      }
      notifyListeners();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> startService(String name) async {
    try {
      await _serviceManager.start(name);
      await _refreshStatus(name);
    } catch (e) {
      _error = 'Failed to start $name: $e';
    }
    notifyListeners();
  }

  Future<void> stopService(String name) async {
    try {
      await _serviceManager.stop(name);
      await _refreshStatus(name);
    } catch (e) {
      _error = 'Failed to stop $name: $e';
    }
    notifyListeners();
  }

  Future<void> restartService(String name) async {
    try {
      await _serviceManager.restart(name);
      await _refreshStatus(name);
    } catch (e) {
      _error = 'Failed to restart $name: $e';
    }
    notifyListeners();
  }

  /// Start all services that have startAll enabled.
  Future<void> startAll() async {
    final toStart = _configs.where((c) => c.startAll).toList();
    for (final config in toStart) {
      await startService(config.name);
    }
  }

  /// Get logs for a service.
  Future<List<String>> getLogs(String name, {int lines = 100}) {
    return _serviceManager.getLogs(name, lines: lines);
  }

  /// Stream logs for a service.
  Stream<String> streamLogs(String name) {
    return _serviceManager.streamLogs(name);
  }

  // -- Internal --

  Future<void> _refreshStatus(String name) async {
    try {
      final status = await _serviceManager.getStatus(name);
      final logs = await _serviceManager.getLogs(name, lines: 5);
      _states[name] = ServiceState(
        serviceName: name,
        status: status,
        recentLogs: logs,
      );
    } catch (e) {
      // Keep existing state on error
    }
  }

  void _startPolling() {
    if (!enablePolling) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      refreshAll();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _serviceManager.dispose();
    super.dispose();
  }
}
