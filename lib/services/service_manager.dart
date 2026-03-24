import '../models/service_config.dart';
import '../models/service_state.dart';

/// Abstract interface for managing services.
///
/// Implementations may use real systemd or a mock layer.
abstract class ServiceManager {
  /// Install/update the systemd unit for this service config.
  Future<void> install(ServiceConfig config);

  /// Start a service by name.
  Future<void> start(String serviceName);

  /// Stop a service by name.
  Future<void> stop(String serviceName);

  /// Restart a service by name.
  Future<void> restart(String serviceName);

  /// Get the current status of a service.
  Future<ServiceStatus> getStatus(String serviceName);

  /// Get recent log lines for a service.
  Future<List<String>> getLogs(String serviceName, {int lines = 50});

  /// Stream of log lines for a service (for live tailing).
  Stream<String> streamLogs(String serviceName);

  /// Dispose any resources held by this manager.
  void dispose();
}
